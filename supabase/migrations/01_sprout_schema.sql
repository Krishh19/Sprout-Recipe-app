-- ============================================================================
-- SPROUT DATABASE SCHEMA
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. RECIPES TABLE
CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT,
    description TEXT,
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    cleaned_ingredients TEXT[] NOT NULL DEFAULT '{}',
    instructions JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_time_mins INTEGER DEFAULT 30,
    cuisine TEXT DEFAULT 'Indian',
    source_url TEXT,
    image_url TEXT,
    servings INTEGER DEFAULT 4,
    rating NUMERIC(3, 2) DEFAULT 4.8,
    review_count INTEGER DEFAULT 28,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for lightning-fast queries
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine ON public.recipes (cuisine);
CREATE INDEX IF NOT EXISTS idx_recipes_total_time ON public.recipes (total_time_mins);
CREATE INDEX IF NOT EXISTS idx_recipes_rating ON public.recipes (rating DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_cleaned_ingredients ON public.recipes USING GIN (cleaned_ingredients);
CREATE INDEX IF NOT EXISTS idx_recipes_title_trgm ON public.recipes USING GIN (title gin_trgm_ops);

-- 2. USER PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY,
    display_name TEXT DEFAULT 'Chef',
    dietary_preferences TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. SAVED RECIPES (FAVORITES) TABLE
CREATE TABLE IF NOT EXISTS public.saved_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_saved_recipe UNIQUE (user_id, recipe_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_recipes_user ON public.saved_recipes (user_id);

-- 4. COLLECTIONS TABLE
CREATE TABLE IF NOT EXISTS public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'bookmark',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_collections_user ON public.collections (user_id);

-- 5. COLLECTION RECIPES JUNCTION
CREATE TABLE IF NOT EXISTS public.collection_recipes (
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (collection_id, recipe_id)
);

-- 6. COOK HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.cook_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    cooked_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cook_history_user ON public.cook_history (user_id);

-- ============================================================================
-- RECIPE MATCHING RPC FUNCTION
-- Calculates overlapping ingredients and match percentage in a single query
-- ============================================================================
CREATE OR REPLACE FUNCTION public.match_recipes(
    user_ingredients TEXT[],
    max_time INTEGER DEFAULT NULL,
    cuisine_filter TEXT DEFAULT NULL,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    ingredients JSONB,
    cleaned_ingredients TEXT[],
    instructions JSONB,
    total_time_mins INTEGER,
    cuisine TEXT,
    image_url TEXT,
    servings INTEGER,
    rating NUMERIC,
    review_count INTEGER,
    matched_ingredients TEXT[],
    missing_ingredients TEXT[],
    matched_count INTEGER,
    total_count INTEGER,
    match_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH normalized_input AS (
        SELECT array_agg(LOWER(TRIM(x))) AS norm_user_ing
        FROM unnest(user_ingredients) AS x
        WHERE TRIM(x) <> ''
    ),
    matched_results AS (
        SELECT
            r.id,
            r.title,
            r.description,
            r.ingredients,
            r.cleaned_ingredients,
            r.instructions,
            r.total_time_mins,
            r.cuisine,
            r.image_url,
            r.servings,
            r.rating,
            r.review_count,
            ARRAY(
                SELECT ing
                FROM unnest(r.cleaned_ingredients) AS ing
                WHERE EXISTS (
                    SELECT 1
                    FROM unnest(ni.norm_user_ing) AS u
                    WHERE ing ILIKE '%' || u || '%' OR u ILIKE '%' || ing || '%'
                )
            ) AS matched_ings,
            ARRAY(
                SELECT ing
                FROM unnest(r.cleaned_ingredients) AS ing
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM unnest(ni.norm_user_ing) AS u
                    WHERE ing ILIKE '%' || u || '%' OR u ILIKE '%' || ing || '%'
                )
            ) AS missing_ings,
            cardinality(r.cleaned_ingredients) AS total_ing_count
        FROM public.recipes r
        CROSS JOIN normalized_input ni
        WHERE
            (max_time IS NULL OR r.total_time_mins <= max_time)
            AND (cuisine_filter IS NULL OR r.cuisine ILIKE '%' || cuisine_filter || '%')
    )
    SELECT
        mr.id,
        mr.title,
        mr.description,
        mr.ingredients,
        mr.cleaned_ingredients,
        mr.instructions,
        mr.total_time_mins,
        mr.cuisine,
        mr.image_url,
        mr.servings,
        mr.rating,
        mr.review_count,
        mr.matched_ings AS matched_ingredients,
        mr.missing_ings AS missing_ingredients,
        cardinality(mr.matched_ings) AS matched_count,
        mr.total_ing_count AS total_count,
        ROUND(
            CASE 
                WHEN mr.total_ing_count = 0 THEN 0
                ELSE (cardinality(mr.matched_ings)::NUMERIC / mr.total_ing_count::NUMERIC) * 100
            END, 1
        ) AS match_percentage
    FROM matched_results mr
    WHERE cardinality(mr.matched_ings) > 0
    ORDER BY match_percentage DESC, cardinality(mr.matched_ings) DESC, mr.rating DESC
    LIMIT limit_count;
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cook_history ENABLE ROW LEVEL SECURITY;

-- Recipes are viewable by anyone (anon & authenticated)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'recipes' AND policyname = 'Public read recipes'
    ) THEN
        CREATE POLICY "Public read recipes" ON public.recipes FOR SELECT USING (true);
    END IF;
END $$;
