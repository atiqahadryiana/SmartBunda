import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/firestore_paths.dart';
import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/services/service_providers.dart';
import 'package:smartbunda/theme/app_components.dart';
import 'package:smartbunda/widgets/empty_state.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class ContentManagementScreen extends ConsumerWidget {
  const ContentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RequireSignIn(
      title: 'Content management',
      showAppBar: true,
      message: 'Please sign in to manage content.',
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Content management'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Education'),
                Tab(text: 'Recommendations'),
                Tab(text: 'Notifications'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ContentTab(type: ContentType.education),
              _ContentTab(type: ContentType.recommendation),
              _ContentTab(type: ContentType.notification),
              _ContentTab(type: ContentType.report),
            ],
          ),
        ),
      ),
    );
  }
}

enum ContentType { education, recommendation, notification, report }

class _ContentTab extends ConsumerWidget {
  const _ContentTab({required this.type});

  final ContentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = _itemsForType(ref);
    final allowEdits = type != ContentType.report;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScreenHeader(
            title: _title,
            subtitle: _subtitle,
            icon: _icon,
            action: allowEdits
                ? FilledButton.icon(
                    onPressed: () => _showEditor(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: _icon,
                    title: 'No items yet',
                    message: _emptyMessage,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final isActive = (doc.data['isActive'] as bool?) ?? true;
                    return Card(
                      child: ListTile(
                        title: Text(_titleFor(doc)),
                        subtitle: Text(_subtitleFor(doc)),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (allowEdits)
                              Switch(
                                value: isActive,
                                onChanged: (value) => ref
                                    .read(contentRepositoryProvider)
                                    .setActive(
                                      collection: _collection,
                                      id: doc.id,
                                      isActive: value,
                                    ),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showDetails(context, doc);
                                } else if (value == 'edit') {
                                  _showEditor(context, ref, doc: doc);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref, doc);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View'),
                                ),
                                if (allowEdits)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => const _ContentItemSkeleton(),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  AsyncValue<List<FirestoreDoc>> _itemsForType(WidgetRef ref) {
    switch (type) {
      case ContentType.education:
        return ref.watch(allEducationContentProvider);
      case ContentType.recommendation:
        return ref.watch(allRecommendationsProvider);
      case ContentType.notification:
        return ref.watch(allNotificationsProvider);
      case ContentType.report:
        return ref.watch(allReportsProvider);
    }
  }

  String get _title {
    switch (type) {
      case ContentType.education:
        return 'Education content';
      case ContentType.recommendation:
        return 'Recommendations';
      case ContentType.notification:
        return 'Notifications';
      case ContentType.report:
        return 'Reports';
    }
  }

  String get _subtitle {
    switch (type) {
      case ContentType.education:
        return 'Create and manage educational materials for patients.';
      case ContentType.recommendation:
        return 'Add recommendation messages per patient or globally.';
      case ContentType.notification:
        return 'Send or store notification messages for users.';
      case ContentType.report:
        return 'Saved reports generated by the app.';
    }
  }

  String get _emptyMessage {
    switch (type) {
      case ContentType.education:
        return 'Create your first education item.';
      case ContentType.recommendation:
        return 'Create your first recommendation.';
      case ContentType.notification:
        return 'Create your first notification.';
      case ContentType.report:
        return 'Reports will appear once patients export them.';
    }
  }

  IconData get _icon {
    switch (type) {
      case ContentType.education:
        return Icons.menu_book_outlined;
      case ContentType.recommendation:
        return Icons.analytics_outlined;
      case ContentType.notification:
        return Icons.notifications_none_outlined;
      case ContentType.report:
        return Icons.assessment_outlined;
    }
  }

  String get _collection {
    switch (type) {
      case ContentType.education:
        return FS.educationContent;
      case ContentType.recommendation:
        return FS.recommendations;
      case ContentType.notification:
        return FS.notifications;
      case ContentType.report:
        return FS.reports;
    }
  }

  String _titleFor(FirestoreDoc doc) {
    final data = doc.data;
    final base = _stringOrNull(
          data['title'],
        ) ??
        _stringOrNull(data['name']) ??
        _stringOrNull(data['recommendation']) ??
        _stringOrNull(data['message']) ??
        doc.title ??
        doc.id;
    return _truncate(base, 64);
  }

  String _subtitleFor(FirestoreDoc doc) {
    final data = doc.data;
    switch (type) {
      case ContentType.education:
        return _stringOrNull(data['summary']) ??
            _stringOrNull(data['subtitle']) ??
            _stringOrNull(data['description']) ??
            'Tap to view details.';
      case ContentType.recommendation:
        return _patientLabel(data) ?? 'General recommendation';
      case ContentType.notification:
        final message = _stringOrNull(data['message']);
        final patient = _patientLabel(data);
        if (message != null && patient != null) {
          return '$message | $patient';
        }
        return message ?? patient ?? 'Notification';
      case ContentType.report:
        final patient = _stringOrNull(data['patientId']) ?? _stringOrNull(data['userId']);
        final calories = data['avgCalories'];
        final protein = data['avgProtein'];
        final summary = [
          if (calories != null) 'Calories $calories',
          if (protein != null) 'Protein $protein',
        ].join(' | ');
        if (patient != null && summary.isNotEmpty) {
          return 'Patient $patient | $summary';
        }
        return patient != null ? 'Patient $patient' : (summary.isNotEmpty ? summary : 'Report');
    }
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    FirestoreDoc? doc,
  }) async {
    switch (type) {
      case ContentType.education:
        await _showEducationEditor(context, ref, doc: doc);
        return;
      case ContentType.recommendation:
        await _showRecommendationEditor(context, ref, doc: doc);
        return;
      case ContentType.notification:
        await _showNotificationEditor(context, ref, doc: doc);
        return;
      case ContentType.report:
        return;
    }
  }

  Future<void> _showEducationEditor(
    BuildContext context,
    WidgetRef ref, {
    FirestoreDoc? doc,
  }) async {
    final data = doc?.data ?? {};
    final titleCtrl = TextEditingController(
      text: _stringOrNull(data['title']) ?? _stringOrNull(data['name']) ?? '',
    );
    final summaryCtrl = TextEditingController(
      text: _stringOrNull(data['summary']) ?? _stringOrNull(data['subtitle']) ?? '',
    );
    final bodyCtrl = TextEditingController(
      text: _stringOrNull(data['body']) ?? _stringOrNull(data['content']) ?? '',
    );
    var isActive = (data['isActive'] as bool?) ?? true;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Add education content' : 'Edit education content'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value != null && value.trim().isNotEmpty ? null : 'Required',
                    ),
                    TextFormField(
                      controller: summaryCtrl,
                      decoration: const InputDecoration(labelText: 'Summary'),
                    ),
                    TextFormField(
                      controller: bodyCtrl,
                      decoration: const InputDecoration(labelText: 'Body'),
                      maxLines: 4,
                    ),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: const Text('Active'),
                    ),
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
                await ref.read(contentRepositoryProvider).upsertEducationContent(
                      id: doc?.id,
                      title: titleCtrl.text.trim(),
                      summary: _nullIfEmpty(summaryCtrl.text),
                      body: _nullIfEmpty(bodyCtrl.text),
                      isActive: isActive,
                    );
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecommendationEditor(
    BuildContext context,
    WidgetRef ref, {
    FirestoreDoc? doc,
  }) async {
    final data = doc?.data ?? {};
    final textCtrl = TextEditingController(
      text: _stringOrNull(data['recommendation']) ??
          _stringOrNull(data['text']) ??
          _stringOrNull(data['message']) ??
          '',
    );
    final patientCtrl = TextEditingController(
      text: _stringOrNull(data['patientId']) ?? _stringOrNull(data['userId']) ?? '',
    );
    var isActive = (data['isActive'] as bool?) ?? true;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Add recommendation' : 'Edit recommendation'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: textCtrl,
                      decoration: const InputDecoration(labelText: 'Recommendation text'),
                      maxLines: 3,
                      validator: (value) =>
                          value != null && value.trim().isNotEmpty ? null : 'Required',
                    ),
                    TextFormField(
                      controller: patientCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Patient ID (optional)'),
                    ),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: const Text('Active'),
                    ),
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
                await ref.read(contentRepositoryProvider).upsertRecommendation(
                      id: doc?.id,
                      text: textCtrl.text.trim(),
                      patientId: _nullIfEmpty(patientCtrl.text),
                      isActive: isActive,
                    );
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotificationEditor(
    BuildContext context,
    WidgetRef ref, {
    FirestoreDoc? doc,
  }) async {
    final data = doc?.data ?? {};
    final titleCtrl = TextEditingController(
      text: _stringOrNull(data['title']) ?? _stringOrNull(data['name']) ?? '',
    );
    final messageCtrl = TextEditingController(
      text: _stringOrNull(data['message']) ?? _stringOrNull(data['body']) ?? '',
    );
    final patientCtrl = TextEditingController(
      text: _stringOrNull(data['patientId']) ?? _stringOrNull(data['userId']) ?? '',
    );
    var isActive = (data['isActive'] as bool?) ?? true;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Add notification' : 'Edit notification'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value != null && value.trim().isNotEmpty ? null : 'Required',
                    ),
                    TextFormField(
                      controller: messageCtrl,
                      decoration: const InputDecoration(labelText: 'Message'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: patientCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Patient ID (optional)'),
                    ),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: const Text('Active'),
                    ),
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
                await ref.read(contentRepositoryProvider).upsertNotification(
                      id: doc?.id,
                      title: titleCtrl.text.trim(),
                      message: _nullIfEmpty(messageCtrl.text),
                      patientId: _nullIfEmpty(patientCtrl.text),
                      isActive: isActive,
                    );
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FirestoreDoc doc,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete ${doc.id}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(contentRepositoryProvider).deleteDoc(
                    collection: _collection,
                    id: doc.id,
                  );
              if (context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, FirestoreDoc doc) {
    final entries = doc.data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title ?? doc.id),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key}: ${_valueLabel(entry.value)}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _valueLabel(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Iterable) {
      return value.map((item) => item.toString()).join(', ');
    }
    return value.toString();
  }

  String? _stringOrNull(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _nullIfEmpty(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _patientLabel(Map<String, dynamic> data) {
    final patient = _stringOrNull(data['patientId']) ?? _stringOrNull(data['userId']);
    return patient == null ? null : 'Patient $patient';
  }

  String _truncate(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 3)}...';
  }
}

class _ContentItemSkeleton extends StatelessWidget {
  const _ContentItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        title: SbSkeletonLoader(
          height: 16,
          width: 200,
        ),
        subtitle: SbSkeletonLoader(
          height: 12,
          width: 300,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SbSkeletonLoader(
              width: 40,
              height: 20,
            ),
            SizedBox(width: 8),
            SbSkeletonLoader(
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
