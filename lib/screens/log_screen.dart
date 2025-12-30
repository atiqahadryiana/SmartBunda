import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
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
                                '${entry.calories} kcal | P ${entry.protein}g | C ${entry.carbs}g | F ${entry.fat}g',
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
              title: const Text('Scan with camera (stub)'),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showPhotoStub(rootContext, ref, source: 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload image (stub)'),
              onTap: () async {
                await Navigator.of(sheetContext).maybePop();
                if (!rootContext.mounted) return;
                _showPhotoStub(rootContext, ref, source: 'gallery');
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
    final unitCtrl = TextEditingController(text: 'serving');
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final ironCtrl = TextEditingController();
    final folateCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityCtrl,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v != null && double.tryParse(v) != null ? null : 'Number',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                    ],
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
                          unit: unitCtrl.text.trim().isEmpty ? 'serving' : unitCtrl.text.trim(),
                          calories: int.parse(caloriesCtrl.text),
                          protein: int.parse(proteinCtrl.text),
                          carbs: int.parse(carbCtrl.text),
                          fat: int.parse(fatCtrl.text),
                          ironMg: double.tryParse(ironCtrl.text) ?? 0,
                          folateMcg: double.tryParse(folateCtrl.text) ?? 0,
                        );
                        await dataStore.addEntry(entry);
                        if (context.mounted) {
                          await Navigator.of(context).maybePop();
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
    );
  }

  Future<void> _showFoodPicker(BuildContext context, WidgetRef ref) async {
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
                                  final entry = _entryFromFood(user.id, f);
                                  await dataStore.addEntry(entry);
                                  if (context.mounted) {
                                    await Navigator.of(context).maybePop();
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

  Future<void> _showPhotoStub(BuildContext context, WidgetRef ref, {required String source}) async {
    final foods = await ref.read(foodDatabaseProvider).loadFoods();
    final suggestion = foods.first;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ML suggestion ($source)'),
        content: Text('We think this is "${suggestion.name}". Use it?'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.of(context).maybePop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                final entry = _entryFromFood(user.id, suggestion);
                await ref.read(dataStoreProvider).addEntry(entry);
              }
              if (context.mounted) {
                await Navigator.of(context).maybePop();
              }
            },
            child: const Text('Use it'),
          ),
        ],
      ),
    );
  }

  FoodEntry _entryFromFood(String userId, FoodItem f) {
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
    );
  }
}
