import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 66 · Inbox, 67 · Duplicate merge, 68 · Completeness.
class InboxController extends GetxController {
  InboxController({required this._ownership});

  final OwnershipRepository _ownership;

  final selected = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    selected.addAll(_ownership.inbox.map((d) => d.id));
  }

  List<InboxDraft> get drafts => _ownership.inbox;

  void toggle(String id, bool on) =>
      on ? selected.add(id) : selected.remove(id);

  Future<void> addMissing(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'Add a missing product',
      label: 'Item name',
    );
    if (name == null || name.isEmpty) return;
    final draft = InboxDraft(
      Ids.next('i'),
      name,
      'Added by you',
      'needs details',
    );
    _ownership.inbox.add(draft);
    selected.add(draft.id);
  }

  /// Drafts only become possessions after this explicit confirmation.
  void reviewSelected() {
    final chosen = drafts.where((d) => selected.contains(d.id)).toList();
    if (chosen.isEmpty) {
      Toast.show('Select at least one draft');
      return;
    }
    for (final d in chosen) {
      _ownership.addPossession(
        Possession(id: Ids.next('p'), name: d.name, room: 'Unassigned'),
      );
      _ownership.inbox.remove(d);
    }
    _ownership.addRoom('Unassigned');
    selected.removeAll(chosen.map((d) => d.id));
    Toast.show(
      '${Formatters.count(chosen.length, 'item')} added to your inventory',
    );
  }

  // 67 · Duplicate merge ----------------------------------------------------

  /// The first inbox draft that names an item already in the inventory.
  /// "Sony headphones" matches "Headphones"; the first word alone does not.
  (InboxDraft, Possession)? get mergeCandidate {
    for (final d in drafts) {
      final match = _ownership.possessions.firstWhereOrNull(
        (p) => namesMatch(d.name, p.name),
      );
      if (match != null) return (d, match);
    }
    return null;
  }

  static bool namesMatch(String a, String b) {
    final left = a.toLowerCase().trim();
    final right = b.toLowerCase().trim();
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    return _containsPhrase(left, right) || _containsPhrase(right, left);
  }

  static bool _containsPhrase(String haystack, String needle) {
    if (needle.length < 4) return false;
    return RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(haystack);
  }

  void merge() {
    final pair = mergeCandidate;
    if (pair == null) return;
    final (draft, existing) = pair;
    _ownership.updatePossession(
      existing.copyWith(
        events: [
          ...existing.events,
          OwnershipEvent(
            label: 'Today',
            title: 'Merged',
            detail: '${draft.origin} details kept.',
          ),
        ],
      ),
    );
    _ownership.inbox.remove(draft);
    selected.remove(draft.id);
    Toast.show('Records merged into ${existing.name}');
  }

  void keepSeparate() {
    final pair = mergeCandidate;
    if (pair == null) return;
    selected
      ..clear()
      ..add(pair.$1.id);
    reviewSelected();
  }

  // 68 · Completeness -------------------------------------------------------

  int get percent => _ownership.completenessPercent();

  int missing(bool Function(Possession p) has) => _ownership.missing(has);

  void fillGaps() => Get.toNamed(Routes.inventory);
}
