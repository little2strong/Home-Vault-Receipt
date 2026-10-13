import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 61 · Rooms, 62 · Room detail, 63 · Room scan, 64 · Scan review,
/// 65 · Rapid inventory.
class RoomsController extends GetxController {
  RoomsController({required this._ownership});

  final OwnershipRepository _ownership;

  /// Objects the room scan "detected" (sample), with selection.
  final detected = <(String, String)>[
    ('Television', 'Suggested · model unknown'),
    ('Sofa', 'Suggested · brand unknown'),
    ('Coffee table', 'Suggested · material unknown'),
  ];
  final selectedDetections = <int>{0, 1, 2}.obs;
  final rapidDrafts = <String>[].obs;

  List<String> get rooms => _ownership.rooms;

  List<Possession> inRoom(String room) => _ownership.inRoom(room);

  String roomSummary(String room) {
    final owned = inRoom(room).where((p) => p.status == OwnershipStatus.owned);
    return '${Formatters.count(owned.length, 'possession')} · recorded value '
        '${Money.formatWhole(_ownership.recordedValue(owned))}';
  }

  void openRoom(String room) => Get.toNamed(Routes.roomDetail, arguments: room);

  void openPossession(Possession p) =>
      Get.toNamed(Routes.possessionDetail, arguments: p.id);

  void addItem(String room) =>
      Get.toNamed(Routes.addPossession, arguments: room);

  void scan() => Get.toNamed(Routes.roomScan);

  Future<void> addRoom(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'Add room',
      label: 'Room name',
    );
    if (name == null || name.isEmpty) return;
    if (rooms.any((r) => r.toLowerCase() == name.toLowerCase())) {
      Toast.show('$name already exists');
      return;
    }
    _ownership.addRoom(name);
  }

  void reviewScan() {
    selectedDetections.assignAll({0, 1, 2});
    Get.toNamed(Routes.roomScanReview);
  }

  void toggleDetection(int i, bool on) =>
      on ? selectedDetections.add(i) : selectedDetections.remove(i);

  /// Detected objects become drafts; nothing is added without review.
  void createDrafts() {
    for (final i in selectedDetections) {
      final (name, note) = detected[i];
      _ownership.inbox.add(InboxDraft(Ids.next('i'), name, 'Room scan', note));
    }
    Toast.show(
      '${Formatters.count(selectedDetections.length, 'draft')} added to your inbox',
    );
    Get.offNamed(Routes.inbox);
  }

  Future<void> captureNext(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'What is it?',
      label: 'Item name',
    );
    if (name == null || name.isEmpty) return;
    rapidDrafts.add(name);
  }

  void finishRapid() {
    if (rapidDrafts.isEmpty) {
      Get.back();
      return;
    }
    for (final name in rapidDrafts) {
      _ownership.inbox.add(
        InboxDraft(Ids.next('i'), name, 'Rapid inventory', 'photo added'),
      );
    }
    rapidDrafts.clear();
    Get.offNamed(Routes.inbox);
  }
}
