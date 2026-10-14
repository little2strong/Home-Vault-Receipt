import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/file_store.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/item.dart';
import '../../../core/models/receipt.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../add/view/review_details_view.dart';

class OriginalViewerController extends GetxController {
  OriginalViewerController(this.store, this.files);

  final VaultStore store;
  final FileStore files;
  late final String id = Get.parameters['id'] ?? '';
  late final String? itemId = (Get.arguments is Map)
      ? (Get.arguments as Map)['itemId'] as String?
      : null;

  final pages = <Uint8List>[].obs;
  final loading = true.obs;
  final error = RxnString();
  final page = 0.obs;
  final turns = 0.obs;
  final transform = TransformationController();
  final pageController = PageController();
  PdfControllerPinch? pdf;

  Receipt? get receipt => store.receipt(id);
  Item? get item => itemId == null ? null : store.item(itemId!);
  LineBox? get box => item?.lineBox;

  @override
  void onReady() {
    super.onReady();
    _load();
  }

  /// The original loads only now, after the user asked to see it.
  Future<void> _load() async {
    await store.ready.future;
    final r = receipt;
    if (r == null || !r.hasOriginal) {
      loading.value = false;
      error.value = 'There is no stored original for this receipt.';
      return;
    }
    try {
      final data = <Uint8List>[];
      for (final path in r.originalPaths) {
        data.add(await files.getData(path));
      }
      if (r.isPdf) {
        pdf = PdfControllerPinch(document: PdfDocument.openData(data.first));
      }
      pages.assignAll(data);
      final b = box;
      if (b != null && !r.isPdf && b.page < data.length && b.page > 0) {
        page.value = b.page;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => pageController.jumpToPage(b.page),
        );
      }
    } catch (_) {
      error.value = "The original couldn't load. Check your connection.";
    } finally {
      loading.value = false;
    }
  }

  void zoom() {
    final zoomed = transform.value.getMaxScaleOnAxis() > 1.1;
    transform.value = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()..scaleByDouble(2.2, 2.2, 1, 1));
  }

  void nextPage() {
    if (receipt?.isPdf ?? false) {
      final c = pdf;
      if (c == null) return;
      final n = c.pagesCount ?? 1;
      c.jumpToPage(c.page % n + 1);
      return;
    }
    if (pages.length < 2) return;
    final next = (page.value + 1) % pages.length;
    pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// A copy the user keeps; Home Vault never shares it by itself.
  Future<void> saveCopy() async {
    final r = receipt;
    if (r == null || pages.isEmpty) return;
    final pdfFile = r.isPdf;
    final i = pdfFile ? 0 : page.value;
    final name = '${r.number}-${r.displayShop}'.replaceAll(
      RegExp(r'[^A-Za-z0-9\-]+'),
      '-',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            pages[i],
            mimeType: pdfFile ? 'application/pdf' : 'image/jpeg',
            name: pdfFile ? '$name.pdf' : '$name-${i + 1}.jpg',
          ),
        ],
        fileNameOverrides: [pdfFile ? '$name.pdf' : '$name-${i + 1}.jpg'],
      ),
    );
  }

  @override
  void onClose() {
    transform.dispose();
    pageController.dispose();
    pdf?.dispose();
    super.onClose();
  }
}

/// 23 Original viewer: zoom, rotate, pages, and the item's line marked.
class OriginalViewerView extends GetView<OriginalViewerController> {
  const OriginalViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.camera,
      body: SafeArea(
        child: Obx(() {
          final r = controller.receipt;
          final count = controller.receipt?.isPdf ?? false
              ? (controller.pdf?.pagesCount ?? 1)
              : controller.pages.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    SquareIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      dark: true,
                      onPressed: Get.back,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            r == null
                                ? 'Receipt'
                                : '${r.number} · ${r.displayShop}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (count > 0 && !(r?.isPdf ?? false))
                            Text(
                              'Page ${controller.page.value + 1} of $count',
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              Expanded(child: _body(context)),
              if (controller.item != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.box == null
                        ? '${controller.item!.name} · line position not recorded'
                        : 'Highlighted: ${controller.item!.name}',
                    style: const TextStyle(
                      color: Color(0xFFBFE8D5),
                      fontSize: 16,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Tool(Icons.zoom_in_rounded, 'Zoom', controller.zoom),
                    _Tool(
                      Icons.rotate_left_rounded,
                      'Rotate',
                      () => controller.turns.value =
                          (controller.turns.value + 1) % 4,
                    ),
                    if (count > 1)
                      _Tool(
                        Icons.chevron_right_rounded,
                        'Next page',
                        controller.nextPage,
                      ),
                    _Tool(
                      Icons.download_rounded,
                      'Save copy',
                      controller.saveCopy,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.loading.value) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          semanticsLabel: 'Loading the original',
        ),
      );
    }
    if (controller.error.value != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            controller.error.value!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ),
      );
    }
    final pdf = controller.pdf;
    if (pdf != null) {
      return RotatedBox(
        quarterTurns: controller.turns.value,
        child: PdfViewPinch(controller: pdf),
      );
    }
    final box = controller.box;
    return PageView.builder(
      controller: controller.pageController,
      itemCount: controller.pages.length,
      onPageChanged: (i) {
        controller.page.value = i;
        controller.transform.value = Matrix4.identity();
      },
      itemBuilder: (_, i) => InteractiveViewer(
        transformationController: controller.transform,
        maxScale: 6,
        child: Center(
          child: RotatedBox(
            quarterTurns: controller.turns.value,
            child: _PageImage(
              bytes: controller.pages[i],
              highlight: box != null && box.page == i ? box : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageImage extends StatelessWidget {
  const _PageImage({required this.bytes, this.highlight});

  final Uint8List bytes;
  final LineBox? highlight;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(bytes, semanticLabel: 'Original receipt');
    if (highlight == null) return image;
    return Stack(
      children: [
        image,
        Positioned.fill(child: LineHighlight(box: highlight!)),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: () async {
        try {
          onTap();
        } catch (_) {
          Toast.show('That did not work.');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
