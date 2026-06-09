/// SmartBunda — Local Malaysian Food Composition Database (MyFCD)
///
/// Dart-side offline nutrition lookup for post-classification nutrition enrichment.
/// Source: Malaysian Ministry of Health — https://myfcd.moh.gov.my/
/// All values are per 100 g edible portion unless noted.
library smartbunda.food_nutrition_lookup;


// ── Data model ────────────────────────────────────────────────────────────────

class FoodNutritionData {
  const FoodNutritionData({
    required this.name,
    required this.category,
    required this.aliases,
    required this.energyKcalPer100g,
    required this.proteinGPer100g,
    required this.fatGPer100g,
    required this.carbsGPer100g,
    required this.fibreGPer100g,
    required this.sodiumMgPer100g,
    required this.calciumMgPer100g,
    required this.ironMgPer100g,
    this.sugarGPer100g,
    this.vitaminAUgPer100g,
    this.vitaminCMgPer100g,
    this.vitaminDUgPer100g,
    this.defaultPortionG = 200.0,
  });

  final String name;
  final String category;
  final List<String> aliases;
  final double energyKcalPer100g;
  final double proteinGPer100g;
  final double fatGPer100g;
  final double carbsGPer100g;
  final double fibreGPer100g;
  final double sodiumMgPer100g;
  final double calciumMgPer100g;
  final double ironMgPer100g;

  /// Optional micronutrients — null when not available in the local DB.
  /// Displayed as "—" in the UI and ignored by the recommendation engine.
  final double? sugarGPer100g;
  final double? vitaminAUgPer100g;
  final double? vitaminCMgPer100g;
  final double? vitaminDUgPer100g;

  final double defaultPortionG;

  /// Scale all per-100g values to a given portion size.
  FoodNutritionData scaleToPortionG(double grams) {
    final f = grams / 100.0;
    double? scale(double? v) => v == null ? null : v * f;
    return FoodNutritionData(
      name: name,
      category: category,
      aliases: aliases,
      energyKcalPer100g: (energyKcalPer100g * f),
      proteinGPer100g:   (proteinGPer100g   * f),
      fatGPer100g:       (fatGPer100g       * f),
      carbsGPer100g:     (carbsGPer100g     * f),
      fibreGPer100g:     (fibreGPer100g     * f),
      sodiumMgPer100g:   (sodiumMgPer100g   * f),
      calciumMgPer100g:  (calciumMgPer100g  * f),
      ironMgPer100g:     (ironMgPer100g     * f),
      sugarGPer100g:     scale(sugarGPer100g),
      vitaminAUgPer100g: scale(vitaminAUgPer100g),
      vitaminCMgPer100g: scale(vitaminCMgPer100g),
      vitaminDUgPer100g: scale(vitaminDUgPer100g),
      defaultPortionG: grams,
    );
  }

  int get energyKcal       => energyKcalPer100g.round();
  int get proteinG          => proteinGPer100g.round();
  int get fatG              => fatGPer100g.round();
  int get carbsG            => carbsGPer100g.round();
  double get fibreG         => fibreGPer100g;
  double get sodiumMg       => sodiumMgPer100g;
  double get calciumMg      => calciumMgPer100g;
  double get ironMg         => ironMgPer100g;
  double? get sugarG        => sugarGPer100g;
  double? get vitaminAUg    => vitaminAUgPer100g;
  double? get vitaminCMg    => vitaminCMgPer100g;
  double? get vitaminDUg    => vitaminDUgPer100g;
}

// ── Local database ────────────────────────────────────────────────────────────

const List<FoodNutritionData> _kFoods = [
  // ── Rice dishes ────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Nasi Lemak', category: 'rice',
    aliases: ['nasi lemak', 'coconut rice'],
    energyKcalPer100g: 175, proteinGPer100g: 4.8, fatGPer100g: 9.2,
    carbsGPer100g: 20.1, fibreGPer100g: 1.4, sodiumMgPer100g: 312,
    calciumMgPer100g: 28, ironMgPer100g: 1.1, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Goreng Ayam', category: 'rice',
    aliases: ['nasi goreng ayam', 'chicken fried rice', 'nasi goreng'],
    energyKcalPer100g: 183, proteinGPer100g: 7.2, fatGPer100g: 6.8,
    carbsGPer100g: 24.5, fibreGPer100g: 0.9, sodiumMgPer100g: 520,
    calciumMgPer100g: 22, ironMgPer100g: 1.0, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Goreng Seafood', category: 'rice',
    aliases: ['nasi goreng seafood', 'seafood fried rice'],
    energyKcalPer100g: 172, proteinGPer100g: 8.1, fatGPer100g: 5.9,
    carbsGPer100g: 23.2, fibreGPer100g: 0.9, sodiumMgPer100g: 560,
    calciumMgPer100g: 35, ironMgPer100g: 1.2, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Goreng Cili Padi', category: 'rice',
    aliases: ['nasi goreng cili padi', 'spicy fried rice'],
    energyKcalPer100g: 178, proteinGPer100g: 5.6, fatGPer100g: 7.1,
    carbsGPer100g: 23.8, fibreGPer100g: 1.1, sodiumMgPer100g: 580,
    calciumMgPer100g: 20, ironMgPer100g: 0.9, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Goreng Ikan Masin', category: 'rice',
    aliases: ['nasi goreng ikan masin', 'salted fish fried rice'],
    energyKcalPer100g: 181, proteinGPer100g: 6.3, fatGPer100g: 7.4,
    carbsGPer100g: 24.0, fibreGPer100g: 0.8, sodiumMgPer100g: 650,
    calciumMgPer100g: 24, ironMgPer100g: 1.0, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Hainanese Chicken Rice', category: 'rice',
    aliases: ['hainanese chicken rice', 'nasi ayam', 'claypot chicken rice'],
    energyKcalPer100g: 162, proteinGPer100g: 9.4, fatGPer100g: 6.1,
    carbsGPer100g: 18.8, fibreGPer100g: 0.7, sodiumMgPer100g: 480,
    calciumMgPer100g: 18, ironMgPer100g: 0.8, defaultPortionG: 350,
  ),
  FoodNutritionData(
    name: 'Nasi Briyani', category: 'rice',
    aliases: ['nasi briyani', 'biryani'],
    energyKcalPer100g: 195, proteinGPer100g: 6.8, fatGPer100g: 8.2,
    carbsGPer100g: 25.3, fibreGPer100g: 1.2, sodiumMgPer100g: 390,
    calciumMgPer100g: 32, ironMgPer100g: 1.3, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Kerabu', category: 'rice',
    aliases: ['nasi kerabu', 'blue rice'],
    energyKcalPer100g: 158, proteinGPer100g: 5.2, fatGPer100g: 5.6,
    carbsGPer100g: 22.8, fibreGPer100g: 2.1, sodiumMgPer100g: 340,
    calciumMgPer100g: 45, ironMgPer100g: 1.5, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Nasi Kukus', category: 'rice',
    aliases: ['nasi kukus', 'steamed rice chicken'],
    energyKcalPer100g: 163, proteinGPer100g: 8.8, fatGPer100g: 5.9,
    carbsGPer100g: 19.5, fibreGPer100g: 0.8, sodiumMgPer100g: 390,
    calciumMgPer100g: 22, ironMgPer100g: 0.9, defaultPortionG: 300,
  ),

  // ── Noodles ─────────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Char Kuey Teow', category: 'noodles',
    aliases: ['char kuey teow', 'char kway teow', 'fried flat noodles'],
    energyKcalPer100g: 182, proteinGPer100g: 7.2, fatGPer100g: 9.1,
    carbsGPer100g: 19.8, fibreGPer100g: 1.2, sodiumMgPer100g: 620,
    calciumMgPer100g: 38, ironMgPer100g: 1.8, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Mee Goreng Mamak', category: 'noodles',
    aliases: ['mee goreng mamak', 'maggi goreng mamak', 'mamak mee goreng'],
    energyKcalPer100g: 178, proteinGPer100g: 7.8, fatGPer100g: 8.2,
    carbsGPer100g: 19.5, fibreGPer100g: 1.5, sodiumMgPer100g: 680,
    calciumMgPer100g: 42, ironMgPer100g: 2.1, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Bihun Goreng', category: 'noodles',
    aliases: ['bihun goreng', 'mihun goreng', 'fried vermicelli'],
    energyKcalPer100g: 162, proteinGPer100g: 5.9, fatGPer100g: 7.1,
    carbsGPer100g: 20.1, fibreGPer100g: 1.0, sodiumMgPer100g: 540,
    calciumMgPer100g: 28, ironMgPer100g: 1.2, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Bihun Sup', category: 'noodles',
    aliases: ['bihun sup', 'vermicelli soup'],
    energyKcalPer100g: 88, proteinGPer100g: 5.2, fatGPer100g: 2.4,
    carbsGPer100g: 12.1, fibreGPer100g: 0.7, sodiumMgPer100g: 640,
    calciumMgPer100g: 25, ironMgPer100g: 0.8, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Kuey Teow Goreng', category: 'noodles',
    aliases: ['kuey teow goreng', 'fried kway teow'],
    energyKcalPer100g: 168, proteinGPer100g: 6.4, fatGPer100g: 7.8,
    carbsGPer100g: 19.6, fibreGPer100g: 1.0, sodiumMgPer100g: 580,
    calciumMgPer100g: 32, ironMgPer100g: 1.4, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Kuey Teow Sup', category: 'noodles',
    aliases: ['kuey teow sup', 'kuey teow theng'],
    energyKcalPer100g: 98, proteinGPer100g: 5.8, fatGPer100g: 2.9,
    carbsGPer100g: 13.8, fibreGPer100g: 0.9, sodiumMgPer100g: 720,
    calciumMgPer100g: 28, ironMgPer100g: 0.9, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Laksa Penang', category: 'noodles',
    aliases: ['laksa penang', 'asam laksa', 'penang laksa'],
    energyKcalPer100g: 122, proteinGPer100g: 6.8, fatGPer100g: 2.9,
    carbsGPer100g: 17.8, fibreGPer100g: 1.4, sodiumMgPer100g: 680,
    calciumMgPer100g: 55, ironMgPer100g: 1.6, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Laksa Johor', category: 'noodles',
    aliases: ['laksa johor'],
    energyKcalPer100g: 145, proteinGPer100g: 8.2, fatGPer100g: 5.8,
    carbsGPer100g: 16.1, fibreGPer100g: 1.3, sodiumMgPer100g: 620,
    calciumMgPer100g: 48, ironMgPer100g: 1.5, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Laksa Sarawak', category: 'noodles',
    aliases: ['laksa sarawak'],
    energyKcalPer100g: 155, proteinGPer100g: 8.6, fatGPer100g: 7.2,
    carbsGPer100g: 14.8, fibreGPer100g: 1.2, sodiumMgPer100g: 710,
    calciumMgPer100g: 52, ironMgPer100g: 1.7, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Mee Kari', category: 'noodles',
    aliases: ['mee kari', 'curry mee', 'curry noodles'],
    energyKcalPer100g: 148, proteinGPer100g: 7.1, fatGPer100g: 6.8,
    carbsGPer100g: 15.9, fibreGPer100g: 1.2, sodiumMgPer100g: 610,
    calciumMgPer100g: 60, ironMgPer100g: 1.4, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Hokkien Mee', category: 'noodles',
    aliases: ['hokkien mee', 'hokkien fried noodles'],
    energyKcalPer100g: 172, proteinGPer100g: 8.4, fatGPer100g: 8.6,
    carbsGPer100g: 17.2, fibreGPer100g: 1.1, sodiumMgPer100g: 660,
    calciumMgPer100g: 40, ironMgPer100g: 1.6, defaultPortionG: 300,
  ),

  // ── Chicken dishes ──────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Ayam Goreng Berempah', category: 'chicken',
    aliases: ['ayam goreng berempah', 'spiced fried chicken'],
    energyKcalPer100g: 268, proteinGPer100g: 24.8, fatGPer100g: 16.9,
    carbsGPer100g: 4.2, fibreGPer100g: 0.8, sodiumMgPer100g: 520,
    calciumMgPer100g: 18, ironMgPer100g: 1.2, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Ayam Goreng Kunyit', category: 'chicken',
    aliases: ['ayam goreng kunyit', 'turmeric fried chicken'],
    energyKcalPer100g: 258, proteinGPer100g: 23.9, fatGPer100g: 15.8,
    carbsGPer100g: 3.9, fibreGPer100g: 0.6, sodiumMgPer100g: 480,
    calciumMgPer100g: 15, ironMgPer100g: 1.1, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Ayam Masak Merah', category: 'chicken',
    aliases: ['ayam masak merah', 'red chicken curry', 'ayam masak kicap'],
    energyKcalPer100g: 182, proteinGPer100g: 17.6, fatGPer100g: 10.8,
    carbsGPer100g: 5.4, fibreGPer100g: 1.1, sodiumMgPer100g: 540,
    calciumMgPer100g: 22, ironMgPer100g: 1.4, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Ayam Penyet', category: 'chicken',
    aliases: ['ayam penyet', 'smashed fried chicken'],
    energyKcalPer100g: 248, proteinGPer100g: 22.6, fatGPer100g: 15.2,
    carbsGPer100g: 5.2, fibreGPer100g: 0.9, sodiumMgPer100g: 610,
    calciumMgPer100g: 20, ironMgPer100g: 1.3, defaultPortionG: 180,
  ),
  FoodNutritionData(
    name: 'Rendang Ayam', category: 'chicken',
    aliases: ['rendang ayam', 'chicken rendang'],
    energyKcalPer100g: 248, proteinGPer100g: 22.4, fatGPer100g: 16.2,
    carbsGPer100g: 5.1, fibreGPer100g: 1.8, sodiumMgPer100g: 390,
    calciumMgPer100g: 28, ironMgPer100g: 2.1, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Kari Ayam', category: 'chicken',
    aliases: ['kari ayam', 'chicken curry', 'gulai ayam'],
    energyKcalPer100g: 148, proteinGPer100g: 14.8, fatGPer100g: 8.6,
    carbsGPer100g: 4.2, fibreGPer100g: 1.4, sodiumMgPer100g: 480,
    calciumMgPer100g: 35, ironMgPer100g: 1.5, defaultPortionG: 200,
  ),
  FoodNutritionData(
    name: 'Ayam Percik', category: 'chicken',
    aliases: ['ayam percik', 'grilled chicken kelantan'],
    energyKcalPer100g: 192, proteinGPer100g: 20.8, fatGPer100g: 10.2,
    carbsGPer100g: 4.8, fibreGPer100g: 1.0, sodiumMgPer100g: 420,
    calciumMgPer100g: 20, ironMgPer100g: 1.2, defaultPortionG: 150,
  ),

  // ── Beef / meat ──────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Rendang Daging', category: 'beef',
    aliases: ['rendang daging', 'beef rendang'],
    energyKcalPer100g: 268, proteinGPer100g: 24.1, fatGPer100g: 17.8,
    carbsGPer100g: 4.9, fibreGPer100g: 1.9, sodiumMgPer100g: 380,
    calciumMgPer100g: 25, ironMgPer100g: 3.2, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Daging Paprik', category: 'beef',
    aliases: ['daging paprik', 'beef paprik', 'ayam paprik'],
    energyKcalPer100g: 162, proteinGPer100g: 16.8, fatGPer100g: 8.4,
    carbsGPer100g: 6.2, fibreGPer100g: 1.2, sodiumMgPer100g: 510,
    calciumMgPer100g: 30, ironMgPer100g: 2.4, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Kari Kambing', category: 'beef',
    aliases: ['kari kambing', 'mutton curry'],
    energyKcalPer100g: 172, proteinGPer100g: 16.4, fatGPer100g: 10.2,
    carbsGPer100g: 4.8, fibreGPer100g: 1.3, sodiumMgPer100g: 490,
    calciumMgPer100g: 28, ironMgPer100g: 2.8, defaultPortionG: 150,
  ),

  // ── Satay ────────────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Satay Ayam', category: 'satay',
    aliases: ['satay ayam', 'chicken satay', 'satay'],
    energyKcalPer100g: 178, proteinGPer100g: 20.2, fatGPer100g: 8.1,
    carbsGPer100g: 5.8, fibreGPer100g: 0.9, sodiumMgPer100g: 560,
    calciumMgPer100g: 15, ironMgPer100g: 1.4, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Satay Daging', category: 'satay',
    aliases: ['satay daging', 'beef satay'],
    energyKcalPer100g: 192, proteinGPer100g: 21.4, fatGPer100g: 9.8,
    carbsGPer100g: 5.2, fibreGPer100g: 0.8, sodiumMgPer100g: 540,
    calciumMgPer100g: 12, ironMgPer100g: 2.2, defaultPortionG: 150,
  ),

  // ── Fish / seafood ───────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Ikan Bakar', category: 'fish',
    aliases: ['ikan bakar', 'grilled fish'],
    energyKcalPer100g: 142, proteinGPer100g: 22.8, fatGPer100g: 5.2,
    carbsGPer100g: 1.4, fibreGPer100g: 0.4, sodiumMgPer100g: 380,
    calciumMgPer100g: 42, ironMgPer100g: 0.8, defaultPortionG: 200,
  ),
  FoodNutritionData(
    name: 'Ikan Goreng Kunyit', category: 'fish',
    aliases: ['ikan goreng kunyit', 'turmeric fried fish', 'ikan goreng'],
    energyKcalPer100g: 188, proteinGPer100g: 20.4, fatGPer100g: 10.8,
    carbsGPer100g: 2.1, fibreGPer100g: 0.3, sodiumMgPer100g: 420,
    calciumMgPer100g: 38, ironMgPer100g: 0.9, defaultPortionG: 150,
  ),
  FoodNutritionData(
    name: 'Ikan Asam Pedas', category: 'fish',
    aliases: ['ikan asam pedas', 'sour spicy fish'],
    energyKcalPer100g: 128, proteinGPer100g: 18.6, fatGPer100g: 4.8,
    carbsGPer100g: 3.9, fibreGPer100g: 1.2, sodiumMgPer100g: 480,
    calciumMgPer100g: 55, ironMgPer100g: 1.0, defaultPortionG: 200,
  ),
  FoodNutritionData(
    name: 'Kari Ikan', category: 'fish',
    aliases: ['kari ikan', 'fish curry', 'kari kepala ikan', 'gulai ikan'],
    energyKcalPer100g: 140, proteinGPer100g: 17.2, fatGPer100g: 7.1,
    carbsGPer100g: 3.6, fibreGPer100g: 1.2, sodiumMgPer100g: 450,
    calciumMgPer100g: 62, ironMgPer100g: 1.2, defaultPortionG: 200,
  ),
  FoodNutritionData(
    name: 'Sambal Udang', category: 'seafood',
    aliases: ['sambal udang', 'prawn sambal', 'sambal sotong'],
    energyKcalPer100g: 148, proteinGPer100g: 14.2, fatGPer100g: 7.8,
    carbsGPer100g: 5.8, fibreGPer100g: 1.2, sodiumMgPer100g: 520,
    calciumMgPer100g: 68, ironMgPer100g: 1.8, defaultPortionG: 150,
  ),

  // ── Bread / roti ─────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Roti Canai', category: 'bread',
    aliases: ['roti canai', 'roti prata', 'flatbread', 'capati'],
    energyKcalPer100g: 321, proteinGPer100g: 7.8, fatGPer100g: 12.6,
    carbsGPer100g: 45.2, fibreGPer100g: 1.4, sodiumMgPer100g: 480,
    calciumMgPer100g: 45, ironMgPer100g: 2.1, defaultPortionG: 100,
  ),
  FoodNutritionData(
    name: 'Roti Naan', category: 'bread',
    aliases: ['roti naan', 'naan', 'garlic naan', 'cheese naan'],
    energyKcalPer100g: 298, proteinGPer100g: 8.6, fatGPer100g: 7.8,
    carbsGPer100g: 48.2, fibreGPer100g: 1.8, sodiumMgPer100g: 480,
    calciumMgPer100g: 38, ironMgPer100g: 1.9, defaultPortionG: 120,
  ),
  FoodNutritionData(
    name: 'Murtabak', category: 'bread',
    aliases: ['murtabak ayam', 'murtabak daging', 'murtabak'],
    energyKcalPer100g: 248, proteinGPer100g: 13.0, fatGPer100g: 12.2,
    carbsGPer100g: 23.6, fibreGPer100g: 1.1, sodiumMgPer100g: 570,
    calciumMgPer100g: 42, ironMgPer100g: 2.0, defaultPortionG: 200,
  ),
  FoodNutritionData(
    name: 'Apam Balik', category: 'bread',
    aliases: ['apam balik', 'peanut pancake'],
    energyKcalPer100g: 312, proteinGPer100g: 7.8, fatGPer100g: 12.4,
    carbsGPer100g: 43.8, fibreGPer100g: 1.4, sodiumMgPer100g: 340,
    calciumMgPer100g: 35, ironMgPer100g: 1.6, defaultPortionG: 120,
  ),

  // ── Soups ────────────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Sup Ayam', category: 'soup',
    aliases: ['sup ayam', 'chicken soup'],
    energyKcalPer100g: 78, proteinGPer100g: 8.2, fatGPer100g: 3.4,
    carbsGPer100g: 3.2, fibreGPer100g: 0.8, sodiumMgPer100g: 580,
    calciumMgPer100g: 18, ironMgPer100g: 0.5, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Sup Tulang', category: 'soup',
    aliases: ['sup tulang', 'bone soup', 'sup daging'],
    energyKcalPer100g: 92, proteinGPer100g: 9.8, fatGPer100g: 5.1,
    carbsGPer100g: 2.1, fibreGPer100g: 0.4, sodiumMgPer100g: 640,
    calciumMgPer100g: 35, ironMgPer100g: 0.9, defaultPortionG: 400,
  ),
  FoodNutritionData(
    name: 'Tom Yam', category: 'soup',
    aliases: ['tom yam campur', 'tom yam', 'thai spicy soup'],
    energyKcalPer100g: 88, proteinGPer100g: 8.4, fatGPer100g: 3.8,
    carbsGPer100g: 5.2, fibreGPer100g: 1.4, sodiumMgPer100g: 780,
    calciumMgPer100g: 42, ironMgPer100g: 0.7, defaultPortionG: 400,
  ),

  // ── Kuih / desserts ──────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Cendol', category: 'dessert',
    aliases: ['cendol', 'ice cendol'],
    energyKcalPer100g: 162, proteinGPer100g: 2.4, fatGPer100g: 4.8,
    carbsGPer100g: 28.4, fibreGPer100g: 0.8, sodiumMgPer100g: 68,
    calciumMgPer100g: 82, ironMgPer100g: 0.4, defaultPortionG: 350,
  ),
  FoodNutritionData(
    name: 'ABC Dessert', category: 'dessert',
    aliases: ['abc dessert', 'ais batu campur', 'ais kacang', 'shaved ice'],
    energyKcalPer100g: 148, proteinGPer100g: 2.1, fatGPer100g: 2.8,
    carbsGPer100g: 30.2, fibreGPer100g: 1.2, sodiumMgPer100g: 42,
    calciumMgPer100g: 65, ironMgPer100g: 0.3, defaultPortionG: 350,
  ),
  FoodNutritionData(
    name: 'Kuih Onde Onde', category: 'kuih',
    aliases: ['kuih onde onde', 'onde onde', 'pandan balls'],
    energyKcalPer100g: 218, proteinGPer100g: 2.8, fatGPer100g: 6.4,
    carbsGPer100g: 38.2, fibreGPer100g: 1.4, sodiumMgPer100g: 75,
    calciumMgPer100g: 28, ironMgPer100g: 0.6, defaultPortionG: 100,
  ),
  FoodNutritionData(
    name: 'Bubur Pulut Hitam', category: 'dessert',
    aliases: ['bubur pulut hitam', 'black glutinous rice', 'bubur cha cha'],
    energyKcalPer100g: 168, proteinGPer100g: 3.2, fatGPer100g: 4.6,
    carbsGPer100g: 29.8, fibreGPer100g: 2.2, sodiumMgPer100g: 42,
    calciumMgPer100g: 55, ironMgPer100g: 0.8, defaultPortionG: 300,
  ),

  // ── Snacks ───────────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Keropok Lekor', category: 'snack',
    aliases: ['keropok lekor', 'fish sausage', 'keropok keping'],
    energyKcalPer100g: 248, proteinGPer100g: 12.4, fatGPer100g: 8.8,
    carbsGPer100g: 31.2, fibreGPer100g: 0.6, sodiumMgPer100g: 620,
    calciumMgPer100g: 38, ironMgPer100g: 0.9, defaultPortionG: 100,
  ),
  FoodNutritionData(
    name: 'Curry Puff', category: 'snack',
    aliases: ['curry puff', 'karipap', 'epok epok'],
    energyKcalPer100g: 268, proteinGPer100g: 6.2, fatGPer100g: 14.8,
    carbsGPer100g: 29.2, fibreGPer100g: 1.4, sodiumMgPer100g: 380,
    calciumMgPer100g: 22, ironMgPer100g: 1.2, defaultPortionG: 80,
  ),
  FoodNutritionData(
    name: 'Burger Ramly', category: 'snack',
    aliases: ['burger ramly', 'ramly burger', 'oblong burger'],
    energyKcalPer100g: 298, proteinGPer100g: 14.8, fatGPer100g: 14.2,
    carbsGPer100g: 28.4, fibreGPer100g: 1.2, sodiumMgPer100g: 680,
    calciumMgPer100g: 42, ironMgPer100g: 1.8, defaultPortionG: 200,
  ),

  // ── Beverages ─────────────────────────────────────────────────────────────────
  FoodNutritionData(
    name: 'Teh Tarik', category: 'beverage',
    aliases: ['teh tarik', 'pulled tea', 'teh ais', 'milk tea'],
    energyKcalPer100g: 72, proteinGPer100g: 2.8, fatGPer100g: 2.4,
    carbsGPer100g: 10.2, fibreGPer100g: 0, sodiumMgPer100g: 48,
    calciumMgPer100g: 95, ironMgPer100g: 0.1, defaultPortionG: 250,
  ),
  FoodNutritionData(
    name: 'Milo Dinosaur', category: 'beverage',
    aliases: ['milo dinosaur', 'milo', 'milo ais'],
    energyKcalPer100g: 182, proteinGPer100g: 5.2, fatGPer100g: 4.8,
    carbsGPer100g: 31.2, fibreGPer100g: 0.8, sodiumMgPer100g: 78,
    calciumMgPer100g: 145, ironMgPer100g: 5.8, defaultPortionG: 300,
  ),
  FoodNutritionData(
    name: 'Kopi Ais', category: 'beverage',
    aliases: ['kopi ais', 'iced coffee', 'kopi o ais'],
    energyKcalPer100g: 68, proteinGPer100g: 1.8, fatGPer100g: 2.2,
    carbsGPer100g: 10.4, fibreGPer100g: 0, sodiumMgPer100g: 38,
    calciumMgPer100g: 72, ironMgPer100g: 0.1, defaultPortionG: 250,
  ),
];

// ── Lookup index ──────────────────────────────────────────────────────────────

final Map<String, FoodNutritionData> _kIndex = () {
  final map = <String, FoodNutritionData>{};
  for (final food in _kFoods) {
    map[food.name.toLowerCase()] = food;
    for (final alias in food.aliases) {
      map[alias.toLowerCase()] = food;
    }
  }
  return map;
}();

// ── Public API ────────────────────────────────────────────────────────────────

class LocalNutritionLookup {
  const LocalNutritionLookup._();

  /// Fuzzy-match [foodLabel] against the local MyFCD database.
  ///
  /// Returns `null` if no match exceeds [threshold] (0.0–1.0).
  static FoodNutritionData? lookup(
    String foodLabel, {
    double threshold = 0.45,
  }) {
    final query = foodLabel.toLowerCase().trim();

    // 1. Exact match first
    if (_kIndex.containsKey(query)) return _kIndex[query];

    // 2. Substring match (handles "nasi goreng" matching "nasi goreng ayam")
    for (final entry in _kIndex.entries) {
      if (query.contains(entry.key) || entry.key.contains(query)) {
        return entry.value;
      }
    }

    // 3. Fuzzy similarity via bigram overlap
    double bestScore = 0.0;
    FoodNutritionData? best;
    for (final entry in _kIndex.entries) {
      final score = _bigramSimilarity(query, entry.key);
      if (score > bestScore) {
        bestScore = score;
        best = entry.value;
      }
    }
    return bestScore >= threshold ? best : null;
  }

  /// Return all available food entries for browsing.
  static List<FoodNutritionData> get all => _kFoods;

  /// Return foods filtered by category.
  static List<FoodNutritionData> byCategory(String category) =>
      _kFoods.where((f) => f.category == category).toList();
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Dice coefficient over character bigrams — range [0.0, 1.0].
double _bigramSimilarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.length < 2 || b.length < 2) {
    return a == b ? 1.0 : 0.0;
  }
  final bigramsA = _bigrams(a);
  final bigramsB = _bigrams(b);
  var intersection = 0;
  final bCopy = List<String>.from(bigramsB);
  for (final bg in bigramsA) {
    final idx = bCopy.indexOf(bg);
    if (idx >= 0) {
      intersection++;
      bCopy.removeAt(idx);
    }
  }
  return (2.0 * intersection) / (bigramsA.length + bigramsB.length);
}

List<String> _bigrams(String s) {
  final result = <String>[];
  for (var i = 0; i < s.length - 1; i++) {
    result.add(s.substring(i, i + 2));
  }
  return result;
}
