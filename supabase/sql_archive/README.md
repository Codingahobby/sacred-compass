# Supabase SQL archive

These scripts record SQL already applied to the hosted `sacred-compass-dev` project. Keep them for reference and avoid rerunning them against that project.

1. `01_places_and_categories.sql` creates categories, places, and their relationships.
2. `02_images_and_sources.sql` adds place images and sources.
3. `03_users_and_permissions.sql` adds profiles, favourites, and admin membership with their access policies.
4. `04_storage_read_policy.sql` adds the Storage read policy for approved images of published places in the private `place-images` bucket.
