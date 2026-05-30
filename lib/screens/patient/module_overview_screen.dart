import 'package:flutter/material.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class ModuleOverviewScreen extends StatelessWidget {
  const ModuleOverviewScreen({
    super.key,
    required this.title,
    required this.description,
    required this.features,
    this.icon,
    this.footer,
  });

  final String title;
  final String description;
  final List<String> features;
  final IconData? icon;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScreenHeader(
            title: title,
            subtitle: description,
            icon: icon ?? Icons.info_outline,
          ),
          const SizedBox(height: 16),
          Text(strings.t('What you can do'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...features.map(
            (feature) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(feature),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Text(footer!, style: const TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}
