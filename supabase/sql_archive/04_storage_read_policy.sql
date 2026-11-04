
begin;

create policy "Read approved published place images"
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'place-images'

  -- Permit downloads, not bucket listing
  and storage.allow_any_operation(
    array[
      'object.get_authenticated',
      'object.get_authenticated_info'
    ]
  )

  -- The file must have an approved database record
  and exists (
    select 1
    from public.place_images pi
    join public.places p
      on p.id = pi.place_id
    where pi.storage_path = name
      and p.status = 'published'
      and pi.rights_status in (
        'licensed',
        'owned',
        'public_domain',
        'permission_granted'
      )
  )
);

commit;
