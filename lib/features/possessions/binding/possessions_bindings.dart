import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/add_possession_controller.dart';
import '../controller/possession_detail_controller.dart';
import '../controller/possessions_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PossessionsController(ownership: Get.find()));
  }
}

/// Add, identify and serial screens share one controller. An optional room
/// name argument pre-selects the room.
class AddPossessionBinding extends Bindings {
  @override
  void dependencies() {
    final room = Get.arguments as String?;
    Get.lazyPut(
      () => AddPossessionController(ownership: Get.find(), room: room),
    );
  }
}

/// Detail, gallery, documents and extraction share one controller per item.
class PossessionDetailBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => PossessionDetailController(
        ownership: Get.find(),
        receipts: Get.find(),
        possessionId: id,
      ),
      tag: currentRouteTag,
    );
  }
}
