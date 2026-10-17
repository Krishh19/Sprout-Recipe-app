-- Migration 05: Recipe Quality, Diet Classification & Metadata Schema
-- ============================================================================

-- Clean table re-seed (Option B): truncate existing recipes to remove duplicated slugs
TRUNCATE TABLE public.recipes CASCADE;

ALTER TABLE public.recipes
  ADD COLUMN IF NOT EXISTS region TEXT,
  ADD COLUMN IF NOT EXISTS diet TEXT NOT NULL DEFAULT 'veg'
                         CHECK (diet IN ('veg', 'egg', 'non-veg')),
  ADD COLUMN IF NOT EXISTS image_status TEXT NOT NULL DEFAULT 'none'
                         CHECK (image_status IN ('none', 'verified', 'mismatch', 'unsure')),
  ADD COLUMN IF NOT EXISTS image_source TEXT,
  ADD COLUMN IF NOT EXISTS image_license TEXT,
  ADD COLUMN IF NOT EXISTS data_source TEXT;

-- Remove hardcoded 4.8 default ratings and reset review default
ALTER TABLE public.recipes ALTER COLUMN rating DROP DEFAULT;
ALTER TABLE public.recipes ALTER COLUMN review_count SET DEFAULT 0;

-- Additional performance indexes for diet, lower-case cuisine lookups, and unique slugs
CREATE INDEX IF NOT EXISTS idx_recipes_diet ON public.recipes (diet);
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine_lower ON public.recipes (lower(cuisine));
CREATE UNIQUE INDEX IF NOT EXISTS idx_recipes_slug_unique ON public.recipes (slug);
