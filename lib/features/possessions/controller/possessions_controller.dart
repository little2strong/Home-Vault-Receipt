import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';

/// 53 · Inventory
class PossessionsController extends GetxController {
  PossessionsController({required this._ownership});

  final OwnershipRepository _ownership;

  List<Possession> get possessions => _ownership.possessions;

  int get roomCount => _ownership.rooms.length;

  void open(Possession p) =>
      Get.toNamed(Routes.possessionDetail, arguments: p.id);

  void add() => Get.toNamed(Routes.addPossession);

  void openRooms() => Get.toNamed(Routes.rooms);

  void openCollections() => Get.toNamed(Routes.collections);

  void openInbox() => Get.toNamed(Routes.inbox);

  void openRapidInventory() => Get.toNamed(Routes.rapidInventory);

  void openMerge() => Get.toNamed(Routes.duplicateMerge);
}
