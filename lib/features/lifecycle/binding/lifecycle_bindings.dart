import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/collections_controller.dart';
import '../controller/lifecycle_controller.dart';

/// Timeline, resale, status and sharing for one possession.
class LifecycleBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => LifecycleController(ownership: Get.find(), possessionId: id),
      tag: currentRouteTag,
    );
  }
}

class CollectionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CollectionsController(ownership: Get.find()));
  }
}
