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
      
      await _ensureAdminUserMappingTableAndPolicies();
      Logger.info('Admin-user mapping table migration completed');
      
      Logger.info('All database migrations completed successfully');
    } catch (e) {
      Logger.error('Error during database migrations: $e', e);
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
        add column if not exists designation text,
        add column if not exists created_by uuid references auth.users(id); -- Add created_by column
        
        -- Create index for performance
        create index if not exists idx_users_created_by on public.users(created_by);
        '''
      });

      // Update RLS policies for users table with admin-user mapping
      await supa.rpc('exec_sql', params: {
        'query': '''
        -- Drop existing policies
        drop policy if exists "users_select" on public.users;
        drop policy if exists "users_insert" on public.users;
        drop policy if exists "users_update" on public.users;
        drop policy if exists "users_delete" on public.users;

        -- New RLS policies for admin-user mapping
        create policy "admin_can_view_own_users"
        on public.users
        for select
        using (
          -- Allow admins to see their own workers
          exists (
            select 1 from public.admin_user_mapping
            where admin_user_mapping.user_id = users.id
              and admin_user_mapping.admin_id = auth.uid()
          )
          -- Allow workers to see their own record
          or users.id = (select id from public.users where phone = auth.jwt() ->> 'phone')
          -- Allow super admin to see all users (optional)
          or (select email from public.users where phone = auth.jwt() ->> 'phone') = 'superadmin@yourapp.com'
        );

        create policy "admin_can_insert_users"
        on public.users
        for insert
        with check (
          -- Allow admins to create workers
          (select role from public.users where phone = auth.jwt() ->> 'phone') = 'admin'
        );

        create policy "admin_can_update_own_users"
        on public.users
        for update
        using (
          -- Allow admins to update their own workers
          exists (
            select 1 from public.admin_user_mapping
            where admin_user_mapping.user_id = users.id
              and admin_user_mapping.admin_id = auth.uid()
          )
          -- Allow workers to update their own record
          or users.id = (select id from public.users where phone = auth.jwt() ->> 'phone')
        )
        with check (
          -- Allow admins to update their own workers
          exists (
            select 1 from public.admin_user_mapping
            where admin_user_mapping.user_id = users.id
              and admin_user_mapping.admin_id = auth.uid()
          )
          -- Allow workers to update their own record
          or users.id = (select id from public.users where phone = auth.jwt() ->> 'phone')
        );

        create policy "admin_can_delete_own_users"
        on public.users
        for delete
        using (
          -- Allow admins to delete their own workers
          exists (
            select 1 from public.admin_user_mapping
            where admin_user_mapping.user_id = users.id
              and admin_user_mapping.admin_id = auth.uid()
          )
        );
        '''
      });

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
          updated_at timestamptz default now(),
          -- Add unique constraint for worker_id and date
          constraint attendance_worker_date_ux unique(worker_id, date)
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
          city text,
          state text,
          pincode text,
          country text,
          logout_city text,
          logout_state text,
          logout_pincode text,
          created_at timestamptz default now(),
          -- Add unique constraint for worker_id and date
          constraint login_status_worker_date_ux unique(worker_id, date)
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
          status text default 'pending' check (status in ('pending', 'approved', 'rejected', 'deducted')),
          deducted_from_salary_id bigint references public.salary(id) on delete set null,
          approved_by bigint references public.users(id) on delete set null,
          approved_date timestamptz,
          created_at timestamptz default now(),
          updated_at timestamptz default now()
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
          pdf_url text,
          created_at timestamptz default now(),
          updated_at timestamptz default now()
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

  // 7️⃣ ADMIN-USER MAPPING
  Future<void> _ensureAdminUserMappingTableAndPolicies() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        -- ADMIN-USER MAPPING TABLE
        create table if not exists public.admin_user_mapping (
          id bigint generated always as identity primary key,
          admin_id uuid references auth.users(id) on delete cascade,
          user_id bigint references public.users(id) on delete cascade,
          created_at timestamptz default now(),
          unique (admin_id, user_id)
        );

        -- Create indexes for performance
        create index if not exists idx_admin_user_mapping_admin_id on public.admin_user_mapping(admin_id);
        create index if not exists idx_admin_user_mapping_user_id on public.admin_user_mapping(user_id);

        -- Enable Row Level Security
        alter table public.admin_user_mapping enable row level security;

        -- Policies

        -- 1️⃣ Allow admins to view only their mappings
        create policy "admin_can_view_their_mappings"
        on public.admin_user_mapping
        for select
        using (auth.uid() = admin_id);

        -- 2️⃣ Allow admins to insert mappings for themselves only
        create policy "admin_can_insert_own_mappings"
        on public.admin_user_mapping
        for insert
        with check (auth.uid() = admin_id);

        -- 3️⃣ Allow admins to delete only their mappings
        create policy "admin_can_delete_own_mappings"
        on public.admin_user_mapping
        for delete
        using (auth.uid() = admin_id);

        -- Function to auto-map admin and user after insert
        create or replace function public.auto_map_admin_to_user()
        returns trigger
        language plpgsql
        security definer
        set search_path = public
        as \$\$
        begin
          if new.created_by is not null then
            insert into public.admin_user_mapping (admin_id, user_id)
            values (new.created_by, new.id)
            on conflict do nothing;
          end if;
          return new;
        end;
        \$\$;

        -- Trigger
        drop trigger if exists trg_auto_map_admin_user on public.users;
        create trigger trg_auto_map_admin_user
        after insert on public.users
        for each row
        execute function public.auto_map_admin_to_user();
        '''
      });

      Logger.info('Admin-user mapping table ensured');
    } catch (e) {
      Logger.error('Error ensuring admin-user mapping table: $e', e);
      rethrow;
    }
  }

  // ✅ Apply open policies so it works in Web (GitHub) + Mobile
  Future<void> _applyPolicies(String tableName) async {
    try {
      // Skip applying default policies for users table since we have custom policies
      if (tableName == 'users') {
        Logger.info('Skipping default policies for users table');
        return;
      }
      
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