import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Status of the last prediction attempt, driving how [ResultBanner] looks.
enum ResultState { idle, loading, success, error }

/// The display area at the bottom of the page. On success, the predicted
/// number is shown as a large monospace readout -- the app's signature
/// moment, styled like a console output rather than a generic alert box.
class ResultBanner extends StatelessWidget {
  final ResultState state;
  final String message;
  final String? readoutValue;
  final String? readoutCaption;

  const ResultBanner({
    super.key,
    required this.state,
    required this.message,
    this.readoutValue,
    this.readoutCaption,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color bg;
    final IconData icon;

    switch (state) {
      case ResultState.success:
        accent = AppColors.success;
        bg = AppColors.successBg;
        icon = Icons.check_circle_outline;
        break;
      case ResultState.error:
        accent = AppColors.danger;
        bg = AppColors.dangerBg;
        icon = Icons.error_outline;
        break;
      case ResultState.loading:
        accent = AppColors.accent;
        bg = AppColors.surfaceAlt;
        icon = Icons.hourglass_top;
        break;
      case ResultState.idle:
        accent = AppColors.textMuted;
        bg = AppColors.surface;
        icon = Icons.info_outline;
        break;
    }

    if (state == ResultState.success && readoutValue != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 6),
                Text('PREDICTED COUNT',
                    style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
              ],
            ),
            const SizedBox(height: 6),
            Text(readoutValue!, style: AppTheme.mono(fontSize: 40, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (readoutCaption != null) ...[
              const SizedBox(height: 4),
              Text(readoutCaption!, style: AppTheme.body(fontSize: 12)),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppTheme.body(fontSize: 13.5, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
