import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbunda/config/ai_config.dart';
import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/food_entry.dart';
import 'package:smartbunda/models/food_item.dart';
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
                            calories: int.tryParse(caloriesCtrl.text) ?? 0,
                            protein: int.tryParse(proteinCtrl.text) ?? 0,
                            carbs: int.tryParse(carbCtrl.text) ?? 0,
                            fat: int.tryParse(fatCtrl.text) ?? 0,
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
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => _FoodPickerSheet(
          ref: ref,
          rootContext: context,
          scrollController: scrollController,
          onPick: _logPickedFood,
        ),
      ),
    );
  }

  /// Saves a picked [item] at the chosen meal type + plate portion. Shared by
  /// the food-picker sheet.
  static Future<void> _logPickedFood(
    BuildContext rootContext,
    WidgetRef ref,
    FoodItem item,
  ) async {
    final strings = AppStrings.of(rootContext);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final dataStore = ref.read(dataStoreProvider);

    final mealType = await selectMealType(rootContext);
    if (mealType == null) return;
    if (!rootContext.mounted) return;
    final quantity = await promptPlatePortion(rootContext, strings, item);
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
      if (!rootContext.mounted) return;
      await Navigator.of(rootContext).maybePop();
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.t('Meal saved.'))),
        );
      }
    } catch (error) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.saveFailed('$error'))),
        );
      }
    }
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

    // ── Smart split: on-device YOLOv8n-cls FIRST ──────────────────────────────
    // The on-device classifier is instant, offline and free. When it is
    // confident (top-1 ≥ AiConfig.yoloConfidenceThreshold) we use its result
    // directly and skip the cloud entirely. When it is unsure — or the model
    // asset hasn't been shipped yet — we fall through to the Gemini chain,
    // which knows the long tail of Malaysian dishes. Any failure here is
    // swallowed so it can never block the scan.
    List<FoodImagePrediction>? predictions;
    Object? firstError;
    try {
      final yolo = ref.read(yoloFoodClassifierProvider);
      await yolo.ensureLoaded();
      if (yolo.isReady) {
        final onDevice = await yolo.classifyBytes(scanBytes, topK: 5);
        if (onDevice.isNotEmpty &&
            onDevice.first.confidence >= AiConfig.yoloConfidenceThreshold) {
          predictions = onDevice;
        }
      }
    } catch (error) {
      // On-device path is best-effort; remember the error only if nothing
      // else succeeds, then continue to the cloud chain.
      firstError ??= error;
    }

    // Scanner chain (each tried in order until one succeeds). Every stage is a
    // Gemini Flash model via Firebase AI Logic — each model has its own
    // free-tier quota, so a quota error on one stage simply retries on the next.
    // Firebase AI Logic exposes three distinct Gemini Flash vision models; the
    // chain runs all three, then retries the top two, giving FIVE attempts
    // before manual entry. Failover is silent (user isn't told which answered):
    //   1. gemini-3.5-flash       (primary)
    //   2. gemini-2.5-flash       (separate quota)
    //   3. gemini-2.5-flash-lite  (separate quota)
    //   4. gemini-3.5-flash       (retry — clears transient timeouts/blips)
    //   5. gemini-2.5-flash       (retry)
    //   6. Manual entry (last resort, if all five fail)
    // Skipped entirely when the on-device classifier above already produced a
    // confident result.
    for (final scan in (predictions != null)
        ? const <Future<List<FoodImagePrediction>> Function()>[]
        : <Future<List<FoodImagePrediction>> Function()>[
            // Tight timeouts so a slow/quota-capped model fails over fast
            // instead of leaving the user waiting on a frozen "Analyzing…".
            () => ref.read(firebaseAiVisionServiceProvider).classifyBytes(
                scanBytes,
                topK: 5,
                timeout: const Duration(seconds: 12)),
            () => ref.read(firebaseAiVisionFallbackProvider).classifyBytes(
                scanBytes,
                topK: 5,
                timeout: const Duration(seconds: 12)),
            () => ref.read(firebaseAiVisionLiteProvider).classifyBytes(
                scanBytes,
                topK: 5,
                timeout: const Duration(seconds: 12)),
            () => ref.read(firebaseAiVisionServiceProvider).classifyBytes(
                scanBytes,
                topK: 5,
                timeout: const Duration(seconds: 12)),
            () => ref.read(firebaseAiVisionFallbackProvider).classifyBytes(
                scanBytes,
                topK: 5,
                timeout: const Duration(seconds: 12)),
          ]) {
      try {
        predictions = await scan();
        break;
      } catch (error) {
        // Keep the first error for the final "all scanners failed" dialog, but
        // do NOT surface mid-chain failover to the user.
        firstError ??= error;
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

/// The searchable Malaysian-food picker shown in the "Log a meal" sheet.
///
/// A real StatefulWidget (not a StatefulBuilder) so the search controller is
/// disposed, the query is debounced (no search-per-keystroke), and loading /
/// empty states are handled properly.
class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet({
    required this.ref,
    required this.rootContext,
    required this.scrollController,
    required this.onPick,
  });

  final WidgetRef ref;
  final BuildContext rootContext;
  final ScrollController scrollController;
  final Future<void> Function(BuildContext, WidgetRef, FoodItem) onPick;

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Debounce so a fast typist triggers one search, not one per keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
    // Update the clear button immediately without waiting for the debounce.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final db = widget.ref.read(foodDatabaseProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: strings.t('Search Malaysian foods'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: strings.t('Clear'),
                      onPressed: () {
                        _searchCtrl.clear();
                        _debounce?.cancel();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: _onChanged,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder(
              future: db.search(_query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _FoodListSkeleton(controller: widget.scrollController);
                }
                final foods = snapshot.data ?? const [];
                if (foods.isEmpty) {
                  return _FoodPickerEmpty(query: _query, strings: strings);
                }
                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final item = foods[index];
                    final portion = portionFromServing(item.servingSize);
                    final showPortion = portion != PlatePortion.full;
                    return Card(
                      child: ListTile(
                        leading:
                            showPortion ? PortionIcon(portion: portion) : null,
                        title: Text(item.name),
                        subtitle: Text(
                          '${showPortion ? '${portion.label} · ' : ''}'
                          '${item.servingSize} - ${item.caloriesPerServing} kcal | P ${item.proteinG}g | C ${item.carbG}g | F ${item.fatG}g',
                        ),
                        onTap: () => widget.onPick(
                            widget.rootContext, widget.ref, item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer-free skeleton rows shown while the food search runs — reserves the
/// list layout so content doesn't jump in, instead of a bare centered spinner.
class _FoodListSkeleton extends StatelessWidget {
  const _FoodListSkeleton({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return ListView.builder(
      controller: controller,
      itemCount: 6,
      itemBuilder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(160, 14),
              const SizedBox(height: 8),
              bar(double.infinity, 11),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for the food picker: distinguishes "type to search" from
/// "nothing matched your search".
class _FoodPickerEmpty extends StatelessWidget {
  const _FoodPickerEmpty({required this.query, required this.strings});

  final String query;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final searching = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.restaurant_menu_outlined,
              size: 48,
              color: muted,
            ),
            const SizedBox(height: 12),
            Text(
              searching
                  ? strings.t('No foods match your search')
                  : strings.t('Start typing to search Malaysian foods'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted,
                  ),
            ),
            if (searching) ...[
              const SizedBox(height: 4),
              Text(
                strings.t('Try a different name, or add a custom food.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
