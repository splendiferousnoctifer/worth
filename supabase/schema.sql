create table public.worth_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.worth_data enable row level security;
create policy "own row: select" on public.worth_data for select to authenticated using ((select auth.uid()) = user_id);
create policy "own row: insert" on public.worth_data for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own row: update" on public.worth_data for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own row: delete" on public.worth_data for delete to authenticated using ((select auth.uid()) = user_id);
create or replace function public.worth_touch() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;
create trigger worth_touch before update on public.worth_data for each row execute function public.worth_touch();
