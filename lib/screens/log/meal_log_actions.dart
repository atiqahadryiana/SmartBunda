import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/food_image_classifier.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/screens/food/food_analysis_result_screen.dart';
import 'package:smartbunda/screens/log/meal_log_utils.dart';

class MealLogActions {
  const MealLogActions._();

  static Future<void> showAddOptions(
      BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final rootContext = context;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                strings.t('Log a meal'),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(strings.t('Manual entry')),
              subtitle:
                  Text(strings.t('Type the meal and nutrients yourself.')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                await showAddEntrySheet(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: Text(strings.t('Pick from Malaysian food DB')),
              subtitle: Text(strings.t('Search saved foods and portions.')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                await showFoodPicker(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(strings.t('Scan with camera')),
              subtitle: Text(strings
                  .t('Take a fresh photo for TensorFlow Lite detection.')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                await captureMeal(rootContext, ref, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(strings.t('Upload image')),
              subtitle: Text(
                  strings.t('Choose an existing photo from your gallery.')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                await captureMeal(rootContext, ref,
                    source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAddEntrySheet(
    BuildContext context,
    WidgetRef ref, {
    String? initialMeal,
  }) async {
    final strings = AppStrings.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final dataStore = ref.read(dataStoreProvider);
    final formKey = GlobalKey<FormState>();
    final mealCtrl = TextEditingController(text: initialMeal ?? '');
    final quantityCtrl = TextEditingController(text: '1');
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final ironCtrl = TextEditingController();
    final folateCtrl = TextEditingController();
    var mealType = defaultMealType();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: mealCtrl,
                      decoration:
                          InputDecoration(labelText: strings.t('Meal name')),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : strings.t('Required'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      items: mealOptions(strings)
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => mealType = value);
                      },
                      decoration:
                          InputDecoration(labelText: strings.t('Meal time')),
                    ),
                    TextFormField(
                      controller: quantityCtrl,
                      decoration:
                          InputDecoration(labelText: strings.t('Quantity')),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value != null && parseQuantity(value) != null
                              ? null
                              : strings.t('Number'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: caloriesCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Calories')),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value != null && int.tryParse(value) != null
                                    ? null
                                    : strings.t('Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: proteinCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Protein (g)')),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value != null && int.tryParse(value) != null
                                    ? null
                                    : strings.t('Number'),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: carbCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Carbs (g)')),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value != null && int.tryParse(value) != null
                                    ? null
                                    : strings.t('Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: fatCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Fat (g)')),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value != null && int.tryParse(value) != null
                                    ? null
                                    : strings.t('Number'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: ironCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Iron (mg)')),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: folateCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Folate (mcg)')),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final entry = FoodEntry(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            userId: user.id,
                            logId: '',
                            foodId: 'MANUAL',
                            date: DateTime.now(),
                            meal: mealCtrl.text.trim(),
                            quantity: parseQuantity(quantityCtrl.text) ?? 1,
                            unit: '',
                            calories: int.parse(caloriesCtrl.text),
                            protein: int.parse(proteinCtrl.text),
                            carbs: int.parse(carbCtrl.text),
                            fat: int.parse(fatCtrl.text),
                            ironMg: parseOptionalDouble(ironCtrl.text),
                            folateMcg: parseOptionalDouble(folateCtrl.text),
                            mealType: mealType,
                          );
                          try {
                            await dataStore.addEntry(entry);
                            ref.invalidate(entriesProvider);
                            if (!context.mounted) return;
                            Navigator.of(context).maybePop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.t('Meal saved.'))),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(strings.saveFailed('$error'))),
                            );
                          }
                        },
                        child: Text(strings.t('Save')),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showFoodPicker(
      BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final rootContext = context;
    final db = ref.read(foodDatabaseProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final dataStore = ref.read(dataStoreProvider);
    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: strings.t('Search Malaysian foods'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchCtrl.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.t('Clear'),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: db.search(searchCtrl.text),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final foods = snapshot.data!;
                      return Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            final item = foods[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.servingSize} - ${item.caloriesPerServing} kcal | P ${item.proteinG}g | C ${item.carbG}g | F ${item.fatG}g',
                                ),
                                onTap: () async {
                                  final mealType =
                                      await selectMealType(rootContext);
                                  if (mealType == null) return;
                                  if (!rootContext.mounted) return;
                                  final quantity = await promptQuantity(
                                      rootContext, strings, item);
                                  if (quantity == null) return;
                                  final entry = entryFromFood(
                                    user.id,
                                    item,
                                    mealType: mealType,
                                    quantity: quantity,
                                  );
                                  try {
                                    await dataStore.addEntry(entry);
                                    ref.invalidate(entriesProvider);
                                    if (!context.mounted) return;
                                    await Navigator.of(context).maybePop();
                                    if (rootContext.mounted) {
                                      ScaffoldMessenger.of(rootContext)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(strings.t('Meal saved.'))),
                                      );
                                    }
                                  } catch (error) {
                                    if (rootContext.mounted) {
                                      ScaffoldMessenger.of(rootContext)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                strings.saveFailed('$error'))),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> captureMeal(
    BuildContext context,
    WidgetRef ref, {
    required ImageSource source,
  }) async {
    final strings = AppStrings.of(context);
    final rootContext = context;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: source, imageQuality: 85);
    } catch (error) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.unableToAccessMedia('$error'))),
        );
      }
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.t('Could not read selected image.'))),
        );
      }
      return;
    }

    if (rootContext.mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text(strings.t('Analyzing image...'))),
      );
    }

    List<FoodImagePrediction> predictions;
    try {
      predictions = await ref
          .read(foodImageClassifierProvider)
          .classifyBytes(bytes, topK: 5);
    } catch (error) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
        final msg = error is FoodImageClassifierException
            ? error.userMessage
            : 'Image analysis failed: $error';
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!rootContext.mounted) return;
    ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();

    // Navigate to FoodAnalysisResultScreen for AI-powered nutrition lookup & save
    // The screen integrates:
    //   • Top-K prediction confidence display
    //   • MyFCD local nutrition database lookup
    //   • Portion size slider (10–1000g)
    //   • Meal type selector (breakfast/lunch/dinner/snack)
    //   • Complete nutrition facts card
    //   • Direct Firebase save via dataStore.addEntry()
    await Navigator.of(rootContext).push<bool>(
      MaterialPageRoute(
        builder: (context) => FoodAnalysisResultScreen(
          imageBytes: bytes,
          predictions: predictions,
        ),
      ),
    );
    ref.invalidate(entriesProvider);
  }
}
