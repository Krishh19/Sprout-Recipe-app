import csv
import json
import os
import re
import urllib.parse
import subprocess
import time

def slugify(title):
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    return slug or 'recipe'

def main():
    print("Loading storage names...")
    with open('storage_names.txt', 'r', encoding='utf-8') as f:
        storage_list = [line.strip() for line in f if line.strip()]
    sorted_storage = sorted(storage_list, key=lambda s: int(s.split('.', 1)[0]))
    print(f"Total storage files: {len(sorted_storage)}")

    print("Loading cuisines.csv...")
    with open('cuisines.csv', 'r', encoding='utf-8', errors='ignore') as f:
        rows = list(csv.DictReader(f))
    print(f"Total CSV rows: {len(rows)}")

    assert len(rows) == len(sorted_storage), "Row count and storage count must match!"

    seen_slugs = {}
    bucket_url_prefix = 'https://mbhceqllbamrwlsiimgu.supabase.co/storage/v1/object/public/recipe-images/'
    pairs = []

    for idx, (r, s_file) in enumerate(zip(rows, sorted_storage)):
        title = r.get('name', '').strip()
        if not title:
            continue
        base_slug = slugify(title)
        count = seen_slugs.get(base_slug, 0)
        seen_slugs[base_slug] = count + 1
        slug = base_slug if count == 0 else f'{base_slug}-{count + 1}'

        encoded_filename = urllib.parse.quote(s_file)
        pub_url = f'{bucket_url_prefix}{encoded_filename}'
        pairs.append((slug, pub_url))

    print(f"Total slug->URL pairs: {len(pairs)}")

    # Chunk pairs into batches of 400 for Postgres UPDATE
    batch_size = 400
    batches = [pairs[i:i + batch_size] for i in range(0, len(pairs), batch_size)]
    print(f"Divided into {len(batches)} batches.")

    temp_file = "supabase/temp_update.sql"

    for idx, batch in enumerate(batches):
        values_clause = ",\n".join(
            f"('{slug}', '{url}')"
            for slug, url in batch
        )
        sql = f"""
UPDATE public.recipes AS r
SET image_url = v.image_url,
    image_status = 'verified',
    image_source = 'supabase-storage'
FROM (VALUES
{values_clause}
) AS v(slug, image_url)
WHERE r.slug = v.slug;
"""
        with open(temp_file, "w", encoding="utf-8") as tf:
            tf.write(sql.strip() + "\n")

        print(f"Applying Batch {idx + 1}/{len(batches)} ({len(batch)} recipes)...")
        res = subprocess.run(["supabase", "db", "query", "--linked", "-f", temp_file], capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Batch {idx + 1} FAILED: {res.stderr}")
            return
        print(f"Batch {idx + 1} SUCCESS.")
        time.sleep(0.5)

    try:
        os.remove(temp_file)
    except Exception:
        pass

    print("\nAll batches successfully applied! Verifying sample in DB...")
    verify_cmd = [
        "supabase", "db", "query", "--linked",
        "SELECT title, image_url FROM public.recipes WHERE slug IN ('kara-boondi-kurma-recipe-boondi-in-coconut-milk', 'indian-tea-masala-powder');"
    ]
    res_v = subprocess.run(verify_cmd, capture_output=True, text=True)
    print(res_v.stdout)

if __name__ == '__main__':
    main()
