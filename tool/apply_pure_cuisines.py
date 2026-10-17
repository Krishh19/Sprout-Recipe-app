import os
import subprocess
import time
import sys

def run_chunk(sql_chunk_path):
    print(f"Applying {sql_chunk_path}...")
    cmd = ["supabase", "db", "query", "--linked", "-f", sql_chunk_path]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error applying {sql_chunk_path}: {res.stderr}")
        return False
    print(f"Successfully applied {sql_chunk_path}.")
    return True

def main():
    migration_file = "supabase/migrations/07_seed_cuisines_pure.sql"
    if not os.path.exists(migration_file):
        print(f"File {migration_file} not found.")
        sys.exit(1)

    with open(migration_file, "r", encoding="utf-8") as f:
        full_sql = f.read()

    # Split by statement (blocks start with INSERT or TRUNCATE)
    statements = full_sql.split(";\n\n")
    print(f"Total SQL statements: {len(statements)}")

    # Group into batches of 4 statements (approx 800 recipes, ~2.5 MB)
    batch_size = 4
    temp_dir = "supabase/temp_chunks"
    os.makedirs(temp_dir, exist_ok=True)

    chunks = []
    current_stmts = []
    for stmt in statements:
        s = stmt.strip()
        if not s:
            continue
        current_stmts.append(s + ";\n\n")
        if len(current_stmts) >= batch_size:
            chunk_file = os.path.join(temp_dir, f"chunk_{len(chunks):02d}.sql")
            with open(chunk_file, "w", encoding="utf-8") as cf:
                cf.writelines(current_stmts)
            chunks.append(chunk_file)
            current_stmts = []

    if current_stmts:
        chunk_file = os.path.join(temp_dir, f"chunk_{len(chunks):02d}.sql")
        with open(chunk_file, "w", encoding="utf-8") as cf:
            cf.writelines(current_stmts)
        chunks.append(chunk_file)

    print(f"Split into {len(chunks)} safe chunks.")

    for i, chunk in enumerate(chunks):
        print(f"\n--- Chunk {i+1} / {len(chunks)} ---")
        success = run_chunk(chunk)
        if not success:
            print("Aborting remaining chunks due to error.")
            sys.exit(1)
        time.sleep(1)

    # Clean up temp chunks
    for chunk in chunks:
        try:
            os.remove(chunk)
        except Exception:
            pass
    try:
        os.rmdir(temp_dir)
    except Exception:
        pass

    print("\nAll chunks successfully applied to Supabase database!")

if __name__ == '__main__':
    main()
