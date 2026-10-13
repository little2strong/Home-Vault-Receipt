import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/possession_detail_controller.dart';

/// 58 · Item gallery
class ItemGalleryView extends RouteView<PossessionDetailController> {
  const ItemGalleryView({super.key});

  @override
  Widget buildWith(
    BuildContext context,
    PossessionDetailController controller,
  ) {
    final p = context.palette;
    return Obx(() {
      final photos = controller.possession?.photos ?? const [];
      return VaultPage(
        title: 'Every useful angle.',
        subtitle: 'Product, condition and ownership evidence.',
        roadmap: true,
        actions: [
          VaultButton(label: 'Add photo', onPressed: controller.addPhoto),
        ],
        children: [
          if (photos.isEmpty)
            Text('No photos yet.', style: context.textStyles.bodyMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              for (final label in photos)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: p.tonal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            color: p.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: context.textStyles.labelMedium?.copyWith(
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
