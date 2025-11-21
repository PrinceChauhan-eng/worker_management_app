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
  created_at timestamptz default now(),
  -- Add unique constraint for worker_id and date
  unique(worker_id, date)
);

-- Create indexes for login_status table
create index if not exists idx_login_status_worker_id on public.login_status(worker_id);
create index if not exists idx_login_status_date on public.login_status(date);
create index if not exists idx_login_status_worker_date on public.login_status(worker_id, date);
create index if not exists idx_login_status_is_logged_in on public.login_status(is_logged_in);

-- Enable RLS
alter table public.login_status enable row level security;

-- Create RLS policies for login_status table
drop policy if exists "login_status_select" on public.login_status;
drop policy if exists "login_status_insert" on public.login_status;
drop policy if exists "login_status_update" on public.login_status;
drop policy if exists "login_status_delete" on public.login_status;

create policy "login_status_select" on public.login_status for select using (true);
create policy "login_status_insert" on public.login_status for insert with check (true);
create policy "login_status_update" on public.login_status for update using (true) with check (true);
create policy "login_status_delete" on public.login_status for delete using (true);