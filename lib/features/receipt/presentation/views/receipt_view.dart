import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/message_view.dart';
import '../controllers/receipt_controller.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/receipt_card.dart';
import '../widgets/receipt_summary_card.dart';

class ReceiptView extends GetView<ReceiptController> {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myReceipts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openAddReceipt,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addReceipt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              AppSizes.md,
            ),
            child: Obx(
              () => ReceiptSummaryCard(
                totalAmount: controller.totalAmount,
                count: controller.filteredReceipts.length,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: const InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Obx(
            () => CategoryFilterBar(
              selected: controller.selectedCategory.value,
              onSelected: controller.selectCategory,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Expanded(child: Obx(_buildBody)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value && controller.receipts.isEmpty) {
      return const AppLoader();
    }

    final error = controller.errorMessage.value;
    if (error != null) {
      return MessageView(
        icon: Icons.error_outline_rounded,
        title: AppStrings.error,
        message: error,
        actionLabel: AppStrings.retry,
        onAction: controller.fetchReceipts,
      );
    }

    final receipts = controller.filteredReceipts;
    if (receipts.isEmpty) {
      return controller.hasActiveFilter
          ? const MessageView(
              icon: Icons.search_off_rounded,
              title: AppStrings.noMatchesTitle,
              message: AppStrings.noMatchesMessage,
            )
          : const MessageView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noReceiptsTitle,
              message: AppStrings.noReceiptsMessage,
            );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchReceipts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.sm,
          AppSizes.md,
          96,
        ),
        itemCount: receipts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (_, index) {
          final receipt = receipts[index];
          return ReceiptCard(
            receipt: receipt,
            onDelete: () => controller.removeReceipt(receipt),
          );
        },
      ),
    );
  }
}
