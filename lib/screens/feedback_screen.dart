import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_strings.dart';
import '../models/app_user.dart';
import '../models/feedback_entry.dart';
import '../providers/app_providers.dart';
import '../services/service_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/require_sign_in.dart';
import '../widgets/screen_header.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  int _rating = 5;
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;
    final strings = AppStrings.of(context);
    setState(() => _sending = true);
    final entry = FeedbackEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: user.id,
      userName: user.displayName ?? user.email,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      rating: _rating,
    );
    await ref.read(dataStoreProvider).addFeedback(entry);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _messageCtrl.clear();
      _rating = 5;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('Feedback sent'))),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final strings = AppStrings.of(context);
    final child = user == null
        ? const SizedBox.shrink()
        : _feedbackView(context, user);
    return RequireSignIn(
      title: strings.t('Feedback'),
      showAppBar: true,
      message: strings.t('Please sign in to send feedback.'),
      child: child,
    );
  }

  Widget _feedbackView(BuildContext context, AppUser user) {
    final strings = AppStrings.of(context);
    final isMonitor = user.role == UserRole.admin ||
        user.role == UserRole.doctor ||
        user.role == UserRole.nurse ||
        user.role == UserRole.dietitian;
    final feedbackAsync =
        ref.watch(isMonitor ? allFeedbackProvider : feedbackProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isMonitor ? strings.t('Feedback monitor') : strings.t('Feedback'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: feedbackAsync.when(
          data: (entries) {
            final sorted = List.of(entries)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView(
              children: [
                ScreenHeader(
                  title: isMonitor ? strings.t('Feedback monitor') : strings.t('Feedback'),
                  subtitle: isMonitor
                      ? strings.t('Review comments and ratings from users.')
                      : strings.t('Share how the app is working for you.'),
                  icon: Icons.feedback_outlined,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('Share your feedback'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageCtrl,
                        decoration: InputDecoration(
                          labelText: strings.t('Message'),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (v) =>
                            v != null && v.trim().isNotEmpty ? null : strings.t('Required'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _rating,
                        items: List.generate(
                          5,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1} / 5'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) setState(() => _rating = value);
                        },
                        decoration: InputDecoration(labelText: strings.t('Rating')),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _sending ? null : () => _submitFeedback(user),
                          child: _sending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.t('Send feedback')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMonitor ? strings.t('All feedback') : strings.t('Your feedback'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  EmptyState(
                    icon: Icons.feedback_outlined,
                    title: strings.t('No feedback yet'),
                    message: strings.t('Feedback will show up here once it is submitted.'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = sorted[index];
                      return Card(
                        child: ListTile(
                          title: Text(entry.message),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry.rating != null)
                                Text(strings.ratingValue(entry.rating!)),
                              if (isMonitor)
                                Text(strings.fromUser(entry.userName)),
                              Text(_formatTimestamp(entry.createdAt)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
