
begin;

-- Images associated with sacred places
create table public.place_images (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null
    references public.places(id) on delete cascade,

  storage_path text not null unique,
  caption text,
  alt_text text,
  photographer_credit text,
  rights_status text not null default 'pending'
    check (rights_status in (
      'pending', 'licensed', 'owned',
      'public_domain', 'permission_granted'
    )),
  rights_notes text,
  display_order integer not null default 0
    check (display_order >= 0),
  created_at timestamptz not null default now()
);

-- Historical and cultural references
create table public.place_sources (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null
    references public.places(id) on delete cascade,

  title text not null,
  publisher text,
  source_url text
    check (source_url is null or source_url ~* '^https?://'),
  citation_notes text,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

-- Index foreign keys
create index place_images_place_id_idx
  on public.place_images(place_id);

create index place_sources_place_id_idx
  on public.place_sources(place_id);

-- Enable Row Level Security
alter table public.place_images enable row level security;
alter table public.place_sources enable row level security;

-- Read-only permissions for mobile clients
revoke all on public.place_images,
  public.place_sources from anon, authenticated;

grant select on public.place_images,
  public.place_sources to anon, authenticated;

-- Only images from published places
create policy "Public can read published place images"
on public.place_images
for select to anon, authenticated
using (
  rights_status in (
    'licensed', 'owned',
    'public_domain', 'permission_granted'
  )
  and exists (
    select 1 from public.places p
    where p.id = place_id
      and p.status = 'published'
  )
);

-- Only sources from published places
create policy "Public can read published place sources"
on public.place_sources
for select to anon, authenticated
using (
  exists (
    select 1 from public.places p
    where p.id = place_id
      and p.status = 'published'
  )
);

commit;
