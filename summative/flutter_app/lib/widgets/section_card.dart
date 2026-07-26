import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A labeled panel grouping a set of related fields -- styled like a
/// monitoring-dashboard panel: dark surface, a colored accent bar on the
/// leading edge, and an icon that hints at what the section measures.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(title, style: AppTheme.display(fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}