import 'package:flutter/material.dart';

/// Status of the last prediction attempt, driving how [ResultBanner] looks.
enum ResultState { idle, loading, success, error }

/// The display area at the bottom of the page: shows the predicted value
/// on success, or a clear error message for validation failures / server
/// errors / connection problems.
class ResultBanner extends StatelessWidget {
  final ResultState state;
  final String message;

  const ResultBanner({super.key, required this.state, required this.message});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    switch (state) {
      case ResultState.success:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case ResultState.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.error_outline;
        break;
      case ResultState.loading:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.hourglass_top;
        break;
      case ResultState.idle:
        bg = Colors.grey.shade100;
        fg = Colors.black87;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
