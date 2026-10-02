import 'package:flutter/material.dart';

class PredictionBadge extends StatelessWidget {
  final String status; // 'verified', 'predicted', 'estimated', 'unknown'
  final String locale;

  const PredictionBadge({
    super.key,
    required this.status,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String labelText;

    switch (status) {
      case 'verified':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.verified;
        labelText = 'Official';
        break;
      case 'predicted':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.psychology;
        labelText = 'AI Forecast';
        break;
      case 'estimated':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.warning_amber;
        labelText = 'Rough Est.';
        break;
      default:
        // Return empty widget for unknown status
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
