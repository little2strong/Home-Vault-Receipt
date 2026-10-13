import 'package:flutter/material.dart';

/// Explains a roadmap action instead of pretending it worked.
Future<void> showRoadmapDialog(
  BuildContext context,
  String title,
  String body,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$title · coming later'),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
