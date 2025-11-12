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

-- Enable RLS
alter table public.attendance enable row level security;

-- Create RLS policies for attendance table
drop policy if exists "attendance_select" on public.attendance;
drop policy if exists "attendance_insert" on public.attendance;
drop policy if exists "attendance_update" on public.attendance;
drop policy if exists "attendance_delete" on public.attendance;

create policy "attendance_select" on public.attendance for select using (true);
create policy "attendance_insert" on public.attendance for insert with check (true);
create policy "attendance_update" on public.attendance for update using (true) with check (true);
create policy "attendance_delete" on public.attendance for delete using (true);

-- Function to mark absent workers
create or replace function mark_absent_workers()
returns void
language sql
as $$
insert into public.attendance (worker_id, date, present)
select id, current_date, false
from public.users
where role = 'worker'
  and id not in (
    select worker_id from public.attendance where date = current_date
  );
$$;

-- Function to update updated_at timestamp
create or replace function update_attendance_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
drop trigger if exists update_attendance_updated_at on public.attendance;
create trigger update_attendance_updated_at before update on public.attendance
  for each row execute procedure update_attendance_updated_at_column();