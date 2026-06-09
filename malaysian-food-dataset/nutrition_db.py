"""
Malaysian Food Composition Database (MyFCD) — local reference.

Source: https://myfcd.moh.gov.my/  (Malaysian Ministry of Health)
Values are per 100 g edible portion.  Portion sizes are typical serving weights.

Usage:
    from nutrition_db import lookup, FOODS
    entry = lookup("nasi lemak")          # fuzzy match
    nutrition = entry.per_portion()       # NutritionFacts at default portion size
    scaled    = entry.per_grams(150)      # scaled to custom weight
"""

from __future__ import annotations

from dataclasses import dataclass, field
from difflib import SequenceMatcher
from typing import Optional


# ── Data classes ──────────────────────────────────────────────────────────────

@dataclass
class NutritionFacts:
    energy_kcal: float
    protein_g: float
    fat_g: float
    carbs_g: float
    fibre_g: float
    sodium_mg: float
    portion_g: float = 100.0

    def __add__(self, other: "NutritionFacts") -> "NutritionFacts":
        return NutritionFacts(
            energy_kcal=self.energy_kcal + other.energy_kcal,
            protein_g=self.protein_g + other.protein_g,
            fat_g=self.fat_g + other.fat_g,
            carbs_g=self.carbs_g + other.carbs_g,
            fibre_g=self.fibre_g + other.fibre_g,
            sodium_mg=self.sodium_mg + other.sodium_mg,
            portion_g=self.portion_g + other.portion_g,
        )

    def as_dict(self) -> dict:
        return {
            "Energy (kcal)": round(self.energy_kcal, 1),
            "Protein (g)": round(self.protein_g, 1),
            "Fat (g)": round(self.fat_g, 1),
            "Carbohydrate (g)": round(self.carbs_g, 1),
            "Dietary Fibre (g)": round(self.fibre_g, 1),
            "Sodium (mg)": round(self.sodium_mg, 1),
        }


@dataclass
class FoodEntry:
    key: str
    name: str
    category: str
    aliases: list[str]
    # Per-100g values
    energy_kcal: float
    protein_g: float
    fat_g: float
    carbs_g: float
    fibre_g: float
    sodium_mg: float
    default_portion_g: float = 200.0

    def per_grams(self, grams: float) -> NutritionFacts:
        f = grams / 100.0
        return NutritionFacts(
            energy_kcal=round(self.energy_kcal * f, 1),
            protein_g=round(self.protein_g * f, 1),
            fat_g=round(self.fat_g * f, 1),
            carbs_g=round(self.carbs_g * f, 1),
            fibre_g=round(self.fibre_g * f, 1),
            sodium_mg=round(self.sodium_mg * f, 1),
            portion_g=grams,
        )

    def per_portion(self) -> NutritionFacts:
        return self.per_grams(self.default_portion_g)


# ── MyFCD Food Database ───────────────────────────────────────────────────────
# Values: energy_kcal, protein_g, fat_g, carbs_g, fibre_g, sodium_mg  (per 100g)

_RAW: list[dict] = [
    # ── Rice dishes ──────────────────────────────────────────────────────────
    dict(key="nasi_lemak", name="Nasi Lemak", category="rice",
         aliases=["nasi lemak", "coconut rice"],
         energy_kcal=175, protein_g=4.8, fat_g=9.2, carbs_g=20.1,
         fibre_g=1.4, sodium_mg=312, default_portion_g=300),

    dict(key="nasi_goreng_ayam", name="Nasi Goreng Ayam", category="rice",
         aliases=["nasi goreng ayam", "chicken fried rice"],
         energy_kcal=183, protein_g=7.2, fat_g=6.8, carbs_g=24.5,
         fibre_g=0.9, sodium_mg=520, default_portion_g=300),

    dict(key="nasi_goreng_cili_padi", name="Nasi Goreng Cili Padi", category="rice",
         aliases=["nasi goreng cili padi", "spicy fried rice"],
         energy_kcal=178, protein_g=5.6, fat_g=7.1, carbs_g=23.8,
         fibre_g=1.1, sodium_mg=580, default_portion_g=300),

    dict(key="nasi_goreng_ikan_masin", name="Nasi Goreng Ikan Masin", category="rice",
         aliases=["nasi goreng ikan masin", "salted fish fried rice"],
         energy_kcal=181, protein_g=6.3, fat_g=7.4, carbs_g=24.0,
         fibre_g=0.8, sodium_mg=650, default_portion_g=300),

    dict(key="nasi_goreng_seafood", name="Nasi Goreng Seafood", category="rice",
         aliases=["nasi goreng seafood", "seafood fried rice"],
         energy_kcal=172, protein_g=8.1, fat_g=5.9, carbs_g=23.2,
         fibre_g=0.9, sodium_mg=560, default_portion_g=300),

    dict(key="nasi_goreng_usa", name="Nasi Goreng USA", category="rice",
         aliases=["nasi goreng usa", "nasi goreng american"],
         energy_kcal=179, protein_g=7.5, fat_g=7.0, carbs_g=23.5,
         fibre_g=1.0, sodium_mg=540, default_portion_g=300),

    dict(key="nasi_ayam", name="Nasi Ayam", category="rice",
         aliases=["nasi ayam", "chicken rice", "hainanese chicken rice"],
         energy_kcal=162, protein_g=9.4, fat_g=6.1, carbs_g=18.8,
         fibre_g=0.7, sodium_mg=480, default_portion_g=350),

    dict(key="hainanese_chicken_rice", name="Hainanese Chicken Rice", category="rice",
         aliases=["hainanese chicken rice", "nasi ayam hainanese"],
         energy_kcal=160, protein_g=9.6, fat_g=5.8, carbs_g=18.5,
         fibre_g=0.6, sodium_mg=460, default_portion_g=350),

    dict(key="nasi_briyani", name="Nasi Briyani", category="rice",
         aliases=["nasi briyani", "biryani", "briyani rice"],
         energy_kcal=195, protein_g=6.8, fat_g=8.2, carbs_g=25.3,
         fibre_g=1.2, sodium_mg=390, default_portion_g=300),

    dict(key="nasi_kerabu", name="Nasi Kerabu", category="rice",
         aliases=["nasi kerabu", "blue rice kelantan"],
         energy_kcal=158, protein_g=5.2, fat_g=5.6, carbs_g=22.8,
         fibre_g=2.1, sodium_mg=340, default_portion_g=300),

    dict(key="nasi_dagang", name="Nasi Dagang", category="rice",
         aliases=["nasi dagang", "traders rice"],
         energy_kcal=185, protein_g=6.1, fat_g=7.9, carbs_g=23.8,
         fibre_g=1.3, sodium_mg=380, default_portion_g=300),

    dict(key="nasi_kukus", name="Nasi Kukus", category="rice",
         aliases=["nasi kukus", "steamed rice with chicken"],
         energy_kcal=163, protein_g=8.8, fat_g=5.9, carbs_g=19.5,
         fibre_g=0.8, sodium_mg=390, default_portion_g=300),

    dict(key="nasi_tomato", name="Nasi Tomato", category="rice",
         aliases=["nasi tomato", "tomato rice"],
         energy_kcal=172, protein_g=4.9, fat_g=6.5, carbs_g=24.8,
         fibre_g=1.0, sodium_mg=350, default_portion_g=300),

    dict(key="nasi_minyak", name="Nasi Minyak", category="rice",
         aliases=["nasi minyak", "ghee rice"],
         energy_kcal=198, protein_g=3.8, fat_g=9.1, carbs_g=25.6,
         fibre_g=0.5, sodium_mg=290, default_portion_g=250),

    dict(key="nasi_ulam", name="Nasi Ulam", category="rice",
         aliases=["nasi ulam", "herb rice"],
         energy_kcal=148, protein_g=4.5, fat_g=4.2, carbs_g=23.6,
         fibre_g=2.8, sodium_mg=210, default_portion_g=300),

    dict(key="nasi_ambeng", name="Nasi Ambeng", category="rice",
         aliases=["nasi ambeng", "javanese rice"],
         energy_kcal=189, protein_g=7.8, fat_g=8.4, carbs_g=22.1,
         fibre_g=1.5, sodium_mg=410, default_portion_g=350),

    dict(key="nasi_kebuli", name="Nasi Kebuli", category="rice",
         aliases=["nasi kebuli", "kabuli rice"],
         energy_kcal=202, protein_g=7.2, fat_g=9.8, carbs_g=24.1,
         fibre_g=1.0, sodium_mg=370, default_portion_g=300),

    dict(key="nasi_tumpang", name="Nasi Tumpang", category="rice",
         aliases=["nasi tumpang", "cone rice"],
         energy_kcal=177, protein_g=6.3, fat_g=7.1, carbs_g=22.8,
         fibre_g=1.2, sodium_mg=380, default_portion_g=250),

    dict(key="claypot_chicken_rice", name="Claypot Chicken Rice", category="rice",
         aliases=["claypot chicken rice", "nasi periuk"],
         energy_kcal=168, protein_g=9.8, fat_g=5.8, carbs_g=20.2,
         fibre_g=0.9, sodium_mg=470, default_portion_g=350),

    dict(key="ketupat", name="Ketupat", category="rice",
         aliases=["ketupat", "rice cake", "pressed rice"],
         energy_kcal=118, protein_g=2.3, fat_g=0.3, carbs_g=26.2,
         fibre_g=0.4, sodium_mg=8, default_portion_g=150),

    dict(key="lemang", name="Lemang", category="rice",
         aliases=["lemang", "bamboo sticky rice"],
         energy_kcal=198, protein_g=3.6, fat_g=9.4, carbs_g=25.8,
         fibre_g=0.8, sodium_mg=35, default_portion_g=200),

    # ── Noodles ──────────────────────────────────────────────────────────────
    dict(key="char_kuey_teow", name="Char Kuey Teow", category="noodles",
         aliases=["char kuey teow", "char kway teow", "fried flat rice noodles"],
         energy_kcal=182, protein_g=7.2, fat_g=9.1, carbs_g=19.8,
         fibre_g=1.2, sodium_mg=620, default_portion_g=300),

    dict(key="kuey_teow_goreng", name="Kuey Teow Goreng", category="noodles",
         aliases=["kuey teow goreng", "fried kway teow"],
         energy_kcal=168, protein_g=6.4, fat_g=7.8, carbs_g=19.6,
         fibre_g=1.0, sodium_mg=580, default_portion_g=300),

    dict(key="kuey_teow_sup", name="Kuey Teow Sup", category="noodles",
         aliases=["kuey teow sup", "kway teow soup"],
         energy_kcal=98, protein_g=5.8, fat_g=2.9, carbs_g=13.8,
         fibre_g=0.9, sodium_mg=720, default_portion_g=400),

    dict(key="kuey_teow_theng", name="Kuey Teow Theng", category="noodles",
         aliases=["kuey teow theng", "kway teow theng"],
         energy_kcal=95, protein_g=5.4, fat_g=2.6, carbs_g=13.4,
         fibre_g=0.8, sodium_mg=680, default_portion_g=400),

    dict(key="bihun_goreng", name="Bihun Goreng", category="noodles",
         aliases=["bihun goreng", "mihun goreng", "fried vermicelli"],
         energy_kcal=162, protein_g=5.9, fat_g=7.1, carbs_g=20.1,
         fibre_g=1.0, sodium_mg=540, default_portion_g=300),

    dict(key="bihun_sup", name="Bihun Sup", category="noodles",
         aliases=["bihun sup", "mihun sup", "vermicelli soup"],
         energy_kcal=88, protein_g=5.2, fat_g=2.4, carbs_g=12.1,
         fibre_g=0.7, sodium_mg=640, default_portion_g=400),

    dict(key="bihun_tomyam", name="Bihun Tom Yam", category="noodles",
         aliases=["bihun tomyam", "bihun tom yam", "vermicelli tom yam"],
         energy_kcal=92, protein_g=5.6, fat_g=2.8, carbs_g=12.4,
         fibre_g=1.0, sodium_mg=710, default_portion_g=400),

    dict(key="mee_goreng_mamak", name="Mee Goreng Mamak", category="noodles",
         aliases=["mee goreng mamak", "maggi goreng mamak", "mamak fried noodles"],
         energy_kcal=178, protein_g=7.8, fat_g=8.2, carbs_g=19.5,
         fibre_g=1.5, sodium_mg=680, default_portion_g=300),

    dict(key="maggi_goreng_mamak", name="Maggi Goreng Mamak", category="noodles",
         aliases=["maggi goreng mamak", "mamak maggi"],
         energy_kcal=182, protein_g=7.9, fat_g=8.6, carbs_g=20.1,
         fibre_g=1.3, sodium_mg=720, default_portion_g=300),

    dict(key="mee_hailam", name="Mee Hailam", category="noodles",
         aliases=["mee hailam", "hainanese noodles"],
         energy_kcal=125, protein_g=6.8, fat_g=3.8, carbs_g=16.2,
         fibre_g=0.9, sodium_mg=580, default_portion_g=350),

    dict(key="mee_jawa", name="Mee Jawa", category="noodles",
         aliases=["mee jawa", "javanese noodles"],
         energy_kcal=132, protein_g=6.2, fat_g=4.1, carbs_g=17.8,
         fibre_g=1.4, sodium_mg=520, default_portion_g=350),

    dict(key="mee_kari", name="Mee Kari", category="noodles",
         aliases=["mee kari", "curry mee", "curry noodles"],
         energy_kcal=148, protein_g=7.1, fat_g=6.8, carbs_g=15.9,
         fibre_g=1.2, sodium_mg=610, default_portion_g=400),

    dict(key="curry_mee", name="Curry Mee", category="noodles",
         aliases=["curry mee", "mee kari"],
         energy_kcal=148, protein_g=7.1, fat_g=6.8, carbs_g=15.9,
         fibre_g=1.2, sodium_mg=610, default_portion_g=400),

    dict(key="mee_siam", name="Mee Siam", category="noodles",
         aliases=["mee siam", "siamese noodles"],
         energy_kcal=138, protein_g=5.8, fat_g=4.9, carbs_g=18.6,
         fibre_g=1.3, sodium_mg=490, default_portion_g=350),

    dict(key="mee_soto", name="Mee Soto", category="noodles",
         aliases=["mee soto", "soto noodles"],
         energy_kcal=118, protein_g=6.4, fat_g=4.2, carbs_g=14.1,
         fibre_g=0.8, sodium_mg=650, default_portion_g=400),

    dict(key="mee_wantan", name="Mee Wantan", category="noodles",
         aliases=["mee wantan", "wonton noodles"],
         energy_kcal=126, protein_g=7.2, fat_g=4.6, carbs_g=14.8,
         fibre_g=0.7, sodium_mg=620, default_portion_g=350),

    dict(key="hokkien_mee", name="Hokkien Mee", category="noodles",
         aliases=["hokkien mee", "hokkien fried noodles"],
         energy_kcal=172, protein_g=8.4, fat_g=8.6, carbs_g=17.2,
         fibre_g=1.1, sodium_mg=660, default_portion_g=300),

    dict(key="loh_mee", name="Loh Mee", category="noodles",
         aliases=["loh mee", "braised noodles"],
         energy_kcal=142, protein_g=7.8, fat_g=5.4, carbs_g=16.2,
         fibre_g=0.9, sodium_mg=590, default_portion_g=350),

    # ── Laksa ────────────────────────────────────────────────────────────────
    dict(key="laksa_penang", name="Laksa Penang", category="noodles",
         aliases=["laksa penang", "asam laksa", "penang laksa"],
         energy_kcal=122, protein_g=6.8, fat_g=2.9, carbs_g=17.8,
         fibre_g=1.4, sodium_mg=680, default_portion_g=400),

    dict(key="laksa_johor", name="Laksa Johor", category="noodles",
         aliases=["laksa johor", "johor laksa"],
         energy_kcal=145, protein_g=8.2, fat_g=5.8, carbs_g=16.1,
         fibre_g=1.3, sodium_mg=620, default_portion_g=400),

    dict(key="laksa_kelantan", name="Laksa Kelantan", category="noodles",
         aliases=["laksa kelantan", "kelantan laksa"],
         energy_kcal=138, protein_g=7.4, fat_g=4.8, carbs_g=17.2,
         fibre_g=1.5, sodium_mg=590, default_portion_g=400),

    dict(key="laksa_sarawak", name="Laksa Sarawak", category="noodles",
         aliases=["laksa sarawak", "sarawak laksa"],
         energy_kcal=155, protein_g=8.6, fat_g=7.2, carbs_g=14.8,
         fibre_g=1.2, sodium_mg=710, default_portion_g=400),

    # ── Chicken dishes ───────────────────────────────────────────────────────
    dict(key="ayam_goreng_berempah", name="Ayam Goreng Berempah", category="chicken",
         aliases=["ayam goreng berempah", "spiced fried chicken"],
         energy_kcal=268, protein_g=24.8, fat_g=16.9, carbs_g=4.2,
         fibre_g=0.8, sodium_mg=520, default_portion_g=150),

    dict(key="ayam_goreng_kunyit", name="Ayam Goreng Kunyit", category="chicken",
         aliases=["ayam goreng kunyit", "turmeric fried chicken"],
         energy_kcal=258, protein_g=23.9, fat_g=15.8, carbs_g=3.9,
         fibre_g=0.6, sodium_mg=480, default_portion_g=150),

    dict(key="ayam_masak_kicap", name="Ayam Masak Kicap", category="chicken",
         aliases=["ayam masak kicap", "soy sauce chicken"],
         energy_kcal=176, protein_g=18.2, fat_g=9.4, carbs_g=5.1,
         fibre_g=0.7, sodium_mg=580, default_portion_g=150),

    dict(key="ayam_masak_merah", name="Ayam Masak Merah", category="chicken",
         aliases=["ayam masak merah", "red chicken curry"],
         energy_kcal=182, protein_g=17.6, fat_g=10.8, carbs_g=5.4,
         fibre_g=1.1, sodium_mg=540, default_portion_g=150),

    dict(key="ayam_penyet", name="Ayam Penyet", category="chicken",
         aliases=["ayam penyet", "smashed fried chicken"],
         energy_kcal=248, protein_g=22.6, fat_g=15.2, carbs_g=5.2,
         fibre_g=0.9, sodium_mg=610, default_portion_g=180),

    dict(key="ayam_percik", name="Ayam Percik", category="chicken",
         aliases=["ayam percik", "grilled chicken kelantan"],
         energy_kcal=192, protein_g=20.8, fat_g=10.2, carbs_g=4.8,
         fibre_g=1.0, sodium_mg=420, default_portion_g=150),

    dict(key="kari_ayam", name="Kari Ayam", category="chicken",
         aliases=["kari ayam", "chicken curry", "gulai ayam"],
         energy_kcal=148, protein_g=14.8, fat_g=8.6, carbs_g=4.2,
         fibre_g=1.4, sodium_mg=480, default_portion_g=200),

    dict(key="gulai_ayam", name="Gulai Ayam", category="chicken",
         aliases=["gulai ayam", "chicken gulai"],
         energy_kcal=148, protein_g=14.8, fat_g=8.6, carbs_g=4.2,
         fibre_g=1.4, sodium_mg=480, default_portion_g=200),

    dict(key="rendang_ayam", name="Rendang Ayam", category="chicken",
         aliases=["rendang ayam", "chicken rendang", "dry chicken curry"],
         energy_kcal=248, protein_g=22.4, fat_g=16.2, carbs_g=5.1,
         fibre_g=1.8, sodium_mg=390, default_portion_g=150),

    # ── Beef / meat dishes ───────────────────────────────────────────────────
    dict(key="rendang_daging", name="Rendang Daging", category="beef",
         aliases=["rendang daging", "beef rendang", "dry beef curry"],
         energy_kcal=268, protein_g=24.1, fat_g=17.8, carbs_g=4.9,
         fibre_g=1.9, sodium_mg=380, default_portion_g=150),

    dict(key="daging_paprik", name="Daging Paprik", category="beef",
         aliases=["daging paprik", "beef paprik", "ayam paprik"],
         energy_kcal=162, protein_g=16.8, fat_g=8.4, carbs_g=6.2,
         fibre_g=1.2, sodium_mg=510, default_portion_g=150),

    dict(key="daging_salai_masak_lemak", name="Daging Salai Masak Lemak", category="beef",
         aliases=["daging salai masak lemak", "smoked beef coconut milk"],
         energy_kcal=221, protein_g=18.6, fat_g=14.8, carbs_g=3.2,
         fibre_g=0.8, sodium_mg=350, default_portion_g=150),

    dict(key="gulai_daging", name="Gulai Daging", category="beef",
         aliases=["gulai daging", "beef gulai", "beef curry"],
         energy_kcal=162, protein_g=15.8, fat_g=9.6, carbs_g=4.1,
         fibre_g=1.2, sodium_mg=460, default_portion_g=150),

    dict(key="kari_kambing", name="Kari Kambing", category="beef",
         aliases=["kari kambing", "mutton curry"],
         energy_kcal=172, protein_g=16.4, fat_g=10.2, carbs_g=4.8,
         fibre_g=1.3, sodium_mg=490, default_portion_g=150),

    # ── Satay ─────────────────────────────────────────────────────────────────
    dict(key="satay_ayam", name="Satay Ayam", category="satay",
         aliases=["satay ayam", "chicken satay"],
         energy_kcal=178, protein_g=20.2, fat_g=8.1, carbs_g=5.8,
         fibre_g=0.9, sodium_mg=560, default_portion_g=150),

    dict(key="satay_daging", name="Satay Daging", category="satay",
         aliases=["satay daging", "beef satay"],
         energy_kcal=192, protein_g=21.4, fat_g=9.8, carbs_g=5.2,
         fibre_g=0.8, sodium_mg=540, default_portion_g=150),

    dict(key="satay_hati", name="Satay Hati", category="satay",
         aliases=["satay hati", "liver satay", "chicken liver satay"],
         energy_kcal=162, protein_g=18.8, fat_g=7.4, carbs_g=4.8,
         fibre_g=0.5, sodium_mg=480, default_portion_g=120),

    dict(key="satay_perut", name="Satay Perut", category="satay",
         aliases=["satay perut", "tripe satay"],
         energy_kcal=148, protein_g=16.2, fat_g=7.8, carbs_g=3.8,
         fibre_g=0.4, sodium_mg=520, default_portion_g=120),

    # ── Fish / seafood ───────────────────────────────────────────────────────
    dict(key="ikan_bakar", name="Ikan Bakar", category="fish",
         aliases=["ikan bakar", "grilled fish"],
         energy_kcal=142, protein_g=22.8, fat_g=5.2, carbs_g=1.4,
         fibre_g=0.4, sodium_mg=380, default_portion_g=200),

    dict(key="ikan_goreng_kunyit", name="Ikan Goreng Kunyit", category="fish",
         aliases=["ikan goreng kunyit", "turmeric fried fish"],
         energy_kcal=188, protein_g=20.4, fat_g=10.8, carbs_g=2.1,
         fibre_g=0.3, sodium_mg=420, default_portion_g=150),

    dict(key="ikan_asam_pedas", name="Ikan Asam Pedas", category="fish",
         aliases=["ikan asam pedas", "spicy sour fish"],
         energy_kcal=128, protein_g=18.6, fat_g=4.8, carbs_g=3.9,
         fibre_g=1.2, sodium_mg=480, default_portion_g=200),

    dict(key="ikan_masak_lemak", name="Ikan Masak Lemak", category="fish",
         aliases=["ikan masak lemak", "fish in coconut milk"],
         energy_kcal=168, protein_g=17.2, fat_g=10.2, carbs_g=3.1,
         fibre_g=0.9, sodium_mg=420, default_portion_g=200),

    dict(key="ikan_percik", name="Ikan Percik", category="fish",
         aliases=["ikan percik", "grilled fish with spices"],
         energy_kcal=158, protein_g=20.8, fat_g=7.1, carbs_g=3.2,
         fibre_g=0.8, sodium_mg=390, default_portion_g=200),

    dict(key="gulai_ikan", name="Gulai Ikan", category="fish",
         aliases=["gulai ikan", "fish gulai", "fish curry"],
         energy_kcal=138, protein_g=16.8, fat_g=6.9, carbs_g=3.8,
         fibre_g=1.1, sodium_mg=440, default_portion_g=200),

    dict(key="kari_ikan", name="Kari Ikan", category="fish",
         aliases=["kari ikan", "fish curry"],
         energy_kcal=140, protein_g=17.2, fat_g=7.1, carbs_g=3.6,
         fibre_g=1.2, sodium_mg=450, default_portion_g=200),

    dict(key="kari_kepala_ikan", name="Kari Kepala Ikan", category="fish",
         aliases=["kari kepala ikan", "fish head curry"],
         energy_kcal=152, protein_g=15.8, fat_g=8.4, carbs_g=4.2,
         fibre_g=1.5, sodium_mg=490, default_portion_g=250),

    dict(key="sambal_udang", name="Sambal Udang", category="seafood",
         aliases=["sambal udang", "sambal prawns", "prawn sambal"],
         energy_kcal=148, protein_g=14.2, fat_g=7.8, carbs_g=5.8,
         fibre_g=1.2, sodium_mg=520, default_portion_g=150),

    dict(key="sambal_kerang", name="Sambal Kerang", category="seafood",
         aliases=["sambal kerang", "cockle sambal", "clam sambal"],
         energy_kcal=128, protein_g=12.8, fat_g=6.2, carbs_g=5.4,
         fibre_g=0.9, sodium_mg=480, default_portion_g=150),

    dict(key="sambal_sotong", name="Sambal Sotong", category="seafood",
         aliases=["sambal sotong", "squid sambal"],
         energy_kcal=138, protein_g=14.6, fat_g=6.8, carbs_g=5.2,
         fibre_g=1.0, sodium_mg=510, default_portion_g=150),

    dict(key="rendang_kerang", name="Rendang Kerang", category="seafood",
         aliases=["rendang kerang", "cockle rendang"],
         energy_kcal=158, protein_g=13.8, fat_g=9.2, carbs_g=4.8,
         fibre_g=1.1, sodium_mg=420, default_portion_g=150),

    # ── Tofu dishes ──────────────────────────────────────────────────────────
    dict(key="tauhu_bergedil", name="Tauhu Bergedil", category="tofu",
         aliases=["tauhu bergedil", "stuffed tofu patty"],
         energy_kcal=162, protein_g=9.8, fat_g=9.4, carbs_g=10.2,
         fibre_g=1.4, sodium_mg=420, default_portion_g=150),

    dict(key="tauhu_sumbat", name="Tauhu Sumbat", category="tofu",
         aliases=["tauhu sumbat", "stuffed tofu"],
         energy_kcal=112, protein_g=7.8, fat_g=6.2, carbs_g=6.4,
         fibre_g=1.8, sodium_mg=380, default_portion_g=150),

    # ── Bread / roti ─────────────────────────────────────────────────────────
    dict(key="roti_canai", name="Roti Canai", category="bread",
         aliases=["roti canai", "roti prata", "flatbread"],
         energy_kcal=321, protein_g=7.8, fat_g=12.6, carbs_g=45.2,
         fibre_g=1.4, sodium_mg=480, default_portion_g=100),

    dict(key="capati", name="Capati", category="bread",
         aliases=["capati", "chapati", "wholemeal flatbread"],
         energy_kcal=278, protein_g=8.9, fat_g=6.2, carbs_g=46.8,
         fibre_g=4.8, sodium_mg=320, default_portion_g=100),

    dict(key="roti_naan", name="Roti Naan", category="bread",
         aliases=["roti naan", "naan"],
         energy_kcal=298, protein_g=8.6, fat_g=7.8, carbs_g=48.2,
         fibre_g=1.8, sodium_mg=480, default_portion_g=120),

    dict(key="cheese_naan", name="Cheese Naan", category="bread",
         aliases=["cheese naan", "naan cheese"],
         energy_kcal=328, protein_g=11.2, fat_g=11.4, carbs_g=45.8,
         fibre_g=1.6, sodium_mg=520, default_portion_g=130),

    dict(key="garlic_naan", name="Garlic Naan", category="bread",
         aliases=["garlic naan", "naan bawang putih"],
         energy_kcal=308, protein_g=8.9, fat_g=9.2, carbs_g=47.6,
         fibre_g=1.7, sodium_mg=490, default_portion_g=120),

    dict(key="roti_bawang", name="Roti Bawang", category="bread",
         aliases=["roti bawang", "onion roti"],
         energy_kcal=312, protein_g=7.6, fat_g=11.8, carbs_g=46.2,
         fibre_g=1.5, sodium_mg=460, default_portion_g=100),

    dict(key="roti_bom", name="Roti Bom", category="bread",
         aliases=["roti bom", "bomb roti"],
         energy_kcal=342, protein_g=7.2, fat_g=14.8, carbs_g=47.2,
         fibre_g=1.2, sodium_mg=390, default_portion_g=100),

    dict(key="roti_telur", name="Roti Telur", category="bread",
         aliases=["roti telur", "egg roti"],
         energy_kcal=298, protein_g=10.4, fat_g=12.2, carbs_g=37.8,
         fibre_g=1.1, sodium_mg=480, default_portion_g=120),

    dict(key="roti_tisu", name="Roti Tisu", category="bread",
         aliases=["roti tisu", "tissue roti", "crispy roti"],
         energy_kcal=318, protein_g=6.8, fat_g=12.8, carbs_g=46.4,
         fibre_g=0.9, sodium_mg=360, default_portion_g=80),

    dict(key="roti_sardin", name="Roti Sardin", category="bread",
         aliases=["roti sardin", "sardine roti"],
         energy_kcal=272, protein_g=10.8, fat_g=10.4, carbs_g=34.8,
         fibre_g=1.4, sodium_mg=520, default_portion_g=120),

    dict(key="roti_john", name="Roti John", category="bread",
         aliases=["roti john"],
         energy_kcal=248, protein_g=12.8, fat_g=10.2, carbs_g=26.4,
         fibre_g=1.2, sodium_mg=580, default_portion_g=150),

    dict(key="murtabak_ayam", name="Murtabak Ayam", category="bread",
         aliases=["murtabak ayam", "chicken murtabak"],
         energy_kcal=242, protein_g=12.6, fat_g=11.8, carbs_g=23.4,
         fibre_g=1.1, sodium_mg=560, default_portion_g=200),

    dict(key="murtabak_daging", name="Murtabak Daging", category="bread",
         aliases=["murtabak daging", "beef murtabak"],
         energy_kcal=252, protein_g=13.4, fat_g=12.6, carbs_g=23.8,
         fibre_g=1.0, sodium_mg=580, default_portion_g=200),

    dict(key="appam", name="Appam", category="bread",
         aliases=["appam", "apom", "rice pancake"],
         energy_kcal=198, protein_g=4.2, fat_g=4.8, carbs_g=34.8,
         fibre_g=0.9, sodium_mg=280, default_portion_g=100),

    # ── Soups ─────────────────────────────────────────────────────────────────
    dict(key="sup_ayam", name="Sup Ayam", category="soup",
         aliases=["sup ayam", "chicken soup"],
         energy_kcal=78, protein_g=8.2, fat_g=3.4, carbs_g=3.2,
         fibre_g=0.8, sodium_mg=580, default_portion_g=400),

    dict(key="sup_daging", name="Sup Daging", category="soup",
         aliases=["sup daging", "beef soup", "sup tulang"],
         energy_kcal=88, protein_g=9.4, fat_g=4.2, carbs_g=2.8,
         fibre_g=0.6, sodium_mg=620, default_portion_g=400),

    dict(key="sup_tulang", name="Sup Tulang", category="soup",
         aliases=["sup tulang", "bone soup", "bone marrow soup"],
         energy_kcal=92, protein_g=9.8, fat_g=5.1, carbs_g=2.1,
         fibre_g=0.4, sodium_mg=640, default_portion_g=400),

    # ── Kuih / desserts ──────────────────────────────────────────────────────
    dict(key="apam_balik", name="Apam Balik", category="kuih",
         aliases=["apam balik", "peanut pancake", "min jiang kueh"],
         energy_kcal=312, protein_g=7.8, fat_g=12.4, carbs_g=43.8,
         fibre_g=1.4, sodium_mg=340, default_portion_g=120),

    dict(key="kuih_bahulu", name="Kuih Bahulu", category="kuih",
         aliases=["kuih bahulu", "sponge cake kuih"],
         energy_kcal=342, protein_g=8.4, fat_g=6.2, carbs_g=62.8,
         fibre_g=0.4, sodium_mg=180, default_portion_g=100),

    dict(key="kuih_bakar_pandan", name="Kuih Bakar Pandan", category="kuih",
         aliases=["kuih bakar pandan", "baked pandan cake"],
         energy_kcal=248, protein_g=5.6, fat_g=9.8, carbs_g=36.4,
         fibre_g=0.6, sodium_mg=220, default_portion_g=100),

    dict(key="kuih_bangkit", name="Kuih Bangkit", category="kuih",
         aliases=["kuih bangkit", "tapioca cookies"],
         energy_kcal=398, protein_g=4.2, fat_g=16.8, carbs_g=58.2,
         fibre_g=0.4, sodium_mg=85, default_portion_g=50),

    dict(key="kuih_bingka_labu", name="Kuih Bingka Labu", category="kuih",
         aliases=["kuih bingka labu", "pumpkin cake"],
         energy_kcal=228, protein_g=3.8, fat_g=8.4, carbs_g=35.6,
         fibre_g=1.2, sodium_mg=180, default_portion_g=100),

    dict(key="kuih_bingka_ubi", name="Kuih Bingka Ubi", category="kuih",
         aliases=["kuih bingka ubi", "cassava cake"],
         energy_kcal=242, protein_g=2.8, fat_g=9.2, carbs_g=37.8,
         fibre_g=1.4, sodium_mg=160, default_portion_g=100),

    dict(key="kuih_cara", name="Kuih Cara", category="kuih",
         aliases=["kuih cara", "cara berlauk"],
         energy_kcal=188, protein_g=6.4, fat_g=6.8, carbs_g=26.4,
         fibre_g=0.8, sodium_mg=240, default_portion_g=100),

    dict(key="kuih_ketayap", name="Kuih Ketayap", category="kuih",
         aliases=["kuih ketayap", "pandan crepe coconut"],
         energy_kcal=212, protein_g=4.2, fat_g=7.8, carbs_g=32.8,
         fibre_g=1.6, sodium_mg=140, default_portion_g=100),

    dict(key="kuih_lapis", name="Kuih Lapis", category="kuih",
         aliases=["kuih lapis", "layer cake"],
         energy_kcal=218, protein_g=2.8, fat_g=5.4, carbs_g=40.2,
         fibre_g=0.4, sodium_mg=120, default_portion_g=100),

    dict(key="kuih_lopes", name="Kuih Lopes", category="kuih",
         aliases=["kuih lopes", "glutinous rice kuih"],
         energy_kcal=192, protein_g=2.4, fat_g=5.8, carbs_g=33.8,
         fibre_g=0.6, sodium_mg=65, default_portion_g=100),

    dict(key="kuih_nagasari", name="Kuih Nagasari", category="kuih",
         aliases=["kuih nagasari", "banana rice flour kuih"],
         energy_kcal=168, protein_g=2.6, fat_g=5.2, carbs_g=28.4,
         fibre_g=1.2, sodium_mg=85, default_portion_g=100),

    dict(key="kuih_onde_onde", name="Kuih Onde Onde", category="kuih",
         aliases=["kuih onde onde", "onde onde", "pandan balls"],
         energy_kcal=218, protein_g=2.8, fat_g=6.4, carbs_g=38.2,
         fibre_g=1.4, sodium_mg=75, default_portion_g=100),

    dict(key="kuih_puteri_ayu", name="Kuih Puteri Ayu", category="kuih",
         aliases=["kuih puteri ayu", "pandan steamed cake"],
         energy_kcal=198, protein_g=4.8, fat_g=5.6, carbs_g=32.8,
         fibre_g=0.8, sodium_mg=120, default_portion_g=100),

    dict(key="kuih_talam", name="Kuih Talam", category="kuih",
         aliases=["kuih talam", "tray kuih", "pandan coconut kuih"],
         energy_kcal=188, protein_g=2.6, fat_g=7.2, carbs_g=28.4,
         fibre_g=0.7, sodium_mg=160, default_portion_g=100),

    dict(key="kuih_tepung_pelita", name="Kuih Tepung Pelita", category="kuih",
         aliases=["kuih tepung pelita", "pandan coconut milk kuih"],
         energy_kcal=172, protein_g=2.4, fat_g=6.8, carbs_g=26.8,
         fibre_g=0.5, sodium_mg=140, default_portion_g=80),

    dict(key="kuih_badak_berendam", name="Kuih Badak Berendam", category="kuih",
         aliases=["kuih badak berendam", "floating hippo kuih"],
         energy_kcal=192, protein_g=3.2, fat_g=6.4, carbs_g=31.8,
         fibre_g=1.0, sodium_mg=95, default_portion_g=100),

    # ── Iced desserts ─────────────────────────────────────────────────────────
    dict(key="cendol", name="Cendol", category="dessert",
         aliases=["cendol", "ice cendol"],
         energy_kcal=162, protein_g=2.4, fat_g=4.8, carbs_g=28.4,
         fibre_g=0.8, sodium_mg=68, default_portion_g=350),

    dict(key="abc_dessert", name="ABC (Ais Batu Campur)", category="dessert",
         aliases=["abc dessert", "ais batu campur", "ais kacang", "shaved ice"],
         energy_kcal=148, protein_g=2.1, fat_g=2.8, carbs_g=30.2,
         fibre_g=1.2, sodium_mg=42, default_portion_g=350),

    dict(key="ais_kacang", name="Ais Kacang", category="dessert",
         aliases=["ais kacang", "abc dessert", "shaved ice"],
         energy_kcal=148, protein_g=2.1, fat_g=2.8, carbs_g=30.2,
         fibre_g=1.2, sodium_mg=42, default_portion_g=350),

    dict(key="ais_krim_malaysia", name="Ais Krim Malaysia", category="dessert",
         aliases=["ais krim malaysia", "malaysian ice cream", "potong"],
         energy_kcal=148, protein_g=3.4, fat_g=4.8, carbs_g=24.2,
         fibre_g=0.2, sodium_mg=62, default_portion_g=90),

    dict(key="cempedak_goreng", name="Cempedak Goreng", category="dessert",
         aliases=["cempedak goreng", "fried cempedak"],
         energy_kcal=218, protein_g=2.8, fat_g=8.4, carbs_g=34.2,
         fibre_g=1.8, sodium_mg=120, default_portion_g=100),

    dict(key="bubur_cha_cha", name="Bubur Cha Cha", category="dessert",
         aliases=["bubur cha cha", "sweet potato coconut milk dessert"],
         energy_kcal=152, protein_g=2.2, fat_g=5.8, carbs_g=24.8,
         fibre_g=1.6, sodium_mg=48, default_portion_g=300),

    dict(key="bubur_pulut_hitam", name="Bubur Pulut Hitam", category="dessert",
         aliases=["bubur pulut hitam", "black glutinous rice porridge"],
         energy_kcal=168, protein_g=3.2, fat_g=4.6, carbs_g=29.8,
         fibre_g=2.2, sodium_mg=42, default_portion_g=300),

    dict(key="sago_gula_melaka", name="Sago Gula Melaka", category="dessert",
         aliases=["sago gula melaka", "sago palm sugar"],
         energy_kcal=198, protein_g=1.2, fat_g=5.4, carbs_g=36.8,
         fibre_g=0.4, sodium_mg=38, default_portion_g=250),

    dict(key="pulut_kuning", name="Pulut Kuning", category="dessert",
         aliases=["pulut kuning", "yellow glutinous rice"],
         energy_kcal=208, protein_g=3.8, fat_g=5.2, carbs_g=37.4,
         fibre_g=0.6, sodium_mg=48, default_portion_g=150),

    dict(key="pulut_mangga", name="Pulut Mangga", category="dessert",
         aliases=["pulut mangga", "mango sticky rice"],
         energy_kcal=212, protein_g=3.4, fat_g=6.8, carbs_g=36.2,
         fibre_g=1.2, sodium_mg=35, default_portion_g=200),

    dict(key="putu_mayam", name="Putu Mayam", category="dessert",
         aliases=["putu mayam", "string hoppers"],
         energy_kcal=188, protein_g=4.2, fat_g=2.8, carbs_g=38.4,
         fibre_g=0.8, sodium_mg=82, default_portion_g=150),

    # ── Snacks ───────────────────────────────────────────────────────────────
    dict(key="keropok_keping", name="Keropok Keping", category="snack",
         aliases=["keropok keping", "fish crackers flat"],
         energy_kcal=428, protein_g=8.4, fat_g=4.2, carbs_g=86.4,
         fibre_g=0.8, sodium_mg=580, default_portion_g=30),

    dict(key="keropok_lekor", name="Keropok Lekor", category="snack",
         aliases=["keropok lekor", "terengganu fish sausage"],
         energy_kcal=248, protein_g=12.4, fat_g=8.8, carbs_g=31.2,
         fibre_g=0.6, sodium_mg=620, default_portion_g=100),

    dict(key="curry_puff", name="Curry Puff", category="snack",
         aliases=["curry puff", "karipap", "epok epok"],
         energy_kcal=268, protein_g=6.2, fat_g=14.8, carbs_g=29.2,
         fibre_g=1.4, sodium_mg=380, default_portion_g=80),

    dict(key="popiah_goreng", name="Popiah Goreng", category="snack",
         aliases=["popiah goreng", "fried spring roll"],
         energy_kcal=242, protein_g=7.8, fat_g=12.2, carbs_g=26.4,
         fibre_g=1.6, sodium_mg=420, default_portion_g=100),

    dict(key="cucur_udang", name="Cucur Udang", category="snack",
         aliases=["cucur udang", "prawn fritter"],
         energy_kcal=212, protein_g=7.4, fat_g=9.8, carbs_g=24.8,
         fibre_g=1.2, sodium_mg=380, default_portion_g=100),

    dict(key="burger_ramly", name="Burger Ramly", category="snack",
         aliases=["burger ramly", "ramly burger"],
         energy_kcal=298, protein_g=14.8, fat_g=14.2, carbs_g=28.4,
         fibre_g=1.2, sodium_mg=680, default_portion_g=200),

    dict(key="oblong_burger", name="Oblong Burger", category="snack",
         aliases=["oblong burger"],
         energy_kcal=282, protein_g=12.6, fat_g=12.8, carbs_g=29.8,
         fibre_g=1.0, sodium_mg=640, default_portion_g=180),

    # ── Beverages ─────────────────────────────────────────────────────────────
    dict(key="teh_tarik", name="Teh Tarik", category="beverage",
         aliases=["teh tarik", "pulled tea", "milk tea"],
         energy_kcal=72, protein_g=2.8, fat_g=2.4, carbs_g=10.2,
         fibre_g=0, sodium_mg=48, default_portion_g=250),

    dict(key="teh_ais", name="Teh Ais", category="beverage",
         aliases=["teh ais", "iced tea", "iced milk tea"],
         energy_kcal=68, protein_g=2.2, fat_g=2.1, carbs_g=9.8,
         fibre_g=0, sodium_mg=42, default_portion_g=300),

    dict(key="teh_o_ais_limau", name="Teh O Ais Limau", category="beverage",
         aliases=["teh o ais limau", "iced lemon tea"],
         energy_kcal=48, protein_g=0.4, fat_g=0.1, carbs_g=11.8,
         fibre_g=0, sodium_mg=18, default_portion_g=300),

    dict(key="kopi_ais", name="Kopi Ais", category="beverage",
         aliases=["kopi ais", "iced coffee"],
         energy_kcal=68, protein_g=1.8, fat_g=2.2, carbs_g=10.4,
         fibre_g=0, sodium_mg=38, default_portion_g=250),

    dict(key="kopi_o_ais", name="Kopi O Ais", category="beverage",
         aliases=["kopi o ais", "iced black coffee"],
         energy_kcal=28, protein_g=0.8, fat_g=0.2, carbs_g=6.2,
         fibre_g=0, sodium_mg=12, default_portion_g=250),

    dict(key="milo_dinosaur", name="Milo Dinosaur", category="beverage",
         aliases=["milo dinosaur", "milo godzilla"],
         energy_kcal=182, protein_g=5.2, fat_g=4.8, carbs_g=31.2,
         fibre_g=0.8, sodium_mg=78, default_portion_g=300),

    dict(key="sirap_ais", name="Sirap Ais", category="beverage",
         aliases=["sirap ais", "sirap bandung", "rose syrup drink"],
         energy_kcal=82, protein_g=1.2, fat_g=1.8, carbs_g=15.8,
         fibre_g=0, sodium_mg=28, default_portion_g=250),

    dict(key="limau_ais", name="Limau Ais", category="beverage",
         aliases=["limau ais", "iced lime juice"],
         energy_kcal=38, protein_g=0.4, fat_g=0.1, carbs_g=9.4,
         fibre_g=0.2, sodium_mg=8, default_portion_g=300),

    dict(key="bandung_cincau", name="Bandung Cincau", category="beverage",
         aliases=["bandung cincau", "grass jelly drink"],
         energy_kcal=72, protein_g=0.8, fat_g=1.2, carbs_g=15.4,
         fibre_g=0.4, sodium_mg=22, default_portion_g=300),

    dict(key="barley_drink", name="Barley Drink", category="beverage",
         aliases=["barley drink", "minuman barli"],
         energy_kcal=48, protein_g=0.8, fat_g=0.2, carbs_g=11.2,
         fibre_g=0.6, sodium_mg=12, default_portion_g=300),

    dict(key="air_mata_kucing", name="Air Mata Kucing", category="beverage",
         aliases=["air mata kucing", "longan drink"],
         energy_kcal=42, protein_g=0.4, fat_g=0.1, carbs_g=10.4,
         fibre_g=0.2, sodium_mg=8, default_portion_g=300),

    dict(key="tom_yam_campur", name="Tom Yam Campur", category="soup",
         aliases=["tom yam campur", "tom yam", "thai spicy soup"],
         energy_kcal=88, protein_g=8.4, fat_g=3.8, carbs_g=5.2,
         fibre_g=1.4, sodium_mg=780, default_portion_g=400),
]


# ── Build lookup structures ────────────────────────────────────────────────────

FOODS: dict[str, FoodEntry] = {}
_alias_to_key: dict[str, str] = {}

for _raw in _RAW:
    entry = FoodEntry(
        key=_raw["key"],
        name=_raw["name"],
        category=_raw["category"],
        aliases=_raw.get("aliases", []),
        energy_kcal=_raw["energy_kcal"],
        protein_g=_raw["protein_g"],
        fat_g=_raw["fat_g"],
        carbs_g=_raw["carbs_g"],
        fibre_g=_raw["fibre_g"],
        sodium_mg=_raw["sodium_mg"],
        default_portion_g=_raw.get("default_portion_g", 200.0),
    )
    FOODS[entry.key] = entry
    for alias in entry.aliases:
        _alias_to_key[alias.lower()] = entry.key
    _alias_to_key[entry.name.lower()] = entry.key


# ── Public API ────────────────────────────────────────────────────────────────

def lookup(food_name: str, threshold: float = 0.5) -> Optional[FoodEntry]:
    """Fuzzy-match food_name against the MyFCD database.

    Returns the best-matching FoodEntry, or None if similarity < threshold.
    """
    query = food_name.lower().strip()
    # 1. Exact alias match
    if query in _alias_to_key:
        return FOODS[_alias_to_key[query]]

    # 2. Fuzzy match across all aliases
    best_score = 0.0
    best_key: Optional[str] = None
    for alias, key in _alias_to_key.items():
        score = SequenceMatcher(None, query, alias).ratio()
        if score > best_score:
            best_score = score
            best_key = key

    if best_score >= threshold and best_key:
        return FOODS[best_key]
    return None


def total_nutrition(items: list[tuple[str, float]]) -> NutritionFacts:
    """Sum nutrition for a list of (food_name, portion_g) pairs."""
    result = NutritionFacts(0, 0, 0, 0, 0, 0, 0)
    for name, grams in items:
        entry = lookup(name)
        if entry:
            result = result + entry.per_grams(grams)
    return result


def all_categories() -> list[str]:
    return sorted({e.category for e in FOODS.values()})


def foods_by_category(category: str) -> list[FoodEntry]:
    return [e for e in FOODS.values() if e.category == category]
