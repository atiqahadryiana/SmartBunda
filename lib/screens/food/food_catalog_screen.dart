import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/models/food_catalog_entry.dart';
import 'package:smartbunda/models/food_item.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class FoodCatalogScreen extends ConsumerWidget {
  const FoodCatalogScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(foodCatalogProvider);

    return RequireSignIn(
      title: 'Food database',
      showAppBar: showAppBar,
      message: 'Please sign in to manage the food catalog.',
      child: Scaffold(
        appBar: showAppBar ? AppBar(title: const Text('Food database')) : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ScreenHeader(
                title: 'Food database',
                subtitle: 'Maintain the food catalog used for meal logging.',
                icon: Icons.restaurant_menu_outlined,
                action: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showForm(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add custom'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _importExcel(context, ref),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Excel'),
                    ),
                  ],
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
                          key: ValueKey(entry.item.id),
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
                                  onChanged: (value) async {
                                    await _runCatalogAction(context, () async {
                                      await ref
                                          .read(foodDatabaseProvider)
                                          .setItemActive(entry.item.id, value);
                                      await ref.read(foodDatabaseProvider).refresh();
                                    });
                                  },
                                ),
                                if (entry.source == FoodCatalogSource.custom)
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _showForm(context, ref, entry: entry);
                                      } else if (value == 'delete') {
                                        await _runCatalogAction(context, () async {
                                          await ref
                                              .read(foodDatabaseProvider)
                                              .removeCustomItem(entry.item.id);
                                          await ref.read(foodDatabaseProvider).refresh();
                                        });
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
      ),
    );
  }

  static const Map<String, int> _fallbackColumnIndex = {
    'name': 0,
    'serving': 1,
    'calories': 2,
    'protein': 3,
    'carbs': 4,
    'fat': 5,
    'iron': 6,
    'folate': 7,
  };

  static const Map<String, String> _headerAliases = {
    'id': 'id',
    'foodid': 'id',
    'name': 'name',
    'food': 'name',
    'foodname': 'name',
    'item': 'name',
    'serving': 'serving',
    'servingsize': 'serving',
    'portionsize': 'serving',
    'portion': 'serving',
    'size': 'serving',
    'calorie': 'calories',
    'calories': 'calories',
    'kcal': 'calories',
    'energy': 'calories',
    'caloriesperserving': 'calories',
    'protein': 'protein',
    'proteing': 'protein',
    'carb': 'carbs',
    'carbs': 'carbs',
    'carbg': 'carbs',
    'carbohydrate': 'carbs',
    'carbohydrates': 'carbs',
    'fat': 'fat',
    'fatg': 'fat',
    'iron': 'iron',
    'ironmg': 'iron',
    'folate': 'folate',
    'folatemcg': 'folate',
  };

  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
      withReadStream: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = await _readFileBytes(result.files.single);
    if (bytes == null) {
      if (context.mounted) {
        _showSnack(context, 'Unable to read the selected file.');
      }
      return;
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Importing foods...')),
    );

    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        throw const FormatException('No sheets found in file.');
      }
      final sheet = excel.tables.values.first;
      if (sheet.rows.isEmpty) {
        throw const FormatException('No rows found in file.');
      }

      final rows = sheet.rows;
      final headerMap = _buildHeaderMap(rows.first);
      final useHeader = headerMap.containsKey('name');
      final startRow = useHeader ? 1 : 0;

      final items = <FoodItem>[];
      var skipped = 0;
      final baseId = DateTime.now().microsecondsSinceEpoch;

      for (var i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (_isRowEmpty(row)) continue;

        final name = _cellString(_cellAt(row, _columnIndex('name', useHeader, headerMap)));
        if (name.isEmpty) {
          skipped += 1;
          continue;
        }

        final serving =
            _cellString(_cellAt(row, _columnIndex('serving', useHeader, headerMap)));
        final idFromFile =
            _cellString(_cellAt(row, _columnIndex('id', useHeader, headerMap)));

        final item = FoodItem(
          id: idFromFile.isNotEmpty ? idFromFile : (baseId + items.length).toString(),
          name: name,
          servingSize: serving,
          caloriesPerServing:
              _intFromCell(_cellAt(row, _columnIndex('calories', useHeader, headerMap))),
          proteinG:
              _intFromCell(_cellAt(row, _columnIndex('protein', useHeader, headerMap))),
          carbG: _intFromCell(_cellAt(row, _columnIndex('carbs', useHeader, headerMap))),
          fatG: _intFromCell(_cellAt(row, _columnIndex('fat', useHeader, headerMap))),
          ironMg:
              _doubleFromCell(_cellAt(row, _columnIndex('iron', useHeader, headerMap))),
          folateMcg:
              _doubleFromCell(_cellAt(row, _columnIndex('folate', useHeader, headerMap))),
        );
        items.add(item);
      }

      if (items.isEmpty) {
        throw const FormatException('No valid rows found to import.');
      }

      await ref.read(foodDatabaseProvider).addCustomItems(items);
      await ref.read(foodDatabaseProvider).refresh();

      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      final note = skipped > 0 ? ' Skipped $skipped rows.' : '';
      messenger.showSnackBar(
        SnackBar(content: Text('Imported ${items.length} foods.$note')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  int? _columnIndex(String key, bool useHeader, Map<String, int> headerMap) {
    if (useHeader) return headerMap[key];
    return _fallbackColumnIndex[key];
  }

  Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    final stream = file.readStream;
    if (stream == null) return null;
    final builder = BytesBuilder();
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Map<String, int> _buildHeaderMap(List<Data?> row) {
    final map = <String, int>{};
    for (var i = 0; i < row.length; i++) {
      final label = _cellString(row[i]);
      if (label.isEmpty) continue;
      final normalized = _normalizeHeader(label);
      final canonical = _headerAliases[normalized];
      if (canonical != null && !map.containsKey(canonical)) {
        map[canonical] = i;
      }
    }
    return map;
  }

  Data? _cellAt(List<Data?> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return null;
    return row[index];
  }

  bool _isRowEmpty(List<Data?> row) {
    for (final cell in row) {
      if (_cellString(cell).isNotEmpty) return false;
    }
    return true;
  }

  String _cellString(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) {
      return value.value.toString().trim();
    }
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) return value.asDateTimeUtc().toIso8601String();
    if (value is DateTimeCellValue) return value.asDateTimeUtc().toIso8601String();
    return value.toString().trim();
  }

  String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  num _numFromCell(Data? cell) {
    if (cell == null) return 0;
    final value = cell.value;
    if (value == null) return 0;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is BoolCellValue) return value.value ? 1 : 0;
    final text = _cellString(cell);
    return _parseNumberText(text) ?? 0;
  }

  int _intFromCell(Data? cell) => _numFromCell(cell).round();

  double _doubleFromCell(Data? cell) => _numFromCell(cell).toDouble();

  num? _parseNumberText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    var normalized = trimmed.replaceAll(' ', '');
    if (normalized.contains('.') && normalized.contains(',')) {
      if (normalized.lastIndexOf(',') > normalized.lastIndexOf('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      final thousandPattern = RegExp(r'^[-+]?(\d{1,3})(,\d{3})+(\.\d+)?$');
      if (thousandPattern.hasMatch(normalized)) {
        normalized = normalized.replaceAll(',', '');
      } else {
        normalized = normalized.replaceAll(',', '.');
      }
    }
    final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
    if (match == null) return null;
    return num.tryParse(match.group(0)!);
  }

  int _parseIntField(String value) {
    final parsed = _parseNumberText(value);
    return parsed?.toInt() ?? 0;
  }

  double _parseDoubleField(String value) {
    final parsed = _parseNumberText(value);
    return parsed?.toDouble() ?? 0;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

    try {
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
                      validator: (v) =>
                          v != null && v.trim().isNotEmpty ? null : 'Required',
                    ),
                    TextFormField(
                      controller: servingCtrl,
                      decoration: const InputDecoration(labelText: 'Serving'),
                      validator: (v) =>
                          v != null && v.trim().isNotEmpty ? null : 'Required',
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
                  caloriesPerServing: _parseIntField(calorieCtrl.text),
                  proteinG: _parseIntField(proteinCtrl.text),
                  carbG: _parseIntField(carbsCtrl.text),
                  fatG: _parseIntField(fatCtrl.text),
                  ironMg: _parseDoubleField(ironCtrl.text),
                  folateMcg: _parseDoubleField(folateCtrl.text),
                );
                final ok = await _runCatalogAction(context, () async {
                  if (entry == null) {
                    await ref.read(foodDatabaseProvider).addCustomItem(item);
                  } else {
                    await ref.read(foodDatabaseProvider).updateCustomItem(item);
                  }
                  await ref.read(foodDatabaseProvider).refresh();
                });
                if (ok && context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      nameCtrl.dispose();
      servingCtrl.dispose();
      calorieCtrl.dispose();
      proteinCtrl.dispose();
      carbsCtrl.dispose();
      fatCtrl.dispose();
      ironCtrl.dispose();
      folateCtrl.dispose();
    }
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    );
  }

  Future<bool> _runCatalogAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Food database update failed: $e')),
        );
      }
      return false;
    }
  }
}
