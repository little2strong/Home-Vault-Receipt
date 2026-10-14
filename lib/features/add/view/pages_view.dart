import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/page_editor.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../controller/capture_flow.dart';

class PagesController extends GetxController {
  CaptureFlow get flow => CaptureFlow.to;
  List<DraftPage> get pages => flow.draft.pages;

  final selected = 0.obs;
  final working = false.obs;

  /// Crop per page path, as fractions; full page when absent.
  final crops = <String, Rect>{}.obs;

  /// Busts the image cache after a page file is rewritten.
  final revision = 0.obs;

  DraftPage? get current =>
      pages.isEmpty ? null : pages[selected.value.clamp(0, pages.length - 1)];

  Rect cropFor(DraftPage p) =>
      crops[p.localPath] ?? const Rect.fromLTWH(0, 0, 1, 1);

  void setCrop(Rect r) {
    final p = current;
    if (p != null) crops[p.localPath] = r;
  }

  Future<void> rotate() async {
    final p = current;
    if (p == null || working.value) return;
    working.value = true;
    final size = await PageEditor.rotate(p.localPath);
    final i = pages.indexOf(p);
    pages[i] = DraftPage(
      localPath: p.localPath,
      contentType: p.contentType,
      width: size.width,
      height: size.height,
    );
    crops.remove(p.localPath);
    imageCache.clear();
    revision.value++;
    flow.touch();
    working.value = false;
  }

  Future<void> autoCrop() async {
    final p = current;
    if (p == null || working.value) return;
    working.value = true;
    crops[p.localPath] = await PageEditor.autoBounds(p.localPath);
    working.value = false;
  }

  void delete() {
    final p = current;
    if (p == null) return;
    pages.remove(p);
    crops.remove(p.localPath);
    selected.value = selected.value.clamp(
      0,
      pages.isEmpty ? 0 : pages.length - 1,
    );
    flow.touch();
    if (pages.isEmpty) Get.back<void>();
  }

  void reorder(int from, int to) {
    final p = pages.removeAt(from);
    pages.insert(to, p);
    selected.value = to;
    flow.touch();
  }

  Future<void> addPage() async {
    if (pages.length >= Limits.receiptPages) {
      Toast.show('That is the most pages for one receipt.');
      return;
    }
    final capture = Get.find<CaptureService>();
    if (capture.hasDocumentScanner) {
      final more = await capture.scanDocument(flow.draft.id);
      pages.addAll(more);
      flow.touch();
    } else {
      await Get.toNamed(Routes.camera);
    }
    selected.value = pages.length - 1;
    revision.value++;
  }

  /// Applies crops, then reads the pages.
  Future<void> usePages() async {
    if (pages.isEmpty || working.value) return;
    working.value = true;
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      final r = crops[p.localPath];
      if (r == null || r == const Rect.fromLTWH(0, 0, 1, 1) || p.isPdf) {
        continue;
      }
      final size = await PageEditor.crop(p.localPath, r);
      pages[i] = DraftPage(
        localPath: p.localPath,
        contentType: p.contentType,
        width: size.width,
        height: size.height,
      );
    }
    crops.clear();
    imageCache.clear();
    flow.touch();
    working.value = false;
    await Get.offNamed(Routes.reading);
  }
}

/// 10 Crop and pages: adjust edges, rotate, reorder and delete pages.
class PagesView extends GetView<PagesController> {
  const PagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          controller.revision.value;
          final pages = controller.pages;
          final page = controller.current;
          final index = controller.selected.value;
          if (page == null) return const SizedBox();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (Get.find<CaptureService>().hasDocumentScanner) {
                          pages.clear();
                          controller.flow.touch();
                          Get.back<void>();
                          controller.flow.fromScanner();
                        } else {
                          Get.offNamed(Routes.camera);
                        }
                      },
                      child: const Text(
                        'Retake',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Adjust page ${index + 1} of ${pages.length}',
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.flow.discard(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pagePadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C312E),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _CropArea(
                      key: ValueKey(
                        '${page.localPath}-${controller.revision.value}',
                      ),
                      page: page,
                      crop: controller.cropFor(page),
                      onChanged: controller.setCrop,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tool(
                    Icons.rotate_right_rounded,
                    'Rotate',
                    controller.rotate,
                  ),
                  _Tool(Icons.crop_rounded, 'Auto crop', controller.autoCrop),
                  _Tool(
                    Icons.delete_outline_rounded,
                    'Delete',
                    controller.delete,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 112,
                child: Row(
                  children: [
                    const SizedBox(width: AppSizes.pagePadding),
                    Flexible(
                      child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        buildDefaultDragHandles: false,
                        itemCount: pages.length,
                        onReorderItem: controller.reorder,
                        itemBuilder: (context, i) =>
                            ReorderableDelayedDragStartListener(
                              key: ValueKey(pages[i].localPath),
                              index: i,
                              child: _Thumb(
                                page: pages[i],
                                number: i + 1,
                                selected: i == index,
                                onTap: () => controller.selected.value = i,
                              ),
                            ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Add a page',
                      child: InkWell(
                        onTap: controller.addPage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 76,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.muted),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: p.muted,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Long receipt? Add more pages. Drag to reorder.',
                        style: TextStyle(color: p.muted),
                      ),
                    ),
                    const SizedBox(width: AppSizes.pagePadding),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  12,
                  AppSizes.pagePadding,
                  16,
                ),
                child: VaultButton(
                  label: pages.length == 1
                      ? 'Use this page'
                      : 'Use ${pages.length} pages',
                  loading: controller.working.value,
                  onPressed: controller.usePages,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: Column(
        children: [
          Icon(icon, color: context.palette.ink),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.page,
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final DraftPage page;
  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Page $number',
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 76,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? p.primary : p.outline,
                width: selected ? 2.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!page.isPdf)
                  Image.file(
                    File(page.localPath),
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: p.surface.withValues(alpha: 0.85),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '$number',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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

/// Image with four draggable corner handles.
class _CropArea extends StatefulWidget {
  const _CropArea({
    super.key,
    required this.page,
    required this.crop,
    required this.onChanged,
  });

  final DraftPage page;
  final Rect crop;
  final ValueChanged<Rect> onChanged;

  @override
  State<_CropArea> createState() => _CropAreaState();
}

class _CropAreaState extends State<_CropArea> {
  late Rect _crop = widget.crop;

  @override
  void didUpdateWidget(_CropArea old) {
    super.didUpdateWidget(old);
    if (old.crop != widget.crop) _crop = widget.crop;
  }

  @override
  Widget build(BuildContext context) {
    final aspect = widget.page.width > 0 && widget.page.height > 0
        ? widget.page.width / widget.page.height
        : 0.6;
    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final r = Rect.fromLTRB(
              _crop.left * w,
              _crop.top * h,
              _crop.right * w,
              _crop.bottom * h,
            );
            Widget handle(Alignment corner) {
              final pos = Offset(
                corner.x < 0 ? r.left : r.right,
                corner.y < 0 ? r.top : r.bottom,
              );
              return Positioned(
                left: pos.dx - 24,
                top: pos.dy - 24,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) {
                    final x = ((pos.dx + d.delta.dx) / w).clamp(0.0, 1.0);
                    final y = ((pos.dy + d.delta.dy) / h).clamp(0.0, 1.0);
                    var c = _crop;
                    c = Rect.fromLTRB(
                      corner.x < 0 ? x.clamp(0.0, c.right - 0.1) : c.left,
                      corner.y < 0 ? y.clamp(0.0, c.bottom - 0.1) : c.top,
                      corner.x > 0 ? x.clamp(c.left + 0.1, 1.0) : c.right,
                      corner.y > 0 ? y.clamp(c.top + 0.1, 1.0) : c.bottom,
                    );
                    setState(() => _crop = c);
                  },
                  onPanEnd: (_) => widget.onChanged(_crop),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.palette.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: widget.page.isPdf
                      ? const ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: Icon(Icons.picture_as_pdf, size: 64),
                          ),
                        )
                      : Image.file(
                          File(widget.page.localPath),
                          fit: BoxFit.fill,
                        ),
                ),
                Positioned.fromRect(
                  rect: r,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6CC4A2),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!widget.page.isPdf) ...[
                  handle(Alignment.topLeft),
                  handle(Alignment.topRight),
                  handle(Alignment.bottomLeft),
                  handle(Alignment.bottomRight),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
