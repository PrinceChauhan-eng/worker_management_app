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

-- Enable RLS
alter table public.notifications enable row level security;

-- Create RLS policies for notifications table
drop policy if exists "notifications_select" on public.notifications;
drop policy if exists "notifications_insert" on public.notifications;
drop policy if exists "notifications_update" on public.notifications;
drop policy if exists "notifications_delete" on public.notifications;

create policy "notifications_select" on public.notifications for select using (true);
create policy "notifications_insert" on public.notifications for insert with check (true);
create policy "notifications_update" on public.notifications for update using (true) with check (true);
create policy "notifications_delete" on public.notifications for delete using (true);