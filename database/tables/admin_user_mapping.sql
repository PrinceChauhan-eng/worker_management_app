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