import csv
import json
import os
import re
import string
import subprocess
import time
import urllib.parse
import urllib.request

def slugify(title):
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    return slug or 'recipe'

def clean_cuisine(area, category):
    if not area or area.lower() in ['unknown', 'none', '']:
        if category in ['Pasta']:
            return 'Italian'
        if category in ['Seafood']:
            return 'Mediterranean'
        return 'Continental'
    mapping = {
        'United States': 'American',
        'France': 'French',
        'India': 'Indian',
        'Netherlands': 'Dutch',
    }
    return mapping.get(area, area)

def parse_diet(category, ing_list):
    cat = (category or '').lower()
    if 'vegan' in cat or 'vegetarian' in cat:
        return 'veg'
    
    text = " ".join(ing_list).lower()
    meat_keywords = ['chicken', 'beef', 'pork', 'lamb', 'mutton', 'fish', 'salmon', 'tuna', 'prawn', 'shrimp', 'crab', 'bacon', 'sausage', 'meat', 'prosciutto', 'duck', 'turkey', 'anchov']
    if any(k in text for k in meat_keywords) or cat in ['beef', 'chicken', 'lamb', 'pork', 'seafood', 'goat']:
        return 'non-veg'
    if 'egg' in text or 'egg' in cat:
        return 'egg'
    return 'veg'

def clean_token(ing):
    clean = re.sub(r'\(.*?\)', '', ing).lower()
    clean = re.sub(r'\b(fresh|dried|chopped|diced|sliced|minced|crushed|ground|grated|peeled|cooked|warm|hot|cold|optional)\b', '', clean)
    clean = re.sub(r'\s+', ' ', clean).strip()
    return clean

def parse_instructions(raw_text):
    if not raw_text:
        return ['Follow standard culinary preparation and serve hot.']
    # Split by carriage returns or newlines
    lines = [l.strip() for l in raw_text.replace('\r', '\n').split('\n') if l.strip()]
    cleaned = []
    for l in lines:
        # Remove leading numbers like "1.", "Step 1:"
        step = re.sub(r'^(step\s*\d+[:.]?|\d+[\.\)])\s*', '', l, flags=re.I).strip()
        if step:
            cleaned.append(step)
    if len(cleaned) == 1 and len(cleaned[0]) > 150:
        # Split long single block by sentences
        sentences = re.split(r'\.\s+(?=[A-Z])', cleaned[0])
        cleaned = [s.strip().rstrip('.') + '.' for s in sentences if s.strip()]
    return cleaned or [raw_text.strip()]

def estimate_time(category, instructions_len):
    cat = (category or '').lower()
    if cat in ['breakfast', 'starter', 'side']:
        return 20
    if cat in ['dessert']:
        return 45
    if cat in ['pasta']:
        return 25
    if instructions_len > 7:
        return 50
    return 35

def sql_escape(val):
    if val is None:
        return 'NULL'
    if isinstance(val, bool):
        return 'true' if val else 'false'
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, list):
        return "'" + json.dumps(val).replace("'", "''") + "'::jsonb"
    s = str(val).replace("'", "''")
    return f"'{s}'"

def sql_escape_array(val_list):
    if not val_list:
        return "ARRAY[]::text[]"
    items = []
    for v in val_list:
        s = str(v).replace("'", "''")
        items.append(f"'{s}'")
    return f"ARRAY[{', '.join(items)}]::text[]"

def fetch_all_meals():
    print("Fetching all recipes from TheMealDB API (letters a-z)...")
    meals_by_id = {}
    for letter in string.ascii_lowercase:
        url = f"https://www.themealdb.com/api/json/v1/1/search.php?f={letter}"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                if data.get('meals'):
                    for m in data['meals']:
                        meals_by_id[m['idMeal']] = m
        except Exception as e:
            print(f"Error fetching letter {letter}: {e}")
        time.sleep(0.1)
    print(f"Total unique meals fetched: {len(meals_by_id)}")
    return list(meals_by_id.values())

def main():
    meals = fetch_all_meals()
    
    # Check existing slugs in database
    print("Fetching existing slugs to prevent collisions...")
    res = subprocess.run(["supabase", "db", "query", "--linked", "SELECT slug FROM public.recipes;"], capture_output=True, text=True)
    existing_slugs = set()
    if res.returncode == 0 and '{' in res.stdout:
        try:
            s_idx = res.stdout.find('{')
            e_idx = res.stdout.rfind('}') + 1
            data = json.loads(res.stdout[s_idx:e_idx])
            existing_slugs = set(r['slug'] for r in data['rows'])
        except Exception:
            pass
    print(f"Found {len(existing_slugs)} existing slugs.")

    parsed_recipes = []
    for m in meals:
        title = (m.get('strMeal') or '').strip()
        if not title:
            continue

        base_slug = slugify(title)
        slug = base_slug
        suffix = 1
        while slug in existing_slugs:
            suffix += 1
            slug = f"{base_slug}-{suffix}"
        existing_slugs.add(slug)

        category = (m.get('strCategory') or '').strip()
        area = (m.get('strArea') or '').strip()
        cuisine = clean_cuisine(area, category)

        raw_ings = []
        cleaned_tokens = set()
        for i in range(1, 21):
            ing = (m.get(f'strIngredient{i}') or '').strip()
            meas = (m.get(f'strMeasure{i}') or '').strip()
            if ing:
                line = f"{meas} {ing}".strip()
                raw_ings.append(line)
                token = clean_token(ing)
                if token:
                    cleaned_tokens.add(token)

        instructions = parse_instructions(m.get('strInstructions', ''))
        diet = parse_diet(category, raw_ings)
        time_mins = estimate_time(category, len(instructions))
        image_url = (m.get('strMealThumb') or '').strip()
        source_url = (m.get('strSource') or m.get('strYoutube') or '').strip()

        desc = f"Classic {cuisine} {title.lower()} featuring {', '.join(list(cleaned_tokens)[:3])}."
        if category:
            desc = f"{category} • " + desc

        parsed_recipes.append({
            'title': title,
            'slug': slug,
            'description': desc,
            'ingredients': raw_ings,
            'cleaned_ingredients': sorted(list(cleaned_tokens)),
            'instructions': instructions,
            'total_time_mins': time_mins,
            'cuisine': cuisine,
            'diet': diet,
            'source_url': source_url or None,
            'image_url': image_url or None,
            'image_status': 'verified',
            'image_source': 'themealdb-cdn',
            'data_source': 'themealdb',
            'servings': 4,
            'rating': None,
            'review_count': 0,
            'is_featured': False
        })

    print(f"Successfully processed {len(parsed_recipes)} recipes from TheMealDB.")

    # Generate SQL statements
    batch_size = 150
    batches = [parsed_recipes[i:i + batch_size] for i in range(0, len(parsed_recipes), batch_size)]
    print(f"Inserting into Supabase in {len(batches)} batches...")

    temp_file = "supabase/temp_themealdb.sql"
    for b_idx, batch in enumerate(batches):
        rows_sql = []
        for r in batch:
            row_str = f"""(
                {sql_escape(r['title'])},
                {sql_escape(r['slug'])},
                {sql_escape(r['description'])},
                {sql_escape(r['ingredients'])},
                {sql_escape_array(r['cleaned_ingredients'])},
                {sql_escape(r['instructions'])},
                {sql_escape(r['total_time_mins'])},
                {sql_escape(r['cuisine'])},
                {sql_escape(r['diet'])},
                {sql_escape(r['source_url'])},
                {sql_escape(r['image_url'])},
                {sql_escape(r['servings'])},
                {sql_escape(r['rating'])},
                {sql_escape(r['review_count'])},
                {sql_escape(r['is_featured'])},
                {sql_escape(r['image_status'])},
                {sql_escape(r['image_source'])},
                {sql_escape(r['data_source'])}
            )"""
            rows_sql.append(row_str)

        sql = f"""
INSERT INTO public.recipes (
    title, slug, description, ingredients, cleaned_ingredients, instructions,
    total_time_mins, cuisine, diet, source_url, image_url, servings,
    rating, review_count, is_featured, image_status, image_source, data_source
) VALUES
{','.join(rows_sql)};
"""
        with open(temp_file, "w", encoding="utf-8") as tf:
            tf.write(sql.strip() + "\n")

        print(f"Executing Batch {b_idx + 1}/{len(batches)} ({len(batch)} recipes)...")
        res = subprocess.run(["supabase", "db", "query", "--linked", "-f", temp_file], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Batch {b_idx + 1} FAILED: {res.stderr}")
            return
        print(f"Batch {b_idx + 1} SUCCESS.")
        time.sleep(0.5)

    try:
        os.remove(temp_file)
    except Exception:
        pass

    print("\nAll TheMealDB batches inserted! Verifying counts in DB...")
    res_final = subprocess.run([
        "supabase", "db", "query", "--linked",
        "SELECT data_source, count(*) FROM public.recipes GROUP BY data_source;"
    ], capture_output=True, text=True)
    print(res_final.stdout)

if __name__ == '__main__':
    main()
