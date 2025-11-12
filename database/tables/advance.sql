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

-- Enable RLS
alter table public.advance enable row level security;

-- Create RLS policies for advance table
drop policy if exists "advance_select" on public.advance;
drop policy if exists "advance_insert" on public.advance;
drop policy if exists "advance_update" on public.advance;
drop policy if exists "advance_delete" on public.advance;

create policy "advance_select" on public.advance for select using (true);
create policy "advance_insert" on public.advance for insert with check (true);
create policy "advance_update" on public.advance for update using (true) with check (true);
create policy "advance_delete" on public.advance for delete using (true);

-- Function to update updated_at timestamp
create or replace function update_advance_updated_at_column()
returns trigger as $$
begin
   NEW.updated_at = now();
   return NEW;
end;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
drop trigger if exists update_advance_updated_at on public.advance;
create trigger update_advance_updated_at before update on public.advance
  for each row execute procedure update_advance_updated_at_column();