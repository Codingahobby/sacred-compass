
begin;

-- 1. Categories
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  created_at timestamptz not null default now()
);

-- 2. Sacred places
create table public.places (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  summary text,
  history text,
  visitor_guidance text,

  country text not null,
  region text,
  city text,
  address text,

  latitude double precision
    check (latitude between -90 and 90),
  longitude double precision
    check (longitude between -180 and 180),

  status text not null default 'draft'
    check (status in (
      'draft', 'in_review', 'published', 'archived'
    )),

  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint valid_coordinate_pair
    check (
      (latitude is null) = (longitude is null)
    ),

  constraint valid_publication
    check (
      status <> 'published'
      or (
        published_at is not null
        and latitude is not null
        and longitude is not null
      )
    )
);

-- 3. Place-to-category relationships
create table public.place_categories (
  place_id uuid not null
    references public.places(id) on delete cascade,
  category_id uuid not null
    references public.categories(id) on delete cascade,
  primary key (place_id, category_id)
);

-- Helpful indexes
create index places_status_idx
  on public.places(status);

create index place_categories_category_idx
  on public.place_categories(category_id);

-- Enable security on every table
alter table public.categories enable row level security;
alter table public.places enable row level security;
alter table public.place_categories enable row level security;

-- API access is read-only for now
revoke all on public.categories,
  public.places, public.place_categories
  from anon, authenticated;

grant select on public.categories,
  public.places, public.place_categories
  to anon, authenticated;

-- Visitors can read categories
create policy "Public can read categories"
on public.categories
for select to anon, authenticated
using (true);

-- Visitors can read published places only
create policy "Public can read published places"
on public.places
for select to anon, authenticated
using (status = 'published');

-- Only category links for published places are visible
create policy "Public can read published place categories"
on public.place_categories
for select to anon, authenticated
using (
  exists (
    select 1 from public.places p
    where p.id = place_id
      and p.status = 'published'
  )
);

commit;
