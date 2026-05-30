import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/models/firestore_doc.dart';
import 'package:smartbunda/providers/app_providers.dart';
import 'package:smartbunda/widgets/require_sign_in.dart';
import 'package:smartbunda/widgets/screen_header.dart';
import 'package:smartbunda/screens/patient/module_overview_screen.dart';
import 'package:smartbunda/screens/patient/nutrition_facts_screen.dart';
import 'package:smartbunda/screens/patient/perinatal_care_manual_screen.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(educationContentProvider);
    final strings = AppStrings.of(context);
    return RequireSignIn(
      title: strings.t('Education & content'),
      showAppBar: true,
      message: strings.t('Please sign in to view education content.'),
      child: Scaffold(
        appBar: AppBar(title: Text(strings.t('Education & content'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ScreenHeader(
              title: strings.t('Education'),
              subtitle:
                  strings.t('Browse guides, tips, and trimester content.'),
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 16),
            const _EducationChatBox(),
            const SizedBox(height: 24),
            contentAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.t('From database'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...items.map(
                      (doc) => _EducationCard(
                        icon: Icons.menu_book_outlined,
                        title: doc.title ?? doc.id,
                        subtitle:
                            doc.subtitle ?? strings.t('Tap to view details.'),
                        onTap: () => _openDoc(context, doc),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(strings.errorLoadingContent('$e')),
              ),
            ),
            _EducationCard(
              icon: Icons.menu_book_outlined,
              title: strings.t('Trimester nutrition guide'),
              subtitle:
                  strings.t('Recommended targets based on gestation stage.'),
              onTap: () => _open(context, const NutritionFactsScreen()),
            ),
            _EducationCard(
              icon: Icons.local_hospital_outlined,
              title: strings.t('Perinatal care manual'),
              subtitle: strings.t(
                'Pre-pregnancy risk checks, care workflow, counselling, and antenatal visits.',
              ),
              onTap: () => _open(context, const PerinatalCareManualScreen()),
            ),
            _EducationCard(
              icon: Icons.restaurant_outlined,
              title: strings.t('Healthy meal suggestions'),
              subtitle: strings.t('Balanced meal ideas and snack tips.'),
              onTap: () => _open(
                context,
                ModuleOverviewScreen(
                  title: strings.t('Healthy meal suggestions'),
                  description:
                      strings.t('Curated meal ideas for each trimester.'),
                  icon: Icons.restaurant_outlined,
                  features: [
                    strings.t(
                        'Iron-rich meals with leafy greens and lean proteins'),
                    strings.t('Calcium-forward snacks and dairy alternatives'),
                    strings.t('Balanced plates with complex carbs and fiber'),
                  ],
                  footer: strings
                      .t('Personalize recommendations with your care team.'),
                ),
              ),
            ),
            _EducationCard(
              icon: Icons.lightbulb_outline,
              title: strings.t('Pregnancy nutrition FAQs'),
              subtitle: strings.t('Quick guidance and common questions.'),
              onTap: () => _open(
                context,
                ModuleOverviewScreen(
                  title: strings.t('Pregnancy nutrition FAQs'),
                  description:
                      strings.t('Common questions answered in one place.'),
                  icon: Icons.lightbulb_outline,
                  features: [
                    strings.t('How much water should I drink daily?'),
                    strings.t('What foods support healthy iron levels?'),
                    strings.t('Safe caffeine limits during pregnancy'),
                  ],
                  footer: strings
                      .t('Always consult your clinician for medical advice.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openDoc(BuildContext context, FirestoreDoc doc) {
    final strings = AppStrings.of(context);
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
            child: Text(strings.t('Close')),
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
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EducationChatBox extends StatefulWidget {
  const _EducationChatBox();

  @override
  State<_EducationChatBox> createState() => _EducationChatBoxState();
}

class _EducationChatBoxState extends State<_EducationChatBox> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final strings = AppStrings.of(context);
    _messages.add(
      _ChatMessage(
        isUser: false,
        text: strings.t('Ask about pregnancy nutrition and the content above.'),
      ),
    );
    _seeded = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final strings = AppStrings.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: _generateResponse(text, strings),
        ),
      );
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateResponse(String input, AppStrings strings) {
    final query = input.toLowerCase();
    if (query.contains('water') ||
        query.contains('hydration') ||
        query.contains('air')) {
      return strings.t(
        'Try to spread water intake across the day, aim for steady sips, and follow any target from your care team.',
      );
    }
    if (query.contains('iron') ||
        query.contains('anemia') ||
        query.contains('zat besi')) {
      return strings.t(
        'Pair iron sources with vitamin C and include leafy greens, beans, or lean meats.',
      );
    }
    if (query.contains('caffeine') || query.contains('kopi')) {
      return strings.t(
        'During pregnancy, keep caffeine moderate and check with your clinician if unsure.',
      );
    }
    return strings.t(
      'Thanks for the question. This is a demo chat box. Connect an AI service to provide tailored answers.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 150);
    final assistantFill = scheme.surfaceContainerHighest.withValues(alpha: 180);
    final userFill = Color.alphaBlend(
      scheme.primary.withValues(alpha: 32),
      scheme.surface,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  strings.t('AI nutrition assistant'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.t('Ask about pregnancy nutrition and the content above.'),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ListView.separated(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final align = message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final bubbleColor =
                        message.isUser ? userFill : assistantFill;
                    final textColor = scheme.onSurface;
                    return Align(
                      alignment: align,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: textColor),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: _messages.length,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 2,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: strings.t('Ask a nutrition question'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: strings.t('Send'),
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}
