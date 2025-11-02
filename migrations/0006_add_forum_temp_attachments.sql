-- Create temp attachments table for forum uploads before attaching to topic/reply
-- Safe to run multiple times

-- Ensure pgcrypto for gen_random_uuid()
create extension if not exists pgcrypto;

create table if not exists public.forum_temp_attachments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  file_name text not null,
  file_url text not null,
  file_size bigint not null,
  file_type text not null,
  storage_path text not null,
  created_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists idx_forum_temp_attachments_user_id on public.forum_temp_attachments(user_id);
create index if not exists idx_forum_temp_attachments_created_at on public.forum_temp_attachments(created_at desc);

-- Enable RLS with basic policies (optional if using service role)
alter table public.forum_temp_attachments enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'forum_temp_attachments' and policyname = 'Temp attachments can be inserted by owner'
  ) then
    create policy "Temp attachments can be inserted by owner"
      on public.forum_temp_attachments for insert
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'forum_temp_attachments' and policyname = 'Temp attachments selectable by owner'
  ) then
    create policy "Temp attachments selectable by owner"
      on public.forum_temp_attachments for select
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'forum_temp_attachments' and policyname = 'Temp attachments deletable by owner'
  ) then
    create policy "Temp attachments deletable by owner"
      on public.forum_temp_attachments for delete
      using (auth.uid() = user_id);
  end if;
end $$;


