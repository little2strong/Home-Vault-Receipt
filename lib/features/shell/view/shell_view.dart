import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/app_page.dart';
import '../../account/view/account_view.dart';
import '../../add/view/add_sheet.dart';
import '../../home/view/home_view.dart';
import '../../products/view/products_view.dart';
import '../../warranties/view/warranties_view.dart';
import '../controller/shell_controller.dart';

/// Tab bar: Home, Products, the centre Add button, Warranties, Account.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(
      () => PopScope(
        canPop: controller.tab.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.tab.value = 0;
        },
        child: Scaffold(
          backgroundColor: p.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: IndexedStack(
                    index: controller.tab.value,
                    children: const [
                      HomeView(),
                      ProductsView(),
                      WarrantiesView(),
                      AccountView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _TabBar(controller: controller),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final ShellController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget tab(int index, IconData icon, IconData selectedIcon, String label) {
      final selected = controller.tab.value == index;
      final color = selected ? p.primary : p.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => controller.tab.value = index,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? selectedIcon : icon, color: color, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tab labels cap at 130% so the bar keeps its shape; screens scale
    // to 200%.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                tab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                tab(
                  1,
                  Icons.view_in_ar_outlined,
                  Icons.view_in_ar_rounded,
                  'Products',
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: Semantics(
                        button: true,
                        label: 'Add a receipt',
                        excludeSemantics: true,
                        child: Material(
                          color: p.primary,
                          elevation: 6,
                          shadowColor: p.primary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: AddSheet.open,
                            child: const SizedBox.square(
                              dimension: 68,
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                tab(
                  2,
                  Icons.shield_outlined,
                  Icons.shield_rounded,
                  'Warranties',
                ),
                tab(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
