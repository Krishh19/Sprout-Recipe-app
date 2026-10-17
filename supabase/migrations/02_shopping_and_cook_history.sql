-- ============================================================================
-- SPROUT MIGRATION 02: SHOPPING LIST & COOK HISTORY RESILIENCE
-- ============================================================================

-- 1. SHOPPING LIST TABLE
CREATE TABLE IF NOT EXISTS public.shopping_list (
    id TEXT PRIMARY KEY DEFAULT ('shop-' || replace(gen_random_uuid()::text, '-', '')),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    recipe_title TEXT,
    is_bought BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_shopping_list_user ON public.shopping_list (user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_list_created ON public.shopping_list (created_at DESC);

-- Enable RLS on shopping_list
ALTER TABLE public.shopping_list ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can manage their shopping list" ON public.shopping_list;
    CREATE POLICY "Users can manage their shopping list" ON public.shopping_list
        FOR ALL
        TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
END $$;

-- 2. COOK HISTORY RESILIENCE & METADATA
ALTER TABLE public.cook_history DROP CONSTRAINT IF EXISTS cook_history_recipe_id_fkey;
ALTER TABLE public.cook_history ALTER COLUMN recipe_id DROP NOT NULL;
ALTER TABLE public.cook_history ALTER COLUMN recipe_id TYPE TEXT USING recipe_id::text;
ALTER TABLE public.cook_history ADD COLUMN IF NOT EXISTS recipe_title TEXT;
ALTER TABLE public.cook_history ADD COLUMN IF NOT EXISTS cuisine TEXT;
ALTER TABLE public.cook_history ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.cook_history ADD COLUMN IF NOT EXISTS total_time_mins INTEGER;

-- Enable RLS policies for user data tables
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can manage their cook history" ON public.cook_history;
    CREATE POLICY "Users can manage their cook history" ON public.cook_history
        FOR ALL
        TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can manage their saved recipes" ON public.saved_recipes;
    CREATE POLICY "Users can manage their saved recipes" ON public.saved_recipes
        FOR ALL
        TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can manage their collections" ON public.collections;
    CREATE POLICY "Users can manage their collections" ON public.collections
        FOR ALL
        TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can manage their collection recipes" ON public.collection_recipes;
    CREATE POLICY "Users can manage their collection recipes" ON public.collection_recipes
        FOR ALL
        TO authenticated
        USING (
            EXISTS (
                SELECT 1 FROM public.collections c
                WHERE c.id = collection_recipes.collection_id
                  AND c.user_id = auth.uid()
            )
        )
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.collections c
                WHERE c.id = collection_recipes.collection_id
                  AND c.user_id = auth.uid()
            )
        );

    DROP POLICY IF EXISTS "Users can view and edit own profile" ON public.user_profiles;
    CREATE POLICY "Users can view and edit own profile" ON public.user_profiles
        FOR ALL
        TO authenticated
        USING (auth.uid() = id)
        WITH CHECK (auth.uid() = id);
END $$;
