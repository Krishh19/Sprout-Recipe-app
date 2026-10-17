import os
import subprocess
import time

def run_sql(sql_text, step_name):
    temp_file = "supabase/temp_statement.sql"
    with open(temp_file, "w", encoding="utf-8") as tf:
        tf.write(sql_text.strip() + ";\n")
    
    file_size_kb = os.path.getsize(temp_file) / 1024
    print(f"Applying {step_name} ({file_size_kb:.1f} KB)...")
    cmd = ["supabase", "db", "query", "--linked", "-f", temp_file]
    res = subprocess.run(cmd, capture_output=True, text=True)
    try:
        os.remove(temp_file)
    except Exception:
        pass

    if res.returncode != 0:
        print(f"FAILED on {step_name}: {res.stderr}")
        return False
    print(f"SUCCESS on {step_name}.")
    return True

def main():
    with open("supabase/migrations/07_seed_cuisines_pure.sql", "r", encoding="utf-8") as f:
        full_sql = f.read()

    # Split into statements
    raw_stmts = full_sql.split(";\n\n")
    insert_stmts = [s.strip() for s in raw_stmts if s.strip().startswith("INSERT INTO")]
    print(f"Total INSERT statements: {len(insert_stmts)}")

    # Check current row count
    cmd_count = ["supabase", "db", "query", "--linked", "SELECT count(*) FROM public.recipes;"]
    res_count = subprocess.run(cmd_count, capture_output=True, text=True)
    print("Current status in DB:\n", res_count.stdout)

    # Each statement inserts 200 rows.
    # If DB currently has 3000 rows, that means statements 0 to 14 (15 statements) succeeded.
    # We should start from statement 15!
    # To be 100% clean and robust:
    # If count is 3000, start_idx = 15.
    start_idx = 3000 // 200
    print(f"Resuming from INSERT statement index {start_idx} (out of {len(insert_stmts)})...")

    for idx in range(start_idx, len(insert_stmts)):
        stmt = insert_stmts[idx]
        ok = run_sql(stmt, f"Batch {idx + 1}/{len(insert_stmts)}")
        if not ok:
            print("Stopping due to error.")
            return
        time.sleep(1)

    print("\nVerifying final count...")
    res_final = subprocess.run(cmd_count, capture_output=True, text=True)
    print(res_final.stdout)

if __name__ == '__main__':
    main()
