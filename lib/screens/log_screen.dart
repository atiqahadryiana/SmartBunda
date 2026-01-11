import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);

    return RequireSignIn(
      title: 'Meal log',
      showAppBar: true,
      message: 'Please sign in to log meals.',
      child: Scaffold(
        appBar: AppBar(title: const Text('Meal log')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(
                title: 'Meal log',
                subtitle: 'Log meals to keep your summary and recommendations accurate.',
                icon: Icons.restaurant_menu,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: entries.when(
                  data: (items) => items.isEmpty
                      ? EmptyState(
                          icon: Icons.restaurant_menu_outlined,
                          title: 'No meals logged yet',
                          message: 'Add your first meal to start tracking nutrition.',
                          action: FilledButton.icon(
                            onPressed: () => _showAddOptions(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Log a meal'),
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
                                  '${entry.calories} kcal | P ${entry.protein}g | C ${entry.carbs}g | F ${entry.fat}g | ${_mealTypeLabel(entry.mealType ?? _mealTypeFromDate(entry.date))}',
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
      ),
    );
  }

  Future<void> _showAddOptions(BuildContext context, WidgetRef ref) async {
    final rootContext = context;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Manual entry'),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showAddEntrySheet(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Pick from Malaysian food DB'),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showFoodPicker(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scan with camera'),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _captureMeal(rootContext, ref, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload image'),
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
                      decoration: const InputDecoration(labelText: 'Meal name'),
                      validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                    ),
                    DropdownButtonFormField<String>(
                      value: mealType,
                      items: _mealOptions
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
                      decoration: const InputDecoration(labelText: 'Meal time'),
                    ),
                    TextFormField(
                      controller: quantityCtrl,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v != null && double.tryParse(v) != null ? null : 'Number',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: caloriesCtrl,
                            decoration: const InputDecoration(labelText: 'Calories'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null ? null : 'Number',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: proteinCtrl,
                            decoration: const InputDecoration(labelText: 'Protein (g)'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null ? null : 'Number',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: carbCtrl,
                            decoration: const InputDecoration(labelText: 'Carbs (g)'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null ? null : 'Number',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: fatCtrl,
                            decoration: const InputDecoration(labelText: 'Fat (g)'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && int.tryParse(v) != null ? null : 'Number',
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
                            decoration: const InputDecoration(labelText: 'Iron (mg)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: folateCtrl,
                            decoration: const InputDecoration(labelText: 'Folate (mcg)'),
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
                              const SnackBar(content: Text('Meal saved.')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Save failed: $e')),
                            );
                          }
                        },
                        child: const Text('Save'),
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
                    decoration: const InputDecoration(
                      hintText: 'Search Malaysian foods',
                      prefixIcon: Icon(Icons.search),
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
                                        const SnackBar(content: Text('Meal saved.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (rootContext.mounted) {
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        SnackBar(content: Text('Save failed: $e')),
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
          SnackBar(content: Text('Unable to access media: $e')),
        );
      }
      return;
    }
    if (picked == null) return;
    final foods = await ref.read(foodDatabaseProvider).loadFoods();
    if (foods.isEmpty) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text('Food database is empty.')),
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
          const SnackBar(content: Text('Meal saved.')),
        );
      }
    } catch (e) {
      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
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
    final initial = _defaultMealType();
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealOptions
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

  String _mealTypeLabel(String? value) {
    final normalized = value?.trim().toLowerCase();
    final match = _mealOptions.firstWhere(
      (opt) => opt.value == normalized,
      orElse: () => const _MealOption(value: 'meal', label: 'Meal'),
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

const List<_MealOption> _mealOptions = [
  _MealOption(value: 'breakfast', label: 'Breakfast'),
  _MealOption(value: 'lunch', label: 'Lunch'),
  _MealOption(value: 'dinner', label: 'Dinner'),
  _MealOption(value: 'supper', label: 'Supper'),
];
