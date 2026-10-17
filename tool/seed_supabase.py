import csv
import json
import os
import re
import sys
import time
import urllib.request
import urllib.error

# Load credentials from .env if present
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
if os.path.exists(env_path):
    with open(env_path, "r", encoding="utf-8") as ef:
        for line in ef:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

# Fallback to arguments if provided: python seed_supabase.py --url <URL> --key <KEY>
LIMIT_RECIPES = None
for i, arg in enumerate(sys.argv):
    if arg == "--url" and i + 1 < len(sys.argv):
        SUPABASE_URL = sys.argv[i + 1].rstrip("/")
    elif arg == "--key" and i + 1 < len(sys.argv):
        SERVICE_ROLE_KEY = sys.argv[i + 1]
    elif arg == "--limit" and i + 1 < len(sys.argv):
        LIMIT_RECIPES = int(sys.argv[i + 1])

NONVEG_PATTERN = re.compile(
    r"\b(chicken|mutton|lamb|beef|pork|bacon|ham|fish|prawns?|shrimp|crab|salmon|tuna|sausage|keema|meat|anchov\w*|seafood)\b",
    re.I
)
EGG_PATTERN = re.compile(r"\b(eggs?|egg whites?|egg yolks?)\b", re.I)

def clean_cuisine(raw_cuisine: str) -> str:
    if not raw_cuisine:
        return "Indian"
    cleaned = raw_cuisine.replace("\ufeff", "").strip()
    cleaned = re.sub(r"\s*recipes?\s*$", "", cleaned, flags=re.I).strip()
    return cleaned or "Indian"

def determine_diet(ingredients_text: str) -> str:
    if NONVEG_PATTERN.search(ingredients_text):
        return "non-veg"
    if EGG_PATTERN.search(ingredients_text):
        return "egg"
    return "veg"

def slugify(title: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return slug or "recipe"

def clean_ingredient_list(raw_cleaned_str: str) -> list:
    if not raw_cleaned_str:
        return []
    parts = raw_cleaned_str.split(",")
    res = []
    for p in parts:
        item = p.strip().lower()
        if "(" in item and ")" in item:
            base = item[:item.find("(")].strip()
            if base:
                res.append(base)
            alt = item[item.find("(") + 1:item.find(")")].strip()
            if alt:
                res.append(alt)
        elif item:
            res.append(item)
    return list(dict.fromkeys(res))

def parse_instructions(raw_inst: str) -> list:
    if not raw_inst:
        return []
    lines = [line.strip() for line in raw_inst.replace("\r", "\n").split("\n") if line.strip()]
    return lines

def parse_ingredients_detailed(raw_ing: str) -> list:
    if not raw_ing:
        return []
    return [i.strip() for i in raw_ing.split(",") if i.strip()]

def post_batch(batch: list, headers: dict, retries: int = 3) -> bool:
    url = f"{SUPABASE_URL}/rest/v1/recipes?on_conflict=slug"
    data = json.dumps(batch).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=45) as resp:
                return resp.status in (200, 201)
        except urllib.error.HTTPError as e:
            err_msg = e.read().decode("utf-8", errors="replace")[:250]
            print(f"HTTP Error {e.code} on attempt {attempt + 1}: {err_msg}")
        except Exception as e:
            print(f"Network error on attempt {attempt + 1}: {e}")
        time.sleep(2 ** attempt)
    return False

def main():
    dry_run = "--dry-run" in sys.argv
    truncate = "--truncate" in sys.argv

    if not dry_run and (not SUPABASE_URL or not SERVICE_ROLE_KEY):
        print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in environment")
        print("or passed via --url <url> --key <key>")
        print("Alternatively, pass --dry-run to validate dataset parsing without uploading.")
        sys.exit(1)

    csv_path = "Cleaned_Indian_Food_Dataset.csv"
    if not os.path.exists(csv_path):
        print(f"CSV file not found at: {csv_path}")
        sys.exit(1)

    print(f"Parsing {csv_path}...")
    seen_slugs = {}
    rows = []
    diet_counts = {"veg": 0, "egg": 0, "non-veg": 0}
    skipped_times = 0

    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            title = r.get("TranslatedRecipeName", "").strip()
            if not title:
                continue

            # Unique slug calculation
            base_slug = slugify(title)
            count = seen_slugs.get(base_slug, 0)
            seen_slugs[base_slug] = count + 1
            slug = base_slug if count == 0 else f"{base_slug}-{count + 1}"

            # Time parsing & outlier validation
            try:
                mins = int(r.get("TotalTimeInMins", 0) or 0)
            except ValueError:
                mins = 30
            if mins <= 0 or mins > 480:
                skipped_times += 1
                mins = 30  # normalize absurd times to standard 30 min default

            cleaned_ing_str = r.get("Cleaned-Ingredients", "")
            diet = determine_diet(cleaned_ing_str)
            diet_counts[diet] += 1

            rows.append({
                "title": title,
                "slug": slug,
                "description": f"Traditional {clean_cuisine(r.get('Cuisine', ''))} recipe cooked with care.",
                "cuisine": clean_cuisine(r.get("Cuisine", "")),
                "diet": diet,
                "ingredients": parse_ingredients_detailed(r.get("TranslatedIngredients", "")),
                "cleaned_ingredients": clean_ingredient_list(cleaned_ing_str),
                "instructions": parse_instructions(r.get("TranslatedInstructions", "")),
                "total_time_mins": mins,
                "source_url": r.get("URL", "").strip(),
                "image_url": None,  # Scraped URLs removed to prevent photo mismatch & copyright issues
                "image_status": "none",
                "data_source": "archanaskitchen-csv",
                "servings": 4,
                "rating": None,
                "review_count": 0,
                "is_featured": False
            })

    print(f"Parsed {len(rows)} recipes successfully.")
    print(f"Diet distribution: Veg: {diet_counts['veg']} | Egg: {diet_counts['egg']} | Non-Veg: {diet_counts['non-veg']}")
    print(f"Normalized {skipped_times} outlier cooking times.")

    if LIMIT_RECIPES:
        rows = rows[:LIMIT_RECIPES]
        print(f"Limiting upload to first {len(rows)} recipes (--limit {LIMIT_RECIPES}).")

    if dry_run:
        print("[DRY RUN] Finished without making network requests.")
        return

    headers = {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json; charset=utf-8",
        "Accept": "application/json; charset=utf-8",
        "Prefer": "resolution=merge-duplicates,return=minimal"
    }

    if truncate:
        print("Truncating existing recipes table...")
        del_url = f"{SUPABASE_URL}/rest/v1/recipes"
        req = urllib.request.Request(del_url, headers=headers, method="DELETE")
        try:
            with urllib.request.urlopen(req) as resp:
                print(f"Truncate response: {resp.status}")
        except Exception as e:
            print(f"Warning: Could not truncate table via REST API (RLS/cascade): {e}")

    batch_size = 50
    failed_batches = 0
    print(f"Uploading {len(rows)} recipes in batches of {batch_size}...")

    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        success = post_batch(batch, headers)
        if not success:
            failed_batches += 1
            print(f"Batch {i // batch_size + 1} failed after retries.")
        else:
            if (i // batch_size + 1) % 10 == 0 or (i + batch_size) >= len(rows):
                print(f"Progress: {min(i + batch_size, len(rows))}/{len(rows)} recipes uploaded.")

    if failed_batches == 0:
        print("ALL RECIPES UPLOADED SUCCESSFULLY!")
    else:
        print(f"Upload completed with {failed_batches} failed batches.")

if __name__ == "__main__":
    main()
