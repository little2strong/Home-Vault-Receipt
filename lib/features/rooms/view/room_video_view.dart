import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/file_store.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';

enum VideoMode { loading, playing, ready, recording, review, uploading }

class RoomVideoController extends GetxController {
  RoomVideoController(this.store, this.repo, this.files);

  final VaultStore store;
  final VaultRepository repo;
  final FileStore files;
  late final String roomId = Get.parameters['id'] ?? '';

  final mode = VideoMode.loading.obs;
  final seconds = 0.obs;
  final progress = 0.0.obs;
  final error = RxnString();
  CameraController? camera;
  VideoPlayerController? player;
  String? recordedPath;
  Timer? _timer;

  int get limit => Limits.roomVideoSeconds;
  String get roomName => store.room(roomId)?.name ?? 'Room';

  @override
  void onReady() {
    super.onReady();
    final room = store.room(roomId);
    if (room?.videoPath != null) {
      _play(room!.videoPath!);
    } else {
      _startCamera();
    }
  }

  /// Plays the stored walkthrough; it downloads only now, on request.
  Future<void> _play(String path) async {
    mode.value = VideoMode.loading;
    try {
      final dir = await getTemporaryDirectory();
      final local = '${dir.path}/room-$roomId.mp4';
      await files.downloadToFile(path, local);
      await _setPlayer(local);
      mode.value = VideoMode.playing;
    } catch (_) {
      error.value = "The video couldn't load. Check your connection.";
      mode.value = VideoMode.playing;
    }
  }

  Future<void> _setPlayer(String local) async {
    await player?.dispose();
    final p = VideoPlayerController.file(File(local));
    await p.initialize();
    await p.setLooping(true);
    await p.play();
    player = p;
  }

  Future<void> _startCamera() async {
    mode.value = VideoMode.loading;
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      // 720p keeps a two-minute walkthrough small enough to upload.
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      camera = c;
      mode.value = VideoMode.ready;
    } catch (_) {
      error.value = 'The camera could not start. Check Home Vault can use it.';
      mode.value = VideoMode.ready;
    }
  }

  Future<void> recordNew() async {
    await player?.pause();
    error.value = null;
    await _startCamera();
  }

  Future<void> start() async {
    final c = camera;
    if (c == null) return;
    await c.startVideoRecording();
    seconds.value = 0;
    mode.value = VideoMode.recording;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds.value++;
      if (seconds.value >= limit) stop();
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    final c = camera;
    if (c == null || !c.value.isRecordingVideo) return;
    final file = await c.stopVideoRecording();
    recordedPath = file.path;
    await c.dispose();
    camera = null;
    await _setPlayer(file.path);
    mode.value = VideoMode.review;
  }

  Future<void> upload() async {
    final path = recordedPath;
    if (path == null) return;
    mode.value = VideoMode.uploading;
    try {
      await repo.uploadRoomVideo(
        roomId: roomId,
        mp4: await File(path).readAsBytes(),
        seconds: seconds.value,
        onProgress: (v) => progress.value = v,
      );
      Toast.show('Walkthrough saved for $roomName');
      Get.back<void>();
    } catch (_) {
      Toast.show("The video didn't upload. Try again on Wi-Fi.");
      mode.value = VideoMode.review;
    }
  }

  Future<void> deleteVideo(BuildContext context) async {
    final ok = await Pickers.confirm(
      context,
      title: 'Delete this walkthrough?',
      message: 'The video is removed from Home Vault.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await repo.deleteRoomVideo(roomId);
      Get.back<void>();
    } catch (e) {
      Toast.show('$e');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    camera?.dispose();
    player?.dispose();
    super.onClose();
  }
}

/// 29 Room video: record or play a room walkthrough (up to 2 minutes).
class RoomVideoView extends GetView<RoomVideoController> {
  const RoomVideoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.camera,
      body: SafeArea(
        child: Obx(() {
          final mode = controller.mode.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              _preview(mode),
              Positioned(
                left: 20,
                right: 20,
                top: 16,
                child: Row(
                  children: [
                    SquareIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      dark: true,
                      onPressed: Get.back,
                    ),
                    const Spacer(),
                    if (mode == VideoMode.recording)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerInk,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '● ${Formatters.clock(controller.seconds.value)} / ${Formatters.clock(controller.limit)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              if (mode == VideoMode.ready || mode == VideoMode.recording)
                Positioned(
                  left: 20,
                  right: 20,
                  top: 90,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${controller.roomName}. ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(
                            text:
                                'Walk slowly around the room. Pause on valuable '
                                'items and open cupboards.',
                          ),
                        ],
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 20,
                child: _controls(context, mode),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _preview(VideoMode mode) {
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
    switch (mode) {
      case VideoMode.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case VideoMode.ready:
      case VideoMode.recording:
        final c = controller.camera;
        if (c == null) return const SizedBox();
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.previewSize?.height ?? 720,
              height: c.value.previewSize?.width ?? 1280,
              child: CameraPreview(c),
            ),
          ),
        );
      case VideoMode.playing:
      case VideoMode.review:
      case VideoMode.uploading:
        final p = controller.player;
        if (p == null || !p.value.isInitialized) return const SizedBox();
        return Center(
          child: AspectRatio(
            aspectRatio: p.value.aspectRatio,
            child: VideoPlayer(p),
          ),
        );
    }
  }

  Widget _controls(BuildContext context, VideoMode mode) {
    switch (mode) {
      case VideoMode.ready:
      case VideoMode.recording:
        final recording = mode == VideoMode.recording;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: recording ? 'Stop recording' : 'Start recording',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: recording ? controller.stop : controller.start,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: recording ? 36 : 72,
                    height: recording ? 36 : 72,
                    decoration: BoxDecoration(
                      color: AppColors.dangerInk,
                      borderRadius: BorderRadius.circular(recording ? 8 : 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Recorded at 720p · location not kept',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );
      case VideoMode.review:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VaultButton(label: 'Use this video', onPressed: controller.upload),
            const SizedBox(height: 12),
            VaultButton.secondary(
              label: 'Record again',
              onPressed: controller.recordNew,
            ),
          ],
        );
      case VideoMode.uploading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: controller.progress.value),
            const SizedBox(height: 10),
            const Text(
              'Uploading privately…',
              style: TextStyle(color: Colors.white),
            ),
          ],
        );
      case VideoMode.playing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VaultButton(
              label: 'Record a new walkthrough',
              onPressed: controller.recordNew,
            ),
            const SizedBox(height: 4),
            LinkButton(
              label: 'Delete this video',
              color: Colors.white,
              onPressed: () => controller.deleteVideo(context),
            ),
          ],
        );
      case VideoMode.loading:
        return const SizedBox();
    }
  }
}
