import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

/// Bottom sheet with one tappable row per option. Returns the chosen index,
/// or null when dismissed (so "Any" can be a real option).
Future<int?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  int? selected,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                0,
                AppSizes.pagePadding,
                AppSizes.sm,
              ),
              child: Text(title, style: sheetContext.textStyles.titleMedium),
            ),
            for (var i = 0; i < options.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                title: Text(options[i]),
                selected: i == selected,
                trailing: i == selected
                    ? Icon(
                        Icons.check_rounded,
                        color: sheetContext.palette.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(i),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
  String? help,
}) {
  final firstDate = first ?? DateTime(2000);
  final lastDate = last ?? DateTime(2100);
  final clamped = initial.isBefore(firstDate)
      ? firstDate
      : initial.isAfter(lastDate)
      ? lastDate
      : initial;
  return showDatePicker(
    context: context,
    initialDate: clamped,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: help,
  );
}

/// Asks for a short piece of text in a dialog, e.g. a room name.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String confirm = 'Save',
  bool obscure = false,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(confirm),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Continue',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: dialogContext.palette.dangerInk,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
