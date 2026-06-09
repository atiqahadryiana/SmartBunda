import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/food_vision_shared.dart';
import 'package:smartbunda/services/image_quality_service.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/screens/food/food_analysis_result_screen.dart';
import 'package:smartbunda/screens/log/meal_log_utils.dart';
import 'package:smartbunda/widgets/portion_icon.dart';

/// User choice from the low image-quality dialog.
enum _LowQualityAction { retake, gallery, manual, continueAnyway }

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
                  .t('Take a fresh photo for AI food detection.')),
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

  /// Edit an existing meal entry (pre-filled), saving via `updateEntry`.
  static Future<void> editEntrySheet(
    BuildContext context,
    WidgetRef ref,
    FoodEntry entry,
  ) async {
    final strings = AppStrings.of(context);
    final dataStore = ref.read(dataStoreProvider);
    final formKey = GlobalKey<FormState>();
    final mealCtrl = TextEditingController(text: entry.meal);
    final quantityCtrl =
        TextEditingController(text: entry.quantity.toString());
    final caloriesCtrl = TextEditingController(text: entry.calories.toString());
    final proteinCtrl = TextEditingController(text: entry.protein.toString());
    final carbCtrl = TextEditingController(text: entry.carbs.toString());
    final fatCtrl = TextEditingController(text: entry.fat.toString());
    var mealType = entry.mealType ?? defaultMealType();
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
                    Text(strings.t('Edit meal'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
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
                          .map((option) => DropdownMenuItem(
                                value: option.value,
                                child: Text(option.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => mealType = value);
                      },
                      decoration:
                          InputDecoration(labelText: strings.t('Meal time')),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: caloriesCtrl,
                            decoration: InputDecoration(
                                labelText: strings.t('Calories')),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null
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
                            validator: (v) =>
                                v != null && int.tryParse(v) != null
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
                            validator: (v) =>
                                v != null && int.tryParse(v) != null
                                    ? null
                                    : strings.t('Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: fatCtrl,
                            decoration:
                                InputDecoration(labelText: strings.t('Fat (g)')),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null
                                    ? null
                                    : strings.t('Number'),
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
                          final updated = entry.copyWith(
                            meal: mealCtrl.text.trim(),
                            quantity:
                                parseQuantity(quantityCtrl.text) ?? entry.quantity,
                            calories: int.parse(caloriesCtrl.text),
                            protein: int.parse(proteinCtrl.text),
                            carbs: int.parse(carbCtrl.text),
                            fat: int.parse(fatCtrl.text),
                            mealType: mealType,
                          );
                          try {
                            await dataStore.updateEntry(updated);
                            ref.invalidate(entriesProvider);
                            if (!context.mounted) return;
                            Navigator.of(context).maybePop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(strings.t('Meal updated.'))),
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

  /// Delete a meal entry after a confirmation dialog.
  static Future<void> confirmDeleteEntry(
    BuildContext context,
    WidgetRef ref,
    FoodEntry entry,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('Delete meal?')),
        content: Text(strings.t('This meal log will be permanently removed.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.t('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(dataStoreProvider).deleteEntry(entry);
      ref.invalidate(entriesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('Meal deleted.'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.saveFailed('$error'))),
      );
    }
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
                            final portion = portionFromServing(item.servingSize);
                            // Only flag non-full portions with a pie icon; a
                            // full plate needs no extra hint.
                            final showPortion = portion != PlatePortion.full;
                            return Card(
                              child: ListTile(
                                leading: showPortion
                                    ? PortionIcon(portion: portion)
                                    : null,
                                title: Text(item.name),
                                subtitle: Text(
                                  '${showPortion ? '${portion.label} · ' : ''}'
                                  '${item.servingSize} - ${item.caloriesPerServing} kcal | P ${item.proteinG}g | C ${item.carbG}g | F ${item.fatG}g',
                                ),
                                onTap: () async {
                                  final mealType =
                                      await selectMealType(rootContext);
                                  if (mealType == null) return;
                                  if (!rootContext.mounted) return;
                                  final quantity = await promptPlatePortion(
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

    // ── Image Quality Assessment (before classification) ──────────────────
    final quality = await const ImageQualityService().assess(bytes);
    if (quality.isInvalid) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.t('Could not read selected image.'))),
        );
      }
      return;
    }
    if (quality.shouldBlock) {
      // Score < 50 → don't classify; let the user retake or pick manually.
      if (!rootContext.mounted) return;
      final action = await _showLowQualityDialog(rootContext, strings, quality);
      switch (action) {
        case _LowQualityAction.retake:
          if (rootContext.mounted) {
            await captureMeal(rootContext, ref, source: ImageSource.camera);
          }
          return;
        case _LowQualityAction.gallery:
          if (rootContext.mounted) {
            await captureMeal(rootContext, ref, source: ImageSource.gallery);
          }
          return;
        case _LowQualityAction.manual:
          if (rootContext.mounted) await showFoodPicker(rootContext, ref);
          return;
        case _LowQualityAction.continueAnyway:
          break; // proceed despite low quality
        case null:
          return; // dismissed
      }
    } else if (quality.shouldWarn && rootContext.mounted) {
      // Score 50–69 → warn but continue.
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(strings.t(
              'Image quality is fair — results may be less accurate.')),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (rootContext.mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text(strings.t('Analyzing image...'))),
      );
    }

    // Downscale to ~768px before upload — vision models tile to that size
    // anyway, so a smaller payload cuts upload + processing time noticeably.
    // The full-resolution `bytes` is still used for the on-screen preview.
    final scanBytes = await compressForVision(bytes);

    // Scanner chain (each tried in order until one succeeds):
    //   1. Firebase AI Logic — Gemini Developer API (primary)
    //   2. OpenRouter vision API (fallback)
    //   3. Ollama Cloud vision API (fallback)
    //   4. Manual entry (last resort)
    // The primary gets a tight timeout so a stalled call fails over to a
    // backup scanner fast instead of leaving the user waiting.
    List<FoodImagePrediction>? predictions;
    Object? firstError;
    var triedFallback = false;
    for (final scan in <Future<List<FoodImagePrediction>> Function()>[
      () => ref.read(firebaseAiVisionServiceProvider).classifyBytes(scanBytes,
          topK: 5, timeout: const Duration(seconds: 45)),
      () => ref.read(foodVisionServiceProvider).classifyBytes(scanBytes,
          topK: 5, timeout: const Duration(seconds: 45)),
      () => ref.read(ollamaVisionServiceProvider).classifyBytes(scanBytes,
          topK: 5, timeout: const Duration(seconds: 60)),
    ]) {
      try {
        predictions = await scan();
        break;
      } catch (error) {
        firstError ??= error;
        // Tell the user once that we're moving to a backup scanner.
        if (!triedFallback && rootContext.mounted) {
          triedFallback = true;
          ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text(strings.t('Trying backup scanner...'))),
          );
        }
      }
    }

    if (predictions == null) {
      // All scanners failed → offer manual entry.
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
        final msg = firstError is FoodImageClassifierException
            ? firstError.userMessage
            : 'Image analysis failed: $firstError';
        if (!rootContext.mounted) return;
        final fallback = await showDialog<bool>(
          context: rootContext,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.orange),
            title: const Text('Scanner unavailable'),
            content: Text(
              '$msg\n\nWould you like to log this meal manually instead?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Log manually'),
              ),
            ],
          ),
        );
        if (fallback == true && rootContext.mounted) {
          await showFoodPicker(rootContext, ref);
        }
      }
      return;
    }

    final resolvedPredictions = predictions;
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
          predictions: resolvedPredictions,
          quality: quality,
        ),
      ),
    );
    ref.invalidate(entriesProvider);
  }

  /// Low-quality (score < 50) dialog: offer retake / gallery / manual / continue.
  static Future<_LowQualityAction?> _showLowQualityDialog(
    BuildContext context,
    AppStrings strings,
    ImageQualityResult quality,
  ) {
    return showDialog<_LowQualityAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.image_not_supported_outlined),
        title: Text(strings.t('Image quality is low')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quality.reason ??
                  strings.t(
                      'This photo may be too blurry, dark, or low-resolution '
                      'for reliable food recognition.'),
            ),
            const SizedBox(height: 8),
            Text(
              '${strings.t('Quality score')}: ${quality.score}/100',
              style: Theme.of(dialogContext).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LowQualityAction.manual),
            child: Text(strings.t('Search manually')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LowQualityAction.gallery),
            child: Text(strings.t('Choose another')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_LowQualityAction.continueAnyway),
            child: Text(strings.t('Use anyway')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LowQualityAction.retake),
            child: Text(strings.t('Retake')),
          ),
        ],
      ),
    );
  }
}
