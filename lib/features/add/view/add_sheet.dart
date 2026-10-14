import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/enums.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/feedback.dart';
import '../controller/capture_flow.dart';

/// 08 Add sheet. Camera is the first option: two taps to the camera.
class AddSheet extends StatelessWidget {
  const AddSheet({super.key});

  static Future<void> open() => SheetFrame.show<void>(const AddSheet());

  Future<void> _go(Future<void> Function() action) async {
    Get.back<void>();
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = Get.find<CaptureService>().hasDocumentScanner;
    return SheetFrame(
      title: 'Add a receipt',
      trailing: const SheetClose(),
      children: [
        _Option(
          icon: Icons.photo_camera_outlined,
          title: 'Scan with camera',
          subtitle: 'Best for paper receipts',
          primary: true,
          onTap: () => _go(() async {
            final flow = CaptureFlow.begin(ReceiptSource.camera);
            if (scanner) {
              await flow.fromScanner();
            } else {
              await Get.toNamed(Routes.camera);
            }
          }),
        ),
        _Option(
          icon: Icons.image_outlined,
          title: 'Choose a photo',
          subtitle: 'A photo or screenshot you already have',
          onTap: () =>
              _go(() => CaptureFlow.begin(ReceiptSource.photo).fromPhotos()),
        ),
        _Option(
          icon: Icons.insert_drive_file_outlined,
          title: 'Import a PDF',
          subtitle: 'Online orders and emailed invoices',
          onTap: () =>
              _go(() => CaptureFlow.begin(ReceiptSource.pdf).fromPdf()),
        ),
        _Option(
          icon: Icons.edit_outlined,
          title: 'Type it in',
          subtitle: 'No receipt to scan',
          onTap: () => _go(() async {
            CaptureFlow.begin(ReceiptSource.manual);
            await Get.toNamed(Routes.manual);
          }),
        ),
        _Option(
          icon: Icons.view_in_ar_outlined,
          title: 'Add something I already own',
          subtitle: 'Older items, for your home inventory',
          onTap: () => _go(() async => Get.toNamed(Routes.addItem)),
        ),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: primary ? p.tonal : p.background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primary ? p.primary : p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: primary ? null : Border.all(color: p.outline),
                  ),
                  child: Icon(
                    icon,
                    color: primary ? Colors.white : p.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
