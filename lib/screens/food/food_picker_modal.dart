/// SmartBunda — Food Picker Modal
///
/// Allows users to browse and select foods from the local MyFCD database.
/// Can be shown as:
///   • Fallback when AI detection has low confidence
///   • Alternative to AI when user prefers manual selection
///   • Quick-log feature from dashboard
library smartbunda.food_picker_modal;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/utils/food_nutrition_lookup.dart';

// ── Food Picker Result ────────────────────────────────────────────────────────

class FoodPickerResult {
  const FoodPickerResult({required this.food, this.quantity = 200});

  final FoodNutritionData food;
  final double quantity; // grams
}

// ── Launcher ──────────────────────────────────────────────────────────────────

/// Show the food picker modal and return selected food or null if dismissed.
Future<FoodPickerResult?> showFoodPickerModal(BuildContext context) {
  return showModalBottomSheet<FoodPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _FoodPickerSheet(),
  );
}

// ── Food Picker Sheet ─────────────────────────────────────────────────────────

class _FoodPickerSheet extends ConsumerStatefulWidget {
  const _FoodPickerSheet();

  @override
  ConsumerState<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<_FoodPickerSheet> {
  late TextEditingController _searchCtrl;
  String _selectedCategory = 'All';
  List<FoodNutritionData> _displayedFoods = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _updateDisplayedFoods();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateDisplayedFoods() {
    final allFoods = LocalNutritionLookup.all;
    final query = _searchCtrl.text.toLowerCase();

    var filtered = allFoods;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((f) => f.category == _selectedCategory.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.aliases.any((a) => a.toLowerCase().contains(query));
      }).toList();
    }

    setState(() => _displayedFoods = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ['All', ...LocalNutritionLookup.all.map((f) => f.category).toSet()]
            .map((c) => c[0].toUpperCase() + c.substring(1))
            .toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Food',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _updateDisplayedFoods(),
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
              ],
            ),
          ),

          // ── Category filter ───────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat;
                    _updateDisplayedFoods();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.darkPink
                            : const Color(0xFFF8BBD0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.darkPink.withValues(alpha: 0.196),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.secondaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF8BBD0)),

          // ── Food list ─────────────────────────────────────────────────────
          Expanded(
            child: _displayedFoods.isEmpty
                ? _EmptySearchState(
                    query: _searchCtrl.text,
                    category: _selectedCategory,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    itemCount: _displayedFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final food = _displayedFoods[index];
                      return _FoodTile(
                        food: food,
                        onSelect: (quantity) {
                          Navigator.pop(
                            context,
                            FoodPickerResult(food: food, quantity: quantity),
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

// ── Food Tile ─────────────────────────────────────────────────────────────────

class _FoodTile extends StatefulWidget {
  const _FoodTile({required this.food, required this.onSelect});

  final FoodNutritionData food;
  final ValueChanged<double> onSelect;

  @override
  State<_FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<_FoodTile> {
  late double _selectedQuantity;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = widget.food.defaultPortionG;
  }

  void _showQuantityPicker() {
    showDialog(
      context: context,
      builder: (context) => _QuantityPickerDialog(
        food: widget.food,
        initialQuantity: _selectedQuantity,
        onConfirm: (qty) {
          setState(() => _selectedQuantity = qty);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.scaleToPortionG(_selectedQuantity);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showQuantityPicker,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.food.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.food.category[0].toUpperCase() +
                                widget.food.category.substring(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${nutrition.energyKcal}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Macro bar
                Row(
                  children: [
                    _MacroBar(
                      label: 'P',
                      value: nutrition.proteinG.toStringAsFixed(0),
                      color: AppTheme.healthcareTeal,
                    ),
                    const SizedBox(width: 8),
                    _MacroBar(
                      label: 'C',
                      value: nutrition.carbsG.toStringAsFixed(0),
                      color: AppTheme.info,
                    ),
                    const SizedBox(width: 8),
                    _MacroBar(
                      label: 'F',
                      value: nutrition.fatG.toStringAsFixed(0),
                      color: AppTheme.darkPink,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedQuantity.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onSelect(_selectedQuantity),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Select'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.darkPink),
                        foregroundColor: AppTheme.darkPink,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Macro Bar ─────────────────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.627),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantity Picker Dialog ────────────────────────────────────────────────────

class _QuantityPickerDialog extends StatefulWidget {
  const _QuantityPickerDialog({
    required this.food,
    required this.initialQuantity,
    required this.onConfirm,
  });

  final FoodNutritionData food;
  final double initialQuantity;
  final ValueChanged<double> onConfirm;

  @override
  State<_QuantityPickerDialog> createState() => _QuantityPickerDialogState();
}

class _QuantityPickerDialogState extends State<_QuantityPickerDialog> {
  late double _quantity;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _ctrl = TextEditingController(
      text: widget.initialQuantity.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.scaleToPortionG(_quantity);
    return AlertDialog(
      title: Text('Adjust Portion: ${widget.food.name}'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity (grams)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed >= 10 && parsed <= 1000) {
                setState(() => _quantity = parsed);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _quantity.clamp(10.0, 1000.0),
            min: 10,
            max: 1000,
            divisions: 99,
            label: _quantity.toStringAsFixed(0),
            onChanged: (val) {
              setState(() {
                _quantity = val;
                _ctrl.text = val.toStringAsFixed(0);
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Energy', style: Theme.of(context).textTheme.bodySmall),
                    Text('${nutrition.energyKcal} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Protein', style: Theme.of(context).textTheme.bodySmall),
                    Text('${nutrition.proteinG.toStringAsFixed(1)} g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Carbs', style: Theme.of(context).textTheme.bodySmall),
                    Text('${nutrition.carbsG.toStringAsFixed(1)} g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_quantity);
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ── Empty Search State ────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query, required this.category});

  final String query;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppTheme.secondaryText.withValues(alpha: 0.706),
            ),
            const SizedBox(height: 12),
            Text(
              'No foods found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              query.isNotEmpty
                  ? 'Try a different search term'
                  : 'Try a different category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
