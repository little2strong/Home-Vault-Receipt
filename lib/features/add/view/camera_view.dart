import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../controller/capture_flow.dart';

class CameraCaptureController extends GetxController
    with WidgetsBindingObserver {
  CameraController? camera;
  final ready = false.obs;
  final torch = false.obs;
  final capturing = false.obs;
  final error = RxnString();
  final pageCount = 0.obs;

  CaptureFlow get flow => CaptureFlow.to;
  bool get hasScanner => Get.find<CaptureService>().hasDocumentScanner;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    pageCount.value = flow.draft.pages.length;
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      await c.setFlashMode(FlashMode.off);
      camera = c;
      ready.value = true;
    } on CameraException catch (e) {
      error.value = e.code == 'CameraAccessDenied'
          ? 'Home Vault needs the camera to scan receipts. Turn it on in '
                'Settings, or choose a photo instead.'
          : 'The camera could not start.';
    } catch (_) {
      error.value = 'The camera could not start.';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = camera;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ready.value = false;
      camera = null;
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_start());
    }
  }

  Future<void> toggleTorch() async {
    final c = camera;
    if (c == null) return;
    torch.toggle();
    try {
      await c.setFlashMode(torch.value ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      torch.value = false;
    }
  }

  Future<void> shoot() async {
    final c = camera;
    if (c == null || capturing.value) return;
    if (flow.draft.pages.length >= Limits.receiptPages) {
      Toast.show('That is the most pages for one receipt.');
      return;
    }
    capturing.value = true;
    try {
      HapticFeedback.mediumImpact();
      final shot = await c.takePicture();
      final page = await Get.find<CaptureService>().keepImage(
        flow.draft.id,
        File(shot.path),
      );
      flow.draft.pages.add(page);
      flow.touch();
      pageCount.value = flow.draft.pages.length;
      Toast.show(
        'Page ${pageCount.value} added. Long receipt? Add the next part.',
      );
    } catch (_) {
      Toast.show('That photo did not work. Try again.');
    } finally {
      capturing.value = false;
    }
  }

  Future<void> useScanner() async {
    await _stop();
    await flow.fromScanner();
  }

  void done() {
    if (flow.draft.pages.isEmpty) return;
    Get.offNamed(Routes.pages);
  }

  Future<void> close() async {
    if (flow.draft.pages.isEmpty) {
      flow.end();
      Get.back<void>();
    } else {
      Get.offNamed(Routes.pages);
    }
  }

  Future<void> _stop() async {
    final c = camera;
    camera = null;
    ready.value = false;
    await c?.dispose();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    camera?.dispose();
    super.onClose();
  }
}

/// 09 Camera capture: torch, multi-page and a hint to use a dark, flat
/// surface. On Android "Auto" hands over to ML Kit's document scanner for
/// automatic edge detection and auto-capture.
class CameraView extends GetView<CameraCaptureController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.camera,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close camera',
                    dark: true,
                    onPressed: controller.close,
                  ),
                  const Spacer(),
                  if (controller.hasScanner)
                    _ModeToggle(onAuto: controller.useScanner),
                  const Spacer(),
                  Obx(
                    () => SquareIconButton(
                      icon: controller.torch.value
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      tooltip: controller.torch.value
                          ? 'Turn torch off'
                          : 'Turn torch on',
                      dark: true,
                      onPressed: controller.toggleTorch,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.error.value != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.error.value!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 20),
                          VaultButton(
                            label: 'Choose a photo instead',
                            expand: false,
                            onPressed: () {
                              Get.back<void>();
                              controller.flow.fromPhotos();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final c = controller.camera;
                if (!controller.ready.value || c == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: c.value.previewSize?.height ?? 1080,
                          height: c.value.previewSize?.width ?? 1920,
                          child: CameraPreview(c),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.78,
                          heightFactor: 0.86,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF6CC4A2),
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Lay it flat on a dark surface · fill the frame',
                style: TextStyle(
                  color: Color(0xFFBFE8D5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
              child: Row(
                children: [
                  Obx(
                    () => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Page\n${controller.pageCount.value + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => Semantics(
                      button: true,
                      label: 'Take photo of page',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: controller.capturing.value
                            ? null
                            : controller.shoot,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.capturing.value
                                  ? Colors.white54
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => SizedBox(
                      width: 88,
                      child: VaultButton(
                        label: 'Done',
                        onPressed: controller.pageCount.value == 0
                            ? null
                            : controller.done,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.onAuto});

  final VoidCallback onAuto;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool selected, VoidCallback? onTap) => Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.ink : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('Auto', false, onAuto), seg('Manual', true, null)],
      ),
    );
  }
}
