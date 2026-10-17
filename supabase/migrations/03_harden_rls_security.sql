-- ============================================================================
-- SPROUT MIGRATION 03: HARDEN ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- 1. SHOPPING LIST
ALTER TABLE public.shopping_list ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their shopping list" ON public.shopping_list;
CREATE POLICY "Users can manage their shopping list" ON public.shopping_list
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 2. COOK HISTORY
ALTER TABLE public.cook_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their cook history" ON public.cook_history;
CREATE POLICY "Users can manage their cook history" ON public.cook_history
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. SAVED RECIPES
ALTER TABLE public.saved_recipes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their saved recipes" ON public.saved_recipes;
CREATE POLICY "Users can manage their saved recipes" ON public.saved_recipes
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. COLLECTIONS
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their collections" ON public.collections;
CREATE POLICY "Users can manage their collections" ON public.collections
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. COLLECTION RECIPES (SCOPED BY PARENT COLLECTION OWNERSHIP)
ALTER TABLE public.collection_recipes ENABLE ROW LEVEL SECURITY;
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

-- 6. USER PROFILES
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view and edit own profile" ON public.user_profiles;
CREATE POLICY "Users can view and edit own profile" ON public.user_profiles
    FOR ALL
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
