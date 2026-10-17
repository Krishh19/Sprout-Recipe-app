-- Migration 08: Optimize match_recipes RPC to prevent statement timeout
CREATE OR REPLACE FUNCTION public.match_recipes(
    user_ingredients TEXT[],
    max_time INT DEFAULT NULL,
    cuisine_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    ingredients JSONB,
    cleaned_ingredients TEXT[],
    instructions JSONB,
    total_time_mins INT,
    cuisine TEXT,
    image_url TEXT,
    servings INT,
    rating NUMERIC,
    review_count INT,
    matched_ingredients TEXT[],
    missing_ingredients TEXT[],
    matched_count INT,
    total_count INT,
    match_percentage NUMERIC
) 
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY
    WITH normalized_input AS (
        SELECT ARRAY(
            SELECT DISTINCT LOWER(TRIM(u))
            FROM unnest(user_ingredients) AS u
            WHERE TRIM(u) <> ''
        ) AS norm_user_ing
    ),
    -- Fast candidate filter: prune recipes before expensive unnesting
    candidates AS (
        SELECT r.id, r.title, r.description, r.ingredients, r.cleaned_ingredients,
               r.instructions, r.total_time_mins, r.cuisine, r.image_url, r.servings,
               r.rating, r.review_count, ni.norm_user_ing
        FROM public.recipes r
        CROSS JOIN normalized_input ni
        WHERE
            (max_time IS NULL OR r.total_time_mins <= max_time)
            AND (cuisine_filter IS NULL OR r.cuisine ILIKE '%' || cuisine_filter || '%')
            AND (
                -- Fast array overlap
                r.cleaned_ingredients && ni.norm_user_ing
                OR EXISTS (
                    SELECT 1
                    FROM unnest(ni.norm_user_ing) AS u
                    WHERE array_to_string(r.cleaned_ingredients, ' ') ILIKE '%' || u || '%'
                )
            )
    ),
    matched_results AS (
        SELECT
            c.id, c.title, c.description, c.ingredients, c.cleaned_ingredients,
            c.instructions, c.total_time_mins, c.cuisine, c.image_url, c.servings,
            c.rating, c.review_count,
            matched.matched_ings,
            ARRAY(
                SELECT ing
                FROM unnest(c.cleaned_ingredients) AS ing
                WHERE NOT (ing = ANY(matched.matched_ings))
            ) AS missing_ings,
            cardinality(c.cleaned_ingredients) AS total_ing_count
        FROM candidates c
        CROSS JOIN LATERAL (
            SELECT COALESCE(array_agg(ing), ARRAY[]::TEXT[]) AS matched_ings
            FROM unnest(c.cleaned_ingredients) AS ing
            WHERE EXISTS (
                SELECT 1
                FROM unnest(c.norm_user_ing) AS u
                WHERE ing = u OR ing ILIKE '%' || u || '%' OR u ILIKE '%' || ing || '%'
            )
        ) matched
        WHERE cardinality(matched.matched_ings) > 0
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
    ORDER BY match_percentage DESC, cardinality(mr.matched_ings) DESC, mr.rating DESC
    LIMIT limit_count;
END;
$$;
