-- ATTENDANCE LOGS TABLE (for multiple punch logs per day)
create table if not exists public.attendance_logs (
  id bigint generated always as identity primary key,
  worker_id bigint references public.users(id) on delete cascade,
  date date default current_date,
  punch_time text not null, -- HH:MM:SS format
  punch_type text not null check (punch_type in ('login', 'logout')),
  location_latitude double precision,
  location_longitude double precision,
  location_address text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Create indexes for attendance_logs table
create index if not exists idx_attendance_logs_worker_id on public.attendance_logs(worker_id);
create index if not exists idx_attendance_logs_date on public.attendance_logs(date);
create index if not exists idx_attendance_logs_worker_date on public.attendance_logs(worker_id, date);
create index if not exists idx_attendance_logs_date_punch on public.attendance_logs(date, punch_time);

-- Enable RLS
alter table public.attendance_logs enable row level security;

-- Create RLS policies for attendance_logs table
drop policy if exists "attendance_logs_select" on public.attendance_logs;
drop policy if exists "attendance_logs_insert" on public.attendance_logs;
drop policy if exists "attendance_logs_update" on public.attendance_logs;
drop policy if exists "attendance_logs_delete" on public.attendance_logs;

create policy "attendance_logs_select" on public.attendance_logs for select using (true);
create policy "attendance_logs_insert" on public.attendance_logs for insert with check (true);
create policy "attendance_logs_update" on public.attendance_logs for update using (true) with check (true);
create policy "attendance_logs_delete" on public.attendance_logs for delete using (true);

-- Function to update updated_at timestamp
create or replace function update_attendance_logs_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
drop trigger if exists update_attendance_logs_updated_at on public.attendance_logs;
create trigger update_attendance_logs_updated_at before update on public.attendance_logs
  for each row execute procedure update_attendance_logs_updated_at_column();