import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDoc {
  FirestoreDoc({
    required this.id,
    required this.data,
  });

  final String id;
  final Map<String, dynamic> data;

  String? get title => _stringFromKeys(const ['title', 'name', 'message', 'subject']);

  String? get subtitle =>
      _stringFromKeys(const ['subtitle', 'summary', 'description', 'status', 'type']);

  DateTime? get timestamp =>
      _asDate(data['updatedAt']) ??
      _asDate(data['createdAt']) ??
      _asDate(data['generatedAt']) ??
      _asDate(data['date']);

  String? _stringFromKeys(List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final str = _stringOrNull(value);
      if (str != null) return str;
    }
    return null;
  }

  String? _stringOrNull(dynamic raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _asDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
