import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Tag for a controller bound to one record, taken from the route argument
/// (a receipt id, a category…). Bindings register with [currentRouteTag];
/// views resolve with [routeTag].
String? routeTag(BuildContext context) =>
    ModalRoute.of(context)?.settings.arguments?.toString();

String? get currentRouteTag => Get.arguments?.toString();

/// Like [GetView], but finds the controller registered for *this* route's
/// argument. The same screen can then be stacked for different records
/// without one page reading another page's controller.
abstract class RouteView<T extends Object> extends StatelessWidget {
  const RouteView({super.key});

  @override
  Widget build(BuildContext context) =>
      buildWith(context, Get.find<T>(tag: routeTag(context)));

  Widget buildWith(BuildContext context, T controller);
}

/// This route's own argument, for screens that share an untagged
/// controller but show one record (a room, a box, a possession).
T routeArgument<T>(BuildContext context) =>
    ModalRoute.of(context)!.settings.arguments as T;
