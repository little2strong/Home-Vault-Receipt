import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 88 · Moving overview, 89 · Moving box, 90 · Box label.
class MovingController extends GetxController {
  MovingController({required this._ownership});

  final OwnershipRepository _ownership;

  List<MovingBox> get boxes => _ownership.boxes;

  MovingBox? box(int number) =>
      boxes.firstWhereOrNull((b) => b.number == number);

  List<MovingBox> withStatus(BoxStatus status) =>
      boxes.where((b) => b.status == status).toList();

  int itemCount(Iterable<MovingBox> list) =>
      list.fold(0, (s, b) => s + b.items.length);

  void openBox(MovingBox b) =>
      Get.toNamed(Routes.movingBox, arguments: b.number);

  void openLabel(int number) => Get.toNamed(Routes.boxLabel, arguments: number);

  Future<void> createBox(BuildContext context) async {
    final room = await promptText(
      context,
      title: 'Create a box',
      label: 'Room',
    );
    if (room == null || room.isEmpty) return;
    final next = boxes.fold(0, (m, b) => b.number > m ? b.number : m) + 1;
    boxes.add(
      MovingBox(
        number: next,
        room: room,
        status: BoxStatus.notPacked,
        items: const [],
        destination: 'New home · ${room.toLowerCase()}',
      ),
    );
    Toast.show('Box $next created');
  }

  Future<void> changeStatus(BuildContext context, int number) async {
    final current = box(number);
    if (current == null) return;
    final i = await showOptionSheet(
      context,
      title: 'Status',
      options: [for (final s in BoxStatus.values) s.label],
      selected: current.status.index,
    );
    if (i == null) return;
    final index = boxes.indexWhere((b) => b.number == number);
    boxes[index] = current.copyWith(status: BoxStatus.values[i]);
  }

  void exportLabel() =>
      Toast.show('Label export is a preview. The QR code is a placeholder.');
}
