class FeedbackEntry {
  FeedbackEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.rating,
  });

  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;
  final int? rating;
}
