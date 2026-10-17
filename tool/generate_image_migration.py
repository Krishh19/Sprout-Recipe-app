import zipfile
import csv
import io
import os
import re
import urllib.parse

def main():
    # 1. Load Cleaned_Indian_Food_Dataset.csv
    csv_path = "Cleaned_Indian_Food_Dataset.csv"
    with open(csv_path, encoding="utf-8") as f:
        recipes = list(csv.DictReader(f))

    # 2. Load uploaded files from archive/data
    data_dir = r"C:\Users\krish\Downloads\Compressed\archive\data"
    if not os.path.exists(data_dir):
        print("Data directory not found:", data_dir)
        return
    uploaded_files = os.listdir(data_dir)

    base_to_uploaded = {}
    for uf in uploaded_files:
        parts = uf.split('.', 1)
        if len(parts) == 2:
            num, rest = parts
            base_to_uploaded[rest.lower()] = uf

    # 3. Load cuisines.csv
    with zipfile.ZipFile(r'C:\Users\krish\Downloads\Compressed\archive.zip', 'r') as z:
        with z.open('cuisines.csv') as f:
            text = io.TextIOWrapper(f, encoding='utf-8', errors='ignore')
            cuisines_rows = list(csv.DictReader(text))

    def norm(s):
        return re.sub(r'[^a-z0-9]', '', s.lower())

    name_to_uploaded = {}
    for cr in cuisines_rows:
        base = os.path.basename(cr['image_url']).lower()
        if base in base_to_uploaded:
            uf = base_to_uploaded[base]
            name_to_uploaded[norm(cr['name'])] = uf

    def slugify(title):
        slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
        return slug or 'recipe'

    # Track seen slugs exactly like tool/seed_supabase.py
    seen_slugs = {}
    
    matches = []
    bucket_url_prefix = "https://mbhceqllbamrwlsiimgu.supabase.co/storage/v1/object/public/recipe-images/"

    for r in recipes:
        title = r.get("TranslatedRecipeName", "").strip()
        if not title:
            continue
        base_slug = slugify(title)
        count = seen_slugs.get(base_slug, 0)
        seen_slugs[base_slug] = count + 1
        slug = base_slug if count == 0 else f"{base_slug}-{count + 1}"

        orig_url = r.get('image-url', '')
        url_base = os.path.basename(urllib.parse.urlparse(orig_url).path).lower()
        title_norm = norm(title)

        matched_file = None
        if url_base in base_to_uploaded:
            matched_file = base_to_uploaded[url_base]
        elif title_norm in name_to_uploaded:
            matched_file = name_to_uploaded[title_norm]

        if matched_file:
            # URL encode filename for web/http safety (spaces, special chars)
            encoded_file = urllib.parse.quote(matched_file)
            full_url = f"{bucket_url_prefix}{encoded_file}"
            matches.append((slug, full_url))

    print(f"Matched {len(matches)} out of {len(recipes)} recipes.")

    # Write SQL migration file
    out_sql_path = "supabase/migrations/06_link_storage_images.sql"
    os.makedirs(os.path.dirname(out_sql_path), exist_ok=True)
    with open(out_sql_path, "w", encoding="utf-8") as sf:
        sf.write("-- Migration 06: Link Uploaded Recipe Images from Supabase Storage\n")
        sf.write("-- Bucket: recipe-images (Public)\n")
        sf.write(f"-- Total matched images: {len(matches)}\n")
        sf.write("-- ============================================================================\n\n")
        
        # Batch into chunks of 500 for fast execution in Supabase SQL editor
        chunk_size = 500
        for i in range(0, len(matches), chunk_size):
            chunk = matches[i:i + chunk_size]
            sf.write("UPDATE public.recipes AS r\nSET\n  image_url = v.img,\n  image_status = 'verified'\nFROM (VALUES\n")
            value_lines = []
            for slug, img_url in chunk:
                # Escape single quotes in slug and url
                s_esc = slug.replace("'", "''")
                u_esc = img_url.replace("'", "''")
                value_lines.append(f"  ('{s_esc}', '{u_esc}')")
            sf.write(",\n".join(value_lines))
            sf.write("\n) AS v(slug, img)\nWHERE r.slug = v.slug;\n\n")

    print(f"Generated {out_sql_path} successfully.")

if __name__ == "__main__":
    main()
