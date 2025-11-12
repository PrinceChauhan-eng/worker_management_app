-- Complete Database Schema for Worker Management App
-- Generated: 2025-11-12
-- This file contains the complete schema for all tables with RLS policies

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- USERS TABLE
create table if not exists public.users (
  id bigint generated always as identity primary key,
  name text not null,
  phone text not null unique,
  password text not null,
  role text not null check (role in ('admin', 'worker')),
  wage numeric not null,
  join_date date not null,
  work_location_latitude double precision,
  work_location_longitude double precision,
  work_location_address text,
  location_radius double precision default 100,
  profile_photo text,
  id_proof text,
  address text,
  email text,
  email_verified boolean default false,
  email_verification_code text,
  designation text,
  created_by uuid references auth.users(id), -- Add created_by column for admin mapping
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Create indexes for users table
create index if not exists idx_users_phone on public.users(phone);
create index if not exists idx_users_role on public.users(role);
create index if not exists idx_users_email on public.users(email);
create index if not exists idx_users_created_by on public.users(created_by); -- Index for performance

-- ATTENDANCE TABLE
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

-- Create indexes for attendance table
create index if not exists idx_attendance_worker_id on public.attendance(worker_id);
create index if not exists idx_attendance_date on public.attendance(date);
create index if not exists idx_attendance_worker_date on public.attendance(worker_id, date);

-- LOGIN STATUS TABLE
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
  created_at timestamptz default now()
);

-- Create indexes for login_status table
create index if not exists idx_login_status_worker_id on public.login_status(worker_id);
create index if not exists idx_login_status_date on public.login_status(date);
create index if not exists idx_login_status_worker_date on public.login_status(worker_id, date);
create index if not exists idx_login_status_is_logged_in on public.login_status(is_logged_in);

-- ADVANCE TABLE
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

-- Create indexes for advance table
create index if not exists idx_advance_worker_id on public.advance(worker_id);
create index if not exists idx_advance_status on public.advance(status);
create index if not exists idx_advance_date on public.advance(date);

-- SALARY TABLE
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

-- Create indexes for salary table
create index if not exists idx_salary_worker_id on public.salary(worker_id);
create index if not exists idx_salary_month on public.salary(month);
create index if not exists idx_salary_paid on public.salary(paid);

-- NOTIFICATIONS TABLE
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

-- Create indexes for notifications table
create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_type on public.notifications(type);
create index if not exists idx_notifications_is_read on public.notifications(is_read);

-- ADMIN-USER MAPPING TABLE
create table if not exists public.admin_user_mapping (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users(id) on delete cascade,
  user_id bigint references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  unique (admin_id, user_id)
);

-- Create indexes for admin_user_mapping table
create index if not exists idx_admin_user_mapping_admin_id on public.admin_user_mapping(admin_id);
create index if not exists idx_admin_user_mapping_user_id on public.admin_user_mapping(user_id);

-- Enable RLS for all tables
alter table public.users enable row level security;
alter table public.attendance enable row level security;
alter table public.login_status enable row level security;
alter table public.advance enable row level security;
alter table public.salary enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_user_mapping enable row level security;

-- Create RLS policies for users table
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

-- Create RLS policies for attendance table
drop policy if exists "attendance_select" on public.attendance;
drop policy if exists "attendance_insert" on public.attendance;
drop policy if exists "attendance_update" on public.attendance;
drop policy if exists "attendance_delete" on public.attendance;

create policy "attendance_select" on public.attendance for select using (true);
create policy "attendance_insert" on public.attendance for insert with check (true);
create policy "attendance_update" on public.attendance for update using (true) with check (true);
create policy "attendance_delete" on public.attendance for delete using (true);

-- Create RLS policies for login_status table
drop policy if exists "login_status_select" on public.login_status;
drop policy if exists "login_status_insert" on public.login_status;
drop policy if exists "login_status_update" on public.login_status;
drop policy if exists "login_status_delete" on public.login_status;

create policy "login_status_select" on public.login_status for select using (true);
create policy "login_status_insert" on public.login_status for insert with check (true);
create policy "login_status_update" on public.login_status for update using (true) with check (true);
create policy "login_status_delete" on public.login_status for delete using (true);

-- Create RLS policies for advance table
drop policy if exists "advance_select" on public.advance;
drop policy if exists "advance_insert" on public.advance;
drop policy if exists "advance_update" on public.advance;
drop policy if exists "advance_delete" on public.advance;

create policy "advance_select" on public.advance for select using (true);
create policy "advance_insert" on public.advance for insert with check (true);
create policy "advance_update" on public.advance for update using (true) with check (true);
create policy "advance_delete" on public.advance for delete using (true);

-- Create RLS policies for salary table
drop policy if exists "salary_select" on public.salary;
drop policy if exists "salary_insert" on public.salary;
drop policy if exists "salary_update" on public.salary;
drop policy if exists "salary_delete" on public.salary;

create policy "salary_select" on public.salary for select using (true);
create policy "salary_insert" on public.salary for insert with check (true);
create policy "salary_update" on public.salary for update using (true) with check (true);
create policy "salary_delete" on public.salary for delete using (true);

-- Create RLS policies for notifications table
drop policy if exists "notifications_select" on public.notifications;
drop policy if exists "notifications_insert" on public.notifications;
drop policy if exists "notifications_update" on public.notifications;
drop policy if exists "notifications_delete" on public.notifications;

create policy "notifications_select" on public.notifications for select using (true);
create policy "notifications_insert" on public.notifications for insert with check (true);
create policy "notifications_update" on public.notifications for update using (true) with check (true);
create policy "notifications_delete" on public.notifications for delete using (true);

-- Policies for admin_user_mapping table

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
as $$
begin
  if new.created_by is not null then
    insert into public.admin_user_mapping (admin_id, user_id)
    values (new.created_by, new.id)
    on conflict do nothing;
  end if;
  return new;
end;
$$;

-- Trigger
drop trigger if exists trg_auto_map_admin_user on public.users;
create trigger trg_auto_map_admin_user
after insert on public.users
for each row
execute function public.auto_map_admin_to_user();

-- Function to update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
drop trigger if exists update_users_updated_at on public.users;
create trigger update_users_updated_at before update on public.users
  for each row execute procedure update_updated_at_column();

drop trigger if exists update_attendance_updated_at on public.attendance;
create trigger update_attendance_updated_at before update on public.attendance
  for each row execute procedure update_updated_at_column();

drop trigger if exists update_advance_updated_at on public.advance;
create trigger update_advance_updated_at before update on public.advance
  for each row execute procedure update_updated_at_column();

drop trigger if exists update_salary_updated_at on public.salary;
create trigger update_salary_updated_at before update on public.salary
  for each row execute procedure update_updated_at_column();