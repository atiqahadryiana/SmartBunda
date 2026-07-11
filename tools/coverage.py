import csv, sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
path = sys.argv[1] if len(sys.argv) > 1 else "assets/myfcd_foods.csv"
rows = list(csv.DictReader(open(path, encoding="utf-8")))
cols = ["calories", "protein", "carbs", "fat", "iron", "folate",
        "calcium", "vitamin_d", "vitamin_b12", "sodium"]
print("total rows:", len(rows))
print("per-column non-empty:")
for c in cols:
    n = sum(1 for r in rows if r[c] not in ("", None))
    print(f"  {c:<13} {n:>4}/{len(rows)}")
print("\nfirst 8 names:")
for r in rows[:8]:
    print("  ", r["id"], "|", r["name"])
