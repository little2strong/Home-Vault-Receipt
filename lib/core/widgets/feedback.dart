import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_sizes.dart';
import '../models/vault_models.dart';
import '../theme/vault_palette.dart';
import '../utils/money.dart';
import 'buttons.dart';
import 'vault_ui.dart';

/// Short confirmations through the app's [ScaffoldMessenger]. (An open
/// `Get.snackbar` would make `Get.back()` close it instead of the page.)
abstract final class Toast {
  static void show(String message) {
    if (message.isEmpty) return;
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

abstract final class Pickers {
  static Future<DateTime?> date(
    BuildContext context, {
    DateTime? initial,
    DateTime? first,
    DateTime? last,
    String? help,
  }) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: first ?? DateTime(1970),
    lastDate: last ?? DateTime(DateTime.now().year + 15),
    helpText: help,
  );

  static Future<String?> currency(BuildContext context, String current) =>
      choose<String>(
        context,
        title: 'Currency',
        values: Money.currencies,
        selected: current,
        label: (c) => '$c ${Money.symbolFor(c).trim()}',
      );

  /// A bottom sheet list of choices.
  static Future<T?> choose<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required String Function(T) label,
    T? selected,
    Widget? footer,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.md,
          ),
          children: [
            Text(title, style: context.textStyles.headlineSmall),
            const SizedBox(height: 12),
            for (final v in values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label(v), style: const TextStyle(fontSize: 17)),
                trailing: v == selected
                    ? Icon(Icons.check_rounded, color: context.palette.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(v),
              ),
            ?footer,
          ],
        ),
      ),
    ),
  );

  /// Room picker with "Set up your rooms" when none exist yet.
  static Future<String?> room(
    BuildContext context, {
    required List<Room> rooms,
    String? selected,
    required VoidCallback onSetUp,
  }) async {
    if (rooms.isEmpty) {
      onSetUp();
      return null;
    }
    return choose<String>(
      context,
      title: 'Which room?',
      values: [for (final r in rooms) r.id],
      selected: selected,
      label: (id) => rooms.firstWhere((r) => r.id == id).name,
    );
  }

  static Future<String?> text(
    BuildContext context, {
    required String title,
    String? initial,
    String? hint,
    String action = 'Save',
    TextCapitalization caps = TextCapitalization.sentences,
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: caps,
          keyboardType: keyboard,
          obscureText: obscure,
          autocorrect: !obscure,
          enableSuggestions: !obscure,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: context.palette.dangerInk,
                  )
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

/// Bottom sheet frame matching the design: title row, body, actions.
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.actions = const [],
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final List<Widget> actions;

  static Future<T?> show<T>(Widget sheet) => Get.bottomSheet<T>(
    sheet,
    isScrollControlled: true,
    backgroundColor: Get.context!.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: context.palette.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  16,
                  AppSizes.pagePadding,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.textStyles.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    8,
                    AppSizes.pagePadding,
                    8,
                  ),
                  children: children,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    8,
                    AppSizes.pagePadding,
                    AppSizes.md,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: i == actions.length - 1 ? 2 : 1,
                          child: actions[i],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A close button for sheets.
class SheetClose extends StatelessWidget {
  const SheetClose({super.key});

  @override
  Widget build(BuildContext context) => SquareIconButton(
    icon: Icons.close_rounded,
    tooltip: 'Close',
    onPressed: () => Navigator.of(context).pop(),
  );
}

/// Money in the user's view: `£499.00`, or `~£120` for estimates.
String money(int? minor, String currency, {bool estimate = false}) {
  if (minor == null) return 'Not stated';
  if (estimate) return '~${Money.formatWhole(minor, currency: currency)}';
  return Money.format(minor, currency: currency);
}

/// Totals per currency, main currency first: `£8,420.47 + €86.50`.
String moneyTotals(Map<String, int> totals, {String main = 'GBP'}) {
  if (totals.isEmpty) return Money.format(0, currency: main);
  final keys = totals.keys.toList()
    ..sort((a, b) => a == main ? -1 : (b == main ? 1 : a.compareTo(b)));
  return keys.map((c) => Money.format(totals[c]!, currency: c)).join(' + ');
}

/// For a widget-level pill showing a warranty word plus colour.
PillTone toneForDays(int days) =>
    days < 0 ? PillTone.grey : (days <= 92 ? PillTone.amber : PillTone.green);
