import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/app_strings.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Meal log'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: strings.t('Meal log'),
              subtitle: strings.t('Log meals to keep your summary and recommendations accurate.'),
              icon: Icons.restaurant_menu,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.when(
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: Icons.restaurant_menu_outlined,
                        title: strings.t('No meals logged yet'),
                        message: strings.t('Add your first meal to start tracking nutrition.'),
                        action: FilledButton.icon(
                          onPressed: () => _showAddOptions(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(strings.t('Log a meal')),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          return Card(
                            child: ListTile(
                              title: Text(entry.meal),
                              subtitle: Text(
                                '${entry.calories} kcal | P ${entry.protein}g | C ${entry.carbs}g | F ${entry.fat}g | ${_mealTypeLabel(entry.mealType ?? _mealTypeFromDate(entry.date), strings)}',
                              ),
                              trailing: Text(
                                '${entry.date.month}/${entry.date.day}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddOptions(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final rootContext = context;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(strings.t('Manual entry')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showAddEntrySheet(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: Text(strings.t('Pick from Malaysian food DB')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showFoodPicker(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(strings.t('Scan with camera')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _captureMeal(rootContext, ref, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(strings.t('Upload image')),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _captureMeal(rootContext, ref, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEntrySheet(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final dataStore = ref.read(dataStoreProvider);
    final formKey = GlobalKey<FormState>();
    final mealCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final ironCtrl = TextEditingController();
    final folateCtrl = TextEditingController();
    var mealType = _defaultMealType();
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
                      decoration: InputDecoration(labelText: strings.t('Meal name')),
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : strings.t('Required'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      items: _mealOptions(strings)
                          .map(
                            (opt) => DropdownMenuItem(
                              value: opt.value,
                              child: Text(opt.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => mealType = value);
                      },
                      decoration: InputDecoration(labelText: strings.t('Meal time')),
                    ),
                    TextFormField(
                      controller: quantityCtrl,
                      decoration: InputDecoration(labelText: strings.t('Quantity')),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v != null && double.tryParse(v) != null ? null : strings.t('Number'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: caloriesCtrl,
                            decoration: InputDecoration(labelText: strings.t('Calories')),
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
                            decoration: InputDecoration(labelText: strings.t('Protein (g)')),
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
                            decoration: InputDecoration(labelText: strings.t('Carbs (g)')),
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
                            decoration: InputDecoration(labelText: strings.t('Fat (g)')),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null
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
                            decoration: InputDecoration(labelText: strings.t('Iron (mg)')),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: folateCtrl,
                            decoration: InputDecoration(labelText: strings.t('Folate (mcg)')),
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
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            userId: user.id,
                            logId: '',
                            foodId: 'MANUAL',
                            date: DateTime.now(),
                            meal: mealCtrl.text.trim(),
                            quantity: double.parse(quantityCtrl.text),
                            unit: '',
                            calories: int.parse(caloriesCtrl.text),
                            protein: int.parse(proteinCtrl.text),
                            carbs: int.parse(carbCtrl.text),
                            fat: int.parse(fatCtrl.text),
                            ironMg: double.tryParse(ironCtrl.text) ?? 0,
                            folateMcg: double.tryParse(folateCtrl.text) ?? 0,
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
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.saveFailed('$e'))),
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

  Future<void> _showFoodPicker(BuildContext context, WidgetRef ref) async {
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
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
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
                            final f = foods[index];
                            return Card(
                              child: ListTile(
                                title: Text(f.name),
                                subtitle: Text(
                                  '${f.servingSize} - ${f.caloriesPerServing} kcal | P ${f.proteinG}g | C ${f.carbG}g | F ${f.fatG}g',
                                ),
                                onTap: () async {
                                  final mealType = await _selectMealType(rootContext);
                                  if (mealType == null) return;
                                  final entry = _entryFromFood(
                                    user.id,
                                    f,
                                    mealType: mealType,
                                  );
                                  try {
                                    await dataStore.addEntry(entry);
                                    ref.invalidate(entriesProvider);
                                    if (context.mounted) {
                                      await Navigator.of(context).maybePop();
                                    }
                                    if (rootContext.mounted) {
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        SnackBar(content: Text(strings.t('Meal saved.'))),
                                      );
                                    }
                                  } catch (e) {
                                    if (rootContext.mounted) {
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        SnackBar(content: Text(strings.saveFailed('$e'))),
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
            );
          });
        },
      ),
    );
  }

  Future<void> _captureMeal(
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
    } catch (e) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.unableToAccessMedia('$e'))),
        );
      }
      return;
    }
    if (picked == null) return;
    final foods = await ref.read(foodDatabaseProvider).loadFoods();
    if (foods.isEmpty) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.t('Food database is empty.'))),
        );
      }
      return;
    }
    final suggestion = foods.first;
    final mealType = await _selectMealType(rootContext);
    if (mealType == null) return;
    final entry = _entryFromFood(
      user.id,
      suggestion,
      mealType: mealType,
    );
    try {
      await ref.read(dataStoreProvider).addEntry(entry);
      ref.invalidate(entriesProvider);
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.t('Meal saved.'))),
        );
      }
    } catch (e) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text(strings.saveFailed('$e'))),
        );
      }
    }
  }

  FoodEntry _entryFromFood(
    String userId,
    FoodItem f, {
    required String mealType,
  }) {
    return FoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      logId: '',
      foodId: f.id,
      date: DateTime.now(),
      meal: f.name,
      quantity: 1,
      unit: f.servingSize,
      calories: f.caloriesPerServing,
      protein: f.proteinG,
      carbs: f.carbG,
      fat: f.fatG,
      ironMg: f.ironMg,
      folateMcg: f.folateMcg,
      mealType: mealType,
    );
  }

  Future<String?> _selectMealType(BuildContext context) async {
    final strings = AppStrings.of(context);
    final initial = _defaultMealType();
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealOptions(strings)
              .map(
                (opt) => ListTile(
                  title: Text(opt.label),
                  trailing: opt.value == initial
                      ? const Icon(Icons.check, color: Colors.pink)
                      : null,
                  onTap: () => Navigator.of(context).maybePop(opt.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _mealTypeLabel(String? value, AppStrings strings) {
    final normalized = value?.trim().toLowerCase();
    final match = _mealOptions(strings).firstWhere(
      (opt) => opt.value == normalized,
      orElse: () => _MealOption(value: 'meal', label: strings.t('Meal')),
    );
    return match.label;
  }

  String _defaultMealType() {
    return _mealTypeFromDate(DateTime.now());
  }

  String _mealTypeFromDate(DateTime date) {
    final hour = date.hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 20) return 'dinner';
    return 'supper';
  }
}

class _MealOption {
  const _MealOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

List<_MealOption> _mealOptions(AppStrings strings) {
  return [
    _MealOption(value: 'breakfast', label: strings.t('Breakfast')),
    _MealOption(value: 'lunch', label: strings.t('Lunch')),
    _MealOption(value: 'dinner', label: strings.t('Dinner')),
    _MealOption(value: 'supper', label: strings.t('Supper')),
  ];
}
