import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/formatters.dart';

class AssistantLink {
  const AssistantLink(this.label, this.route, this.argument);

  final String label;
  final String route;
  final Object? argument;
}

class AssistantMessage {
  const AssistantMessage.user(this.text) : fromUser = true, links = const [];
  const AssistantMessage.reply(this.text, [this.links = const []])
    : fromUser = false;

  final String text;
  final bool fromUser;
  final List<AssistantLink> links;
}

/// 96 · Assistant. Answers only from the user's own records, with links to
/// them, using simple on-device rules; it never invents facts.
class AssistantController extends GetxController {
  AssistantController({required this._receipts, required this._ownership});

  final ReceiptRepository _receipts;
  final OwnershipRepository _ownership;

  final input = TextEditingController();
  final messages = <AssistantMessage>[].obs;

  static const suggestions = [
    'Which items are missing receipts?',
    'Which returns close soon?',
    'When do my warranties end?',
    'How much have I spent this month?',
  ];

  void ask([String? question]) {
    final text = (question ?? input.text).trim();
    if (text.isEmpty) return;
    input.clear();
    messages
      ..add(AssistantMessage.user(text))
      ..add(answer(text));
  }

  AssistantMessage answer(String question) {
    final q = question.toLowerCase();
    if (q.contains('receipt') &&
        (q.contains('missing') || q.contains('without'))) {
      final missing = _ownership.possessions
          .where((p) => !p.hasReceipt)
          .toList();
      if (missing.isEmpty) {
        return const AssistantMessage.reply(
          'Every recorded possession has a receipt attached.',
        );
      }
      return AssistantMessage.reply(
        '${Formatters.count(missing.length, 'recorded possession')} '
        '${missing.length == 1 ? 'does' : 'do'} not have a receipt attached.',
        [
          for (final p in missing)
            AssistantLink(
              '${p.name} · ${p.room}',
              Routes.possessionDetail,
              p.id,
            ),
        ],
      );
    }
    if (q.contains('return') || q.contains('deadline')) {
      final open = _receipts.openDeadlines();
      if (open.isEmpty) {
        return const AssistantMessage.reply(
          'No confirmed return deadlines are open.',
        );
      }
      return AssistantMessage.reply(
        '${Formatters.count(open.length, 'return')} still open, soonest first.',
        [
          for (final r in open)
            AssistantLink(
              '${r.retailer} · ${Formatters.shortDate(r.returnDeadline!)}',
              Routes.reminderDetail,
              r.id,
            ),
        ],
      );
    }
    if (q.contains('warrant')) {
      final items =
          _ownership.possessions.where((p) => p.warrantyExpiry != null).toList()
            ..sort((a, b) => a.warrantyExpiry!.compareTo(b.warrantyExpiry!));
      if (items.isEmpty) {
        return const AssistantMessage.reply(
          'No warranty dates are confirmed yet.',
        );
      }
      return AssistantMessage.reply('Confirmed warranty end dates:', [
        for (final p in items)
          AssistantLink(
            '${p.name} · ${Formatters.date(p.warrantyExpiry!)}',
            Routes.warrantyAssistant,
            p.id,
          ),
      ]);
    }
    if (q.contains('spent') || q.contains('spend') || q.contains('how much')) {
      final today = _receipts.today;
      final thisMonth = _receipts.saved.where(
        (r) =>
            r.purchaseDate.year == today.year &&
            r.purchaseDate.month == today.month,
      );
      final byCurrency = <String, int>{};
      for (final r in thisMonth) {
        byCurrency[r.currency] = (byCurrency[r.currency] ?? 0) + r.total;
      }
      if (byCurrency.isEmpty) {
        return const AssistantMessage.reply('No saved receipts this month.');
      }
      final totals = byCurrency.entries
          .map((e) => Formatters.currency(e.value, e.key))
          .join(' and ');
      return AssistantMessage.reply(
        'This month: $totals across ${Formatters.count(thisMonth.length, 'receipt')}.',
      );
    }
    return const AssistantMessage.reply(
      'I can answer from your own records: missing receipts, open returns, '
      'warranty dates and monthly spending.',
    );
  }

  void openLink(AssistantLink link) =>
      Get.toNamed(link.route, arguments: link.argument);

  @override
  void onClose() {
    input.dispose();
    super.onClose();
  }
}
