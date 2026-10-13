import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../dashboard/view/dashboard_view.dart';
import '../../receipts/view/receipts_view.dart';
import '../../settings/view/settings_view.dart';
import '../controller/shell_controller.dart';

/// Home / Receipts / More. Navigation stays this small on purpose; future
/// ownership tools sit behind More.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.current.value;
      return Scaffold(
        body: IndexedStack(
          index: tab.index,
          children: const [DashboardView(), ReceiptsView(), SettingsView()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (i) => controller.select(ShellTab.values[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: AppStrings.home,
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: AppStrings.receipts,
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: AppStrings.more,
            ),
          ],
        ),
      );
    });
  }
}
