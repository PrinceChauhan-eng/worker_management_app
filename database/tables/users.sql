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

-- Enable RLS
alter table public.users enable row level security;

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
  -- Set created_by automatically
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

-- Function to update updated_at timestamp
create or replace function update_users_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
drop trigger if exists update_users_updated_at on public.users;
create trigger update_users_updated_at before update on public.users
  for each row execute procedure update_users_updated_at_column();