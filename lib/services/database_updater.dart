import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class DatabaseUpdater {
  final SupabaseClient supa = Supabase.instance.client;

  Future<void> runMigrations() async {
    try {
      Logger.info('Starting database migrations...');
      
      await _ensureUsersColumnsAndPolicies();
      Logger.info('Users table migration completed');
      
      await _ensureAttendanceColumnsAndPolicies();
      Logger.info('Attendance table migration completed');
      
      await _ensureLoginStatusColumnsAndPolicies();
      Logger.info('Login status table migration completed');
      
      await _ensureAdvanceTableAndPolicies();
      Logger.info('Advance table migration completed');
      
      await _ensureSalaryTableAndPolicies();
      Logger.info('Salary table migration completed');
      
      await _ensureNotificationsTableAndPolicies();
      Logger.info('Notifications table migration completed');
      
      Logger.info('All database migrations completed successfully');
    } catch (e, stackTrace) {
      Logger.error('Error during database migrations: $e', e, stackTrace);
      rethrow;
    }
  }

  // 1️⃣ USERS
  Future<void> _ensureUsersColumnsAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        alter table if exists public.users
        add column if not exists work_location_latitude double precision,
        add column if not exists work_location_longitude double precision,
        add column if not exists work_location_address text,
        add column if not exists location_radius double precision default 100,
        add column if not exists profile_photo text,
        add column if not exists id_proof text,
        add column if not exists email_verified boolean default false,
        add column if not exists email_verification_code text,
        add column if not exists designation text;
        '''
      });

      await _applyPolicies('users');
      Logger.info('Users table columns and policies ensured');
    } catch (e) {
      Logger.error('Error ensuring users columns and policies: $e', e);
      rethrow;
    }
  }

  // 2️⃣ ATTENDANCE
  Future<void> _ensureAttendanceColumnsAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        create table if not exists public.attendance (
          id bigint generated always as identity primary key,
          worker_id bigint references public.users(id) on delete cascade,
          date date default current_date,
          in_time text,
          out_time text,
          present boolean default false,
          login_latitude double precision,
          login_longitude double precision,
          login_address text,
          logout_latitude double precision,
          logout_longitude double precision,
          logout_address text,
          created_at timestamptz default now(),
          updated_at timestamptz default now()
        );

        -- Add location columns if they don't exist
        alter table public.attendance
        add column if not exists login_latitude double precision,
        add column if not exists login_longitude double precision,
        add column if not exists login_address text,
        add column if not exists logout_latitude double precision,
        add column if not exists logout_longitude double precision,
        add column if not exists logout_address text,
        add column if not exists created_at timestamptz default now(),
        add column if not exists updated_at timestamptz default now();
        '''
      });

      // Create function to mark absent workers separately to avoid escaping issues
      try {
        await supa.rpc('exec_sql', params: {
          'query': '''
          create or replace function mark_absent_workers()
          returns void
          language sql
          as \$\$
          insert into public.attendance (worker_id, date, present)
          select id, current_date, false
          from public.users
          where role = 'worker'
            and id not in (
              select worker_id from public.attendance where date = current_date
            );
          \$\$;
          '''
        });
      } catch (e) {
        Logger.error('Error creating mark_absent_workers function: $e', e);
      }

      await _applyPolicies('attendance');
      Logger.info('Attendance table ensured');
    } catch (e) {
      Logger.error('Error ensuring attendance table: $e', e);
      rethrow;
    }
  }

  // 3️⃣ LOGIN STATUS
  Future<void> _ensureLoginStatusColumnsAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        create table if not exists public.login_status (
          id bigint generated always as identity primary key,
          worker_id bigint references public.users(id) on delete cascade,
          date date default current_date,
          login_time timestamptz,
          logout_time timestamptz,
          login_latitude double precision,
          login_longitude double precision,
          login_address text,
          logout_latitude double precision,
          logout_longitude double precision,
          logout_address text,
          is_logged_in boolean default false,
          created_at timestamptz default now()
        );

        alter table public.login_status
        add column if not exists city text,
        add column if not exists state text,
        add column if not exists pincode text,
        add column if not exists country text,
        add column if not exists logout_city text,
        add column if not exists logout_state text,
        add column if not exists logout_pincode text;
        '''
      });

      await _applyPolicies('login_status');
      Logger.info('Login status table ensured');
    } catch (e) {
      Logger.error('Error ensuring login status table: $e', e);
      rethrow;
    }
  }

  // 4️⃣ ADVANCE
  Future<void> _ensureAdvanceTableAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        create table if not exists public.advance (
          id bigint generated always as identity primary key,
          worker_id bigint references public.users(id) on delete cascade,
          amount numeric,
          date date,
          purpose text,
          note text,
          status text default 'pending'
        );
        '''
      });

      await _applyPolicies('advance');
      Logger.info('Advance table ensured');
    } catch (e) {
      Logger.error('Error ensuring advance table: $e', e);
      rethrow;
    }
  }

  // 5️⃣ SALARY
  Future<void> _ensureSalaryTableAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        create table if not exists public.salary (
          id bigint generated always as identity primary key,
          worker_id bigint references public.users(id) on delete cascade,
          month text,
          year text,
          total_days int,
          present_days int,
          absent_days int,
          gross_salary numeric,
          total_advance numeric,
          net_salary numeric,
          total_salary numeric,
          paid boolean default false,
          paid_date timestamptz,
          pdf_url text
        );
        '''
      });

      await _applyPolicies('salary');
      Logger.info('Salary table ensured');
    } catch (e) {
      Logger.error('Error ensuring salary table: $e', e);
      rethrow;
    }
  }

  // 6️⃣ NOTIFICATIONS
  Future<void> _ensureNotificationsTableAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        create table if not exists public.notifications (
          id bigint generated always as identity primary key,
          title text,
          message text,
          type text,
          user_id bigint,
          user_role text,
          is_read boolean default false,
          created_at timestamptz default now(),
          related_id text
        );
        '''
      });

      await _applyPolicies('notifications');
      Logger.info('Notifications table ensured');
    } catch (e) {
      Logger.error('Error ensuring notifications table: $e', e);
      rethrow;
    }
  }

  // ✅ Apply open policies so it works in Web (GitHub) + Mobile
  Future<void> _applyPolicies(String tableName) async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        alter table public.$tableName enable row level security;

        drop policy if exists "${tableName}_select" on public.$tableName;
        drop policy if exists "${tableName}_insert" on public.$tableName;
        drop policy if exists "${tableName}_update" on public.$tableName;
        drop policy if exists "${tableName}_delete" on public.$tableName;

        create policy "${tableName}_select" on public.$tableName for select using (true);
        create policy "${tableName}_insert" on public.$tableName for insert with check (true);
        create policy "${tableName}_update" on public.$tableName for update using (true) with check (true);
        create policy "${tableName}_delete" on public.$tableName for delete using (true);
        '''
      });
      Logger.info('Policies applied for table: $tableName');
    } catch (e) {
      Logger.error('Error applying policies for table $tableName: $e', e);
      rethrow;
    }
  }
}