import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 15 · Add source
class AddSourceView extends GetView<CaptureController> {
  const AddSourceView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Icon icon(IconData data) => Icon(data, color: p.primary);

    return VaultPage(
      title: 'Add a receipt',
      subtitle: 'Choose what you have.',
      children: [
        InfoCard(
          leading: icon(Icons.photo_camera_outlined),
          title: 'Camera',
          subtitle: 'Photograph a paper receipt.',
          onTap: controller.chooseCamera,
        ),
        InfoCard(
          leading: icon(Icons.photo_library_outlined),
          title: 'Photos',
          subtitle: 'Import a photo or screenshot.',
          onTap: controller.choosePhotos,
        ),
        InfoCard(
          leading: icon(Icons.picture_as_pdf_outlined),
          title: 'PDF invoice',
          subtitle: 'Import up to 20 pages.',
          onTap: controller.choosePdf,
        ),
        InfoCard(
          leading: icon(Icons.edit_note_rounded),
          title: 'Manual entry',
          subtitle: 'Save a record without scanning.',
          onTap: controller.chooseManual,
        ),
        const SizedBox(height: 12),
        Text(
          'Images and PDFs · review before saving',
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}
