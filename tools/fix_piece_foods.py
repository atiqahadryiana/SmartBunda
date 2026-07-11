"""Recompute piece-based foods to per-PIECE servings with Atwater-consistent
calories, then rewrite those rows in tools/foods_master.csv.

Why: countable foods (roti jala, satay, kuih, dim sum, breads, dosai, etc.)
were stored as vague "1 serving / 1 plate" with eyeballed totals that didn't
match MyFCD. Here each such food is defined by:
  • pieces        — typical serving count
  • g_per_piece   — realistic edible weight of ONE piece (MyFCD-style)
  • per-100g density (protein/carb/fat g; iron/folate/calcium/sodium/D/B12)
and the per-serving macros + energy are DERIVED:
  grams   = pieces * g_per_piece
  macro   = density_per_100g * grams / 100
  energy  = 4*protein + 4*carbs + 9*fat        (Atwater system)
This makes calories internally consistent with the macros and tied to a
defensible per-100g density. Reference: Atwater factors (protein 4, carb 4,
fat 9 kcal/g) — Monash "Calculating energy value of food".

Sanity anchor from the user: 2 pcs roti jala ≈ 84.7 kcal at 23 g/pc
(→ ~184 kcal/100g). The roti-jala density below reproduces that.
"""

import csv
from pathlib import Path

CSV_PATH = Path(__file__).resolve().parent / "foods_master.csv"

# name -> (pieces, g_per_piece, density per 100g dict)
# density keys: p,c,f (g) ; iron,folate,calcium,vitd,b12,sodium (per 100g)
# Densities are MyFCD-grounded estimates for cooked Malaysian/Asian/Western
# items; energy is computed by Atwater, not stored here.
PIECE_FOODS = {
    # ── Malay sides ──
    "Roti Jala": dict(label="2 pieces", pcs=2, g=23,
                      p=5.2, c=33.25, f=3.37, iron=0.89, folate=0, calcium=3, vitd=0, b12=0, sodium=241),
    "Satay Ayam (10 sticks)": dict(label="10 sticks", pcs=10, g=18,
                      p=24.0, c=6.0, f=12.0, iron=1.4, folate=12, calcium=20, vitd=0.2, b12=0.6, sodium=420),
    "Ketupat (2 pieces)": dict(label="2 pieces", pcs=2, g=40,
                      p=2.6, c=24.0, f=0.3, iron=0.5, folate=4, calcium=6, vitd=0, b12=0, sodium=4),
    "Otak-Otak (3 pieces)": dict(label="3 pieces", pcs=3, g=30,
                      p=11.0, c=6.0, f=8.0, iron=1.0, folate=12, calcium=45, vitd=0.8, b12=1.0, sodium=420),
    "Keropok Lekor (5 pieces)": dict(label="5 pieces", pcs=5, g=25,
                      p=7.0, c=24.0, f=6.0, iron=0.9, folate=8, calcium=30, vitd=0.4, b12=0.6, sodium=400),
    "Cucur Udang (3 pieces)": dict(label="3 pieces", pcs=3, g=35,
                      p=6.0, c=24.0, f=10.0, iron=1.2, folate=16, calcium=40, vitd=0.3, b12=0.4, sodium=340),
    "Popia Basah (2 rolls)": dict(label="2 rolls", pcs=2, g=70,
                      p=5.0, c=22.0, f=4.0, iron=1.1, folate=22, calcium=36, vitd=0.1, b12=0.2, sodium=320),
    "Popia Goreng (3 pieces)": dict(label="3 pieces", pcs=3, g=30,
                      p=5.0, c=24.0, f=11.0, iron=1.1, folate=16, calcium=32, vitd=0.1, b12=0.1, sodium=380),
    # ── Malay kuih/desserts ──
    "Kuih Seri Muka": dict(label="1 piece", pcs=1, g=55,
                      p=4.5, c=42.0, f=9.0, iron=0.9, folate=10, calcium=28, vitd=0.1, b12=0.1, sodium=120),
    "Kuih Lapis": dict(label="2 pieces", pcs=2, g=40,
                      p=2.2, c=40.0, f=6.0, iron=0.6, folate=6, calcium=16, vitd=0.1, b12=0, sodium=70),
    "Kuih Ketayap": dict(label="2 pieces", pcs=2, g=45,
                      p=3.2, c=34.0, f=7.5, iron=0.8, folate=9, calcium=24, vitd=0.1, b12=0.1, sodium=80),
    "Onde-Onde (5 pieces)": dict(label="5 pieces", pcs=5, g=18,
                      p=3.2, c=42.0, f=5.0, iron=0.9, folate=8, calcium=20, vitd=0, b12=0, sodium=45),
    "Kuih Cara": dict(label="3 pieces", pcs=3, g=25,
                      p=4.0, c=34.0, f=7.0, iron=0.8, folate=11, calcium=40, vitd=0.2, b12=0.2, sodium=120),
    "Kuih Kaswi": dict(label="2 pieces", pcs=2, g=40,
                      p=2.2, c=40.0, f=3.0, iron=0.6, folate=5, calcium=12, vitd=0, b12=0, sodium=70),
    "Kuih Talam": dict(label="1 piece", pcs=1, g=50,
                      p=2.4, c=38.0, f=8.0, iron=0.7, folate=8, calcium=26, vitd=0.1, b12=0, sodium=90),
    "Kuih Lopes (2 pieces)": dict(label="2 pieces", pcs=2, g=55,
                      p=1.8, c=44.0, f=3.5, iron=0.6, folate=4, calcium=14, vitd=0, b12=0, sodium=30),
    "Kuih Bingka": dict(label="1 piece", pcs=1, g=60,
                      p=4.0, c=40.0, f=9.0, iron=0.8, folate=10, calcium=50, vitd=0.2, b12=0.2, sodium=110),
    "Kuih Bahulu (5 pieces)": dict(label="5 pieces", pcs=5, g=12,
                      p=8.0, c=58.0, f=9.0, iron=1.4, folate=20, calcium=34, vitd=0.5, b12=0.5, sodium=90),
    "Dodol (2 pieces)": dict(label="2 pieces", pcs=2, g=30,
                      p=1.2, c=62.0, f=8.0, iron=0.9, folate=4, calcium=18, vitd=0, b12=0, sodium=25),
    "Wajik": dict(label="1 piece", pcs=1, g=55,
                      p=2.4, c=64.0, f=7.0, iron=0.8, folate=4, calcium=16, vitd=0, b12=0, sodium=30),
    # ── Chinese dim sum ──
    "Siew Mai (4 pieces)": dict(label="4 pieces", pcs=4, g=22,
                      p=16.0, c=14.0, f=14.0, iron=1.4, folate=12, calcium=32, vitd=0.3, b12=0.9, sodium=560),
    "Har Gow (4 pieces)": dict(label="4 pieces", pcs=4, g=20,
                      p=12.0, c=28.0, f=6.0, iron=1.2, folate=14, calcium=42, vitd=0.2, b12=0.7, sodium=520),
    "Char Siu Bao (2 pieces)": dict(label="2 pieces", pcs=2, g=70,
                      p=8.6, c=38.0, f=8.0, iron=1.4, folate=22, calcium=30, vitd=0.2, b12=0.4, sodium=380),
    "Xiao Long Bao (4 pieces)": dict(label="4 pieces", pcs=4, g=20,
                      p=14.0, c=24.0, f=13.0, iron=1.5, folate=14, calcium=28, vitd=0.3, b12=0.8, sodium=540),
    "Egg Tart (2 pieces)": dict(label="2 pieces", pcs=2, g=55,
                      p=4.5, c=28.0, f=15.0, iron=0.7, folate=16, calcium=36, vitd=0.6, b12=0.4, sodium=160),
    "Turnip Cake (3 pieces)": dict(label="3 pieces", pcs=3, g=45,
                      p=4.4, c=22.0, f=8.0, iron=0.8, folate=10, calcium=24, vitd=0.2, b12=0.3, sodium=520),
    # ── Indian breads (per piece) ──
    "Roti Canai": dict(label="1 piece", pcs=1, g=90,
                      p=7.8, c=45.0, f=12.0, iron=1.6, folate=44, calcium=22, vitd=0.1, b12=0.1, sodium=510),
    "Roti Telur": dict(label="1 piece", pcs=1, g=120,
                      p=10.0, c=40.0, f=14.0, iron=1.8, folate=46, calcium=34, vitd=0.4, b12=0.5, sodium=470),
    "Roti Tissue": dict(label="1 piece", pcs=1, g=80,
                      p=6.0, c=64.0, f=11.0, iron=1.4, folate=30, calcium=20, vitd=0.1, b12=0.1, sodium=300),
    "Roti Bom": dict(label="1 piece", pcs=1, g=100,
                      p=6.0, c=52.0, f=15.0, iron=1.4, folate=28, calcium=20, vitd=0.2, b12=0.2, sodium=320),
    "Chapati": dict(label="1 piece", pcs=1, g=50,
                      p=10.0, c=56.0, f=6.0, iron=2.8, folate=32, calcium=40, vitd=0, b12=0, sodium=360),
    "Naan": dict(label="1 piece", pcs=1, g=90,
                      p=9.0, c=50.0, f=5.5, iron=2.2, folate=42, calcium=60, vitd=0.1, b12=0.2, sodium=440),
    "Garlic Naan": dict(label="1 piece", pcs=1, g=95,
                      p=8.8, c=50.0, f=7.0, iron=2.2, folate=42, calcium=58, vitd=0.1, b12=0.2, sodium=470),
    "Butter Naan": dict(label="1 piece", pcs=1, g=95,
                      p=8.6, c=49.0, f=9.0, iron=2.2, folate=40, calcium=58, vitd=0.3, b12=0.3, sodium=470),
    "Paratha": dict(label="1 piece", pcs=1, g=80,
                      p=6.5, c=42.0, f=12.0, iron=2.0, folate=26, calcium=32, vitd=0.1, b12=0.1, sodium=400),
    "Poori (2 pieces)": dict(label="2 pieces", pcs=2, g=35,
                      p=7.0, c=46.0, f=14.0, iron=2.2, folate=28, calcium=24, vitd=0.1, b12=0.1, sodium=300),
    # ── Indian snacks/desserts ──
    "Vadai (2 pieces)": dict(label="2 pieces", pcs=2, g=40,
                      p=10.0, c=30.0, f=11.0, iron=2.6, folate=72, calcium=46, vitd=0, b12=0, sodium=420),
    "Samosa (2 pieces)": dict(label="2 pieces", pcs=2, g=50,
                      p=5.5, c=30.0, f=13.0, iron=1.5, folate=24, calcium=28, vitd=0.1, b12=0.1, sodium=400),
    "Pakora (6 pieces)": dict(label="6 pieces", pcs=6, g=20,
                      p=6.5, c=26.0, f=12.0, iron=1.8, folate=40, calcium=40, vitd=0, b12=0, sodium=420),
    "Masala Vada (2 pieces)": dict(label="2 pieces", pcs=2, g=38,
                      p=11.0, c=30.0, f=11.0, iron=2.6, folate=78, calcium=46, vitd=0, b12=0, sodium=400),
    "Bonda (3 pieces)": dict(label="3 pieces", pcs=3, g=40,
                      p=4.6, c=32.0, f=11.0, iron=1.4, folate=20, calcium=30, vitd=0.1, b12=0.1, sodium=340),
    "Gulab Jamun (2 pieces)": dict(label="2 pieces", pcs=2, g=45,
                      p=4.0, c=48.0, f=12.0, iron=0.8, folate=10, calcium=84, vitd=0.2, b12=0.3, sodium=80),
    "Rasgulla (2 pieces)": dict(label="2 pieces", pcs=2, g=60,
                      p=5.0, c=40.0, f=4.0, iron=0.5, folate=8, calcium=110, vitd=0.2, b12=0.4, sodium=50),
    "Laddu (2 pieces)": dict(label="2 pieces", pcs=2, g=40,
                      p=6.0, c=52.0, f=18.0, iron=1.6, folate=18, calcium=48, vitd=0.1, b12=0.2, sodium=70),
    "Kulfi": dict(label="1 piece", pcs=1, g=80,
                      p=6.0, c=30.0, f=15.0, iron=0.4, folate=10, calcium=200, vitd=0.5, b12=0.6, sodium=70),
    "Idli (2 pieces)": dict(label="2 pieces", pcs=2, g=45,
                      p=4.6, c=22.0, f=0.6, iron=1.2, folate=20, calcium=14, vitd=0, b12=0, sodium=200),
    "Thosai (Plain)": dict(label="1 piece", pcs=1, g=80,
                      p=5.0, c=24.0, f=3.5, iron=1.4, folate=22, calcium=16, vitd=0, b12=0, sodium=240),
    "Appam (2 pieces)": dict(label="2 pieces", pcs=2, g=50,
                      p=4.6, c=40.0, f=4.0, iron=1.1, folate=16, calcium=18, vitd=0, b12=0.1, sodium=180),
    "Putu Mayam": dict(label="2 pieces", pcs=2, g=50,
                      p=2.8, c=38.0, f=2.9, iron=1.2, folate=12, calcium=37, vitd=0, b12=0, sodium=117),
    # ── Western pieces ──
    "Pancakes (3 pieces)": dict(label="3 pieces", pcs=3, g=50,
                      p=6.0, c=48.0, f=8.0, iron=1.3, folate=26, calcium=110, vitd=0.3, b12=0.3, sodium=380),
    "Waffles (2 pieces)": dict(label="2 pieces", pcs=2, g=80,
                      p=5.0, c=36.0, f=9.4, iron=1.2, folate=22, calcium=88, vitd=0.3, b12=0.2, sodium=320),
    "French Toast (2 slices)": dict(label="2 slices", pcs=2, g=60,
                      p=10.0, c=38.0, f=13.0, iron=2.0, folate=42, calcium=116, vitd=0.7, b12=0.5, sodium=450),
    "Pizza Margherita (2 slices)": dict(label="2 slices", pcs=2, g=110,
                      p=8.6, c=26.0, f=8.0, iron=1.2, folate=27, calcium=136, vitd=0.1, b12=0.4, sodium=410),
}

# Some CSV names differ from the keys above (label is in the name). Map the
# CSV 'name' value → key. Names that already match are implicit.
NAME_TO_KEY = {
    "Margherita Pizza (2 slices)": "Pizza Margherita (2 slices)",
    "Kuih Lopes": "Kuih Lopes (2 pieces)",
    "Dodol": "Dodol (2 pieces)",
}


def atwater(p: float, c: float, f: float) -> int:
    return round(4 * p + 4 * c + 9 * f)


def main() -> int:
    rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))
    fields = rows[0].keys()
    changed = 0
    for row in rows:
        name = row["name"]
        key = NAME_TO_KEY.get(name, name)
        spec = PIECE_FOODS.get(key)
        if spec is None:
            continue
        grams = spec["pcs"] * spec["g"]
        factor = grams / 100.0
        # Macros are stored as integer grams (matches FoodItem int fields).
        # Energy uses the precise (pre-round) macros for an accurate Atwater
        # figure, then macros are rounded for display.
        p_exact = spec["p"] * factor
        c_exact = spec["c"] * factor
        f_exact = spec["f"] * factor
        row["serving"] = spec["label"]
        row["protein"] = round(p_exact)
        row["carbs"] = round(c_exact)
        row["fat"] = round(f_exact)
        row["calories"] = atwater(p_exact, c_exact, f_exact)
        row["iron_mg"] = round(spec["iron"] * factor, 1)
        row["folate_mcg"] = round(spec["folate"] * factor)
        row["calcium_mg"] = round(spec["calcium"] * factor)
        row["vitamin_d_mcg"] = round(spec["vitd"] * factor, 1)
        row["vitamin_b12_mcg"] = round(spec["b12"] * factor, 1)
        row["sodium_mg"] = round(spec["sodium"] * factor)
        changed += 1

    with CSV_PATH.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(fields))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Rewrote {changed} piece-based foods (of {len(PIECE_FOODS)} specs).")

    # Sanity-print the roti jala anchor.
    for row in rows:
        if row["name"] == "Roti Jala":
            print("Roti Jala ->", row["serving"], row["calories"], "kcal",
                  f"(P{row['protein']} C{row['carbs']} F{row['fat']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
