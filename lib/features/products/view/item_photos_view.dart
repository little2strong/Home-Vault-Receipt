import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/image_tools.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/vault_ui.dart';

class ItemPhotosController extends GetxController {
  ItemPhotosController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;
  late final String id = Get.parameters['id'] ?? '';
  final photos = <ItemPhoto>[].obs;
  final uploading = RxnDouble();
  StreamSubscription<List<ItemPhoto>>? _sub;

  int get limit => Limits.photosPerItem;
  String get itemName => store.item(id)?.name ?? 'Item';

  @override
  void onInit() {
    super.onInit();
    _sub = repo.photos(id).listen(photos.assignAll, onError: (_) {});
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  static const suggestions = [
    'In the room',
    'Serial label',
    'Box and brand',
    'Close-up',
  ];

  /// Records how the photo was added, a fingerprint, and (by a Function)
  /// when it reached the server. GPS is removed unless the user opted in.
  Future<void> add({required bool camera, String? label}) async {
    if (photos.length >= limit) {
      Toast.show('Up to $limit photos per item.');
      return;
    }
    final x = await Get.find<CaptureService>().pickItemPhoto(camera: camera);
    if (x == null) return;
    uploading.value = 0;
    try {
      final keepGps = store.profile.value?.keepPhotoLocation ?? false;
      final prepared = await ImageTools.preparePhoto(
        await x.readAsBytes(),
        keepGps: keepGps,
      );
      await repo.addPhoto(
        itemId: id,
        jpeg: prepared.jpeg,
        source: camera ? PhotoSource.camera : PhotoSource.gallery,
        sha256: prepared.sha256,
        gpsKept: prepared.gpsKept,
        deviceTakenAt: camera ? DateTime.now() : prepared.takenAt,
        label:
            label ??
            suggestions[photos.length.clamp(0, suggestions.length - 1)],
        onProgress: (v) => uploading.value = v,
      );
      Toast.show('Photo added');
    } catch (_) {
      Toast.show(
        "The photo didn't upload. Check your connection and try again.",
      );
    } finally {
      uploading.value = null;
    }
  }

  Future<void> manage(BuildContext context, ItemPhoto photo) async {
    final action = await Pickers.choose<String>(
      context,
      title: photo.label ?? 'Photo',
      values: const ['view', 'label', 'delete'],
      label: (a) => switch (a) {
        'view' => 'View full size',
        'label' => 'Change label',
        _ => 'Delete photo',
      },
    );
    if (!context.mounted) return;
    switch (action) {
      case 'view':
        await Get.to<void>(
          () => _FullPhoto(photo: photo),
          fullscreenDialog: true,
        );
      case 'label':
        final l = await Pickers.text(
          context,
          title: 'Label',
          initial: photo.label,
        );
        if (l != null) {
          await repo.labelPhoto(
            id,
            photo.id,
            l.trim().isEmpty ? null : l.trim(),
          );
        }
      case 'delete':
        final ok = await Pickers.confirm(
          context,
          title: 'Delete this photo?',
          message: 'It is removed from Home Vault and its record is deleted.',
          action: 'Delete',
          destructive: true,
        );
        if (ok) {
          try {
            await repo.deletePhoto(id, photo.id);
          } catch (e) {
            Toast.show('$e');
          }
        }
    }
  }
}

/// 24 Item photos: gallery, add photos and evidence labels.
class ItemPhotosView extends GetView<ItemPhotosController> {
  const ItemPhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final photos = controller.photos;
      final full = photos.length >= controller.limit;
      return AppPage(
        eyebrow: controller.itemName,
        title: 'Photos · ${photos.length} of ${controller.limit}',
        actions: [
          Row(
            children: [
              Expanded(
                child: VaultButton(
                  label: 'Take photo',
                  loading: controller.uploading.value != null,
                  onPressed: full ? null : () => controller.add(camera: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VaultButton.secondary(
                  label: 'From gallery',
                  onPressed: full || controller.uploading.value != null
                      ? null
                      : () => controller.add(camera: false),
                ),
              ),
            ],
          ),
        ],
        children: [
          if (controller.uploading.value != null) ...[
            LinearProgressIndicator(value: controller.uploading.value),
            const SizedBox(height: 12),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.78,
            children: [
              for (final ph in photos)
                _PhotoCard(
                  photo: ph,
                  onTap: () => controller.manage(context, ph),
                ),
              if (!full)
                Semantics(
                  button: true,
                  label: 'Add photo',
                  child: InkWell(
                    onTap: () => controller.add(camera: true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.muted),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 36, color: p.ink),
                          const SizedBox(height: 8),
                          Text(
                            'Add photo',
                            style: context.textStyles.titleMedium,
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed(Routes.photoTips),
                            child: const Text('What to photograph'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const InfoNote(
            'How it was added, when it reached our server, and a fingerprint '
            "showing it hasn't changed since. Location is removed unless you "
            'turned on "Keep photo location".',
            title: 'What we record with each photo',
            icon: null,
          ),
        ],
      );
    });
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo, required this.onTap});

  final ItemPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return VaultCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: PrivateImage(
                path: photo.thumbPath ?? photo.path,
                semanticLabel: photo.label,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.label ?? 'Photo',
                  style: context.textStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.serverUploadedAt != null) ...[
                      Icon(Icons.check_rounded, size: 14, color: p.primary),
                      const SizedBox(width: 2),
                    ],
                    Expanded(
                      child: Text(
                        photo.serverUploadedAt == null
                            ? 'Uploading…'
                            : photo.provenance,
                        style: TextStyle(color: p.muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.photo});

  final ItemPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(photo.label ?? 'Photo'),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: PrivateImage(path: photo.path, fit: BoxFit.contain),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            [
              photo.provenance,
              if (photo.sha256 != null)
                'Fingerprint ${photo.sha256!.substring(0, 12)}…',
              photo.gpsKept ? 'Location kept' : 'Location removed',
            ].join('\n'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

/// 25 Photo tips: which shots help a claim. Never promises acceptance.
class PhotoTipsView extends StatelessWidget {
  const PhotoTipsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppPage(
      title: 'Photos that help a claim',
      subtitle:
          'Insurers usually want to see that you owned the item and what '
          'condition it was in. These four shots cover most claims.',
      actions: [VaultButton(label: 'Take photos', onPressed: Get.back)],
      children: [
        ListCard(
          indent: 70,
          children: [
            for (final (n, title, body) in const [
              (
                1,
                'The whole item, in its room',
                'Step back so the room is recognisable.',
              ),
              (
                2,
                'Serial or model label',
                'Usually on the back or underneath. Get it sharp.',
              ),
              (3, 'Brand name or logo', 'Shows make and model at a glance.'),
              (
                4,
                'Close-up of valuables',
                'Jewellery, art, watches: add any certificate or valuation too.',
              ),
            ])
              RowTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.tonal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: title,
                subtitle: body,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Your insurer decides what evidence it accepts. Check your policy for '
          'limits on single high-value items.',
          style: TextStyle(color: p.muted),
        ),
      ],
    );
  }
}
