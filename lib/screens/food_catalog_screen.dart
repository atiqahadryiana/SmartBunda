import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_catalog_entry.dart';
import '../models/food_item.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';

class FoodCatalogScreen extends ConsumerWidget {
  const FoodCatalogScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(foodCatalogProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Food database')) : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ScreenHeader(
              title: 'Food database',
              subtitle: 'Maintain the food catalog used for meal logging.',
              icon: Icons.restaurant_menu_outlined,
              action: FilledButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add custom'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: catalogAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'No foods yet',
                      message: 'Add a custom food to start building the catalog.',
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(entry.item.name),
                          subtitle: Text(
                            '${entry.item.servingSize} | ${entry.item.caloriesPerServing} kcal',
                          ),
                          leading: Icon(
                            entry.source == FoodCatalogSource.custom
                                ? Icons.edit_outlined
                                : Icons.restaurant_menu_outlined,
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              Switch(
                                value: entry.isActive,
                                onChanged: (value) => ref
                                    .read(foodDatabaseProvider)
                                    .setItemActive(entry.item.id, value),
                              ),
                              if (entry.source == FoodCatalogSource.custom)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showForm(context, ref, entry: entry);
                                    } else if (value == 'delete') {
                                      ref
                                          .read(foodDatabaseProvider)
                                          .removeCustomItem(entry.item.id);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    FoodCatalogEntry? entry,
  }) async {
    final nameCtrl = TextEditingController(text: entry?.item.name ?? '');
    final servingCtrl = TextEditingController(text: entry?.item.servingSize ?? '');
    final calorieCtrl =
        TextEditingController(text: entry?.item.caloriesPerServing.toString() ?? '');
    final proteinCtrl =
        TextEditingController(text: entry?.item.proteinG.toString() ?? '');
    final carbsCtrl =
        TextEditingController(text: entry?.item.carbG.toString() ?? '');
    final fatCtrl = TextEditingController(text: entry?.item.fatG.toString() ?? '');
    final ironCtrl =
        TextEditingController(text: entry?.item.ironMg.toString() ?? '');
    final folateCtrl =
        TextEditingController(text: entry?.item.folateMcg.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry == null ? 'Add custom food' : 'Edit custom food'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                  ),
                  TextFormField(
                    controller: servingCtrl,
                    decoration: const InputDecoration(labelText: 'Serving'),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                  ),
                  _numberField(calorieCtrl, 'Calories'),
                  _numberField(proteinCtrl, 'Protein (g)'),
                  _numberField(carbsCtrl, 'Carbs (g)'),
                  _numberField(fatCtrl, 'Fat (g)'),
                  _numberField(ironCtrl, 'Iron (mg)'),
                  _numberField(folateCtrl, 'Folate (mcg)'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final item = FoodItem(
                id: entry?.item.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                servingSize: servingCtrl.text.trim(),
                caloriesPerServing: int.tryParse(calorieCtrl.text) ?? 0,
                proteinG: int.tryParse(proteinCtrl.text) ?? 0,
                carbG: int.tryParse(carbsCtrl.text) ?? 0,
                fatG: int.tryParse(fatCtrl.text) ?? 0,
                ironMg: double.tryParse(ironCtrl.text) ?? 0,
                folateMcg: double.tryParse(folateCtrl.text) ?? 0,
              );
              if (entry == null) {
                await ref.read(foodDatabaseProvider).addCustomItem(item);
              } else {
                await ref.read(foodDatabaseProvider).updateCustomItem(item);
              }
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }
}


