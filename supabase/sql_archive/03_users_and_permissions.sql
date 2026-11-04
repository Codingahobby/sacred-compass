
begin;

-- =========================================
-- 1. USER PROFILES
-- =========================================

create table public.profiles (
  id uuid primary key
    references auth.users(id) on delete cascade,

  display_name text,
  avatar_path text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

revoke all on public.profiles
from anon, authenticated;

grant select on public.profiles to authenticated;

grant update (display_name, avatar_path)
on public.profiles to authenticated;

create policy "Users view their own profile"
on public.profiles
for select to authenticated
using ((select auth.uid()) = id);

create policy "Users update their own profile"
on public.profiles
for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Automatically create a profile on signup

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user()
from public, anon, authenticated;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- Add profiles for any existing users
insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

-- =========================================
-- 2. USER FAVOURITES
-- =========================================

create table public.favourites (
  user_id uuid not null
    references auth.users(id) on delete cascade,

  place_id uuid not null
    references public.places(id) on delete cascade,

  created_at timestamptz not null default now(),

  primary key (user_id, place_id)
);

create index favourites_place_id_idx
on public.favourites(place_id);

alter table public.favourites enable row level security;

revoke all on public.favourites
from anon, authenticated;

grant select, insert, delete
on public.favourites to authenticated;

create policy "Users view their own favourites"
on public.favourites
for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users save published places"
on public.favourites
for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.places p
    where p.id = place_id
      and p.status = 'published'
  )
);

create policy "Users remove their own favourites"
on public.favourites
for delete to authenticated
using ((select auth.uid()) = user_id);

-- =========================================
-- 3. ADMIN MEMBERS
-- =========================================

create table public.admin_members (
  user_id uuid primary key
    references auth.users(id) on delete cascade,

  role text not null
    check (role in (
      'owner', 'editor', 'reviewer'
    )),

  created_at timestamptz not null default now()
);

alter table public.admin_members enable row level security;

revoke all on public.admin_members
from anon, authenticated;

grant select on public.admin_members
to authenticated;

create policy "Admins view their own membership"
on public.admin_members
for select to authenticated
using ((select auth.uid()) = user_id);

commit;
