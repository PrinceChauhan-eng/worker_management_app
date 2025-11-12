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

-- Enable RLS
alter table public.salary enable row level security;

-- Create RLS policies for salary table
drop policy if exists "salary_select" on public.salary;
drop policy if exists "salary_insert" on public.salary;
drop policy if exists "salary_update" on public.salary;
drop policy if exists "salary_delete" on public.salary;

create policy "salary_select" on public.salary for select using (true);
create policy "salary_insert" on public.salary for insert with check (true);
create policy "salary_update" on public.salary for update using (true) with check (true);
create policy "salary_delete" on public.salary for delete using (true);

-- Function to update updated_at timestamp
create or replace function update_salary_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
drop trigger if exists update_salary_updated_at on public.salary;
create trigger update_salary_updated_at before update on public.salary
  for each row execute procedure update_salary_updated_at_column();