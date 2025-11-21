import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class LocationTableUpdater {
  final SupabaseClient supa = Supabase.instance.client;

  Future<void> syncLocationTables() async {
    try {
      Logger.info('Starting location table synchronization...');
      
      await _ensureUsersLocationColumns();
      Logger.info('Users location columns ensured');
      
      await _ensureLoginStatusLocationColumns();
      Logger.info('Login status location columns ensured');
      
      Logger.info('Location table synchronization completed successfully');
    } catch (e, stackTrace) {
      Logger.error('Error during location table synchronization: $e', e);
      rethrow;
    }
  }

  // ✅ USERS TABLE — Add worker's permanent work location fields
  Future<void> _ensureUsersLocationColumns() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': '''
        alter table if exists public.users
        add column if not exists work_location_latitude double precision,
        add column if not exists work_location_longitude double precision,
        add column if not exists work_location_address text,
        add column if not exists location_radius double precision default 100;

        alter table public.users enable row level security;

        drop policy if exists "users_select" on public.users;
        drop policy if exists "users_insert" on public.users;
        drop policy if exists "users_update" on public.users;
        drop policy if exists "users_delete" on public.users;

        create policy "users_select" on public.users for select using (true);
        create policy "users_insert" on public.users for insert with check (true);
        create policy "users_update" on public.users for update using (true) with check (true);
        create policy "users_delete" on public.users for delete using (true);
        '''
      });
    } catch (e) {
      Logger.error('Error ensuring users location columns: $e', e);
      rethrow;
    }
  }

  // ✅ LOGIN STATUS TABLE — Add dynamic login/logout location tracking fields
  Future<void> _ensureLoginStatusLocationColumns() async {
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

        alter table public.login_status enable row level security;

        drop policy if exists "login_status_select" on public.login_status;
        drop policy if exists "login_status_insert" on public.login_status;
        drop policy if exists "login_status_update" on public.login_status;
        drop policy if exists "login_status_delete" on public.login_status;

        create policy "login_status_select" on public.login_status for select using (true);
        create policy "login_status_insert" on public.login_status for insert with check (true);
        create policy "login_status_update" on public.login_status for update using (true) with check (true);
        create policy "login_status_delete" on public.login_status for delete using (true);
        '''
      });
    } catch (e) {
      Logger.error('Error ensuring login status location columns: $e', e);
      rethrow;
    }
  }
}