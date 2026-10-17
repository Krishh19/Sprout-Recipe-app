import csv, os, urllib.parse

with open('storage_names.txt', 'r', encoding='utf-8') as f:
    storage_names = set(line.strip() for line in f if line.strip())

prefix_map = {}
base_map = {}
for s in storage_names:
    parts = s.split('.', 1)
    if len(parts) == 2 and parts[0].isdigit():
        prefix_map[int(parts[0])] = s
        base_map[parts[1]] = s

with open('cuisines.csv', 'r', encoding='utf-8', errors='ignore') as f:
    rows = list(csv.DictReader(f))

exact_matches = 0
prefix_matches = 0
base_matches = 0
mismatches = []

for idx, r in enumerate(rows):
    url = r.get('image_url', '').strip()
    path = urllib.parse.urlparse(url).path
    base = os.path.basename(path)
    expected = f"{idx + 1}.{base}"
    
    if expected in storage_names:
        exact_matches += 1
    elif (idx + 1) in prefix_map:
        prefix_matches += 1
        mismatches.append(('PREFIX_MATCH_DIFF_BASE', idx + 1, r['name'], expected, prefix_map[idx + 1]))
    elif base in base_map:
        base_matches += 1
        mismatches.append(('BASE_MATCH_DIFF_PREFIX', idx + 1, r['name'], expected, base_map[base]))
    else:
        mismatches.append(('NO_MATCH', idx + 1, r['name'], expected, 'NONE'))

print(f"Total rows in CSV: {len(rows)}")
print(f"Exact matches (idx+1 . base): {exact_matches}")
print(f"Prefix matches where base differed: {prefix_matches}")
print(f"Base matches where prefix differed: {base_matches}")
print(f"Total mismatches: {len(mismatches)}")
print("\nFirst 15 mismatches:")
for m in mismatches[:15]:
    print(" ", m)
