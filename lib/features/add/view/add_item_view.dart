import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/parsing/receipt_parser.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/image_tools.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';

class PendingPhoto {
  PendingPhoto(this.bytes, this.source, this.label);

  final Uint8List bytes;
  final PhotoSource source;
  String label;
}

class AddItemController extends GetxController {
  AddItemController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;

  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final year = TextEditingController();
  final price = TextEditingController();
  final roomId = RxnString();
  final photos = <PendingPhoto>[].obs;
  final saving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String) roomId.value = arg;
  }

  String get roomName =>
      store.room(roomId.value ?? '')?.name ?? 'Choose a room';

  Future<void> addPhoto(BuildContext context) async {
    final camera = await Pickers.choose<bool>(
      context,
      title: 'Add a photo',
      values: const [true, false],
      label: (c) => c ? 'Take a photo' : 'Choose from gallery',
    );
    if (camera == null) return;
    final x = await Get.find<CaptureService>().pickItemPhoto(camera: camera);
    if (x == null) return;
    photos.add(
      PendingPhoto(
        await x.readAsBytes(),
        camera ? PhotoSource.camera : PhotoSource.gallery,
        photos.isEmpty ? 'Item' : (photos.length == 1 ? 'Label' : 'Photo'),
      ),
    );
  }

  Future<void> pickRoom(BuildContext context) async {
    if (store.rooms.isEmpty) {
      await Get.toNamed(Routes.homeSetup);
      if (store.rooms.isEmpty || !context.mounted) return;
    }
    final id = await Pickers.room(
      context,
      rooms: store.rooms,
      selected: roomId.value,
      onSetUp: () => Get.toNamed(Routes.homeSetup),
    );
    if (id != null) roomId.value = id;
  }

  /// Needs a name, a room and at least a photo or an estimated price.
  Future<void> save() async {
    final n = name.text.trim();
    final estimate = Money.parse(price.text);
    if (n.isEmpty) return _fail('Say what the item is.');
    if (roomId.value == null) return _fail('Choose which room it is in.');
    if (photos.isEmpty && estimate == null) {
      return _fail('Add a photo or your best guess at the price.');
    }
    error.value = null;
    saving.value = true;
    try {
      final quantity = (int.tryParse(qty.text.trim()) ?? 1).clamp(1, 999);
      final y = int.tryParse(year.text.trim());
      final id = await repo.addItemWithoutReceipt(
        name: n,
        category: ReceiptParser.guessCategory(n),
        roomId: roomId.value!,
        quantity: quantity,
        currency: store.profile.value?.mainCurrency ?? 'GBP',
        estimateMinor: estimate,
        yearBought: y != null && y > 1900 && y <= DateTime.now().year
            ? y
            : null,
      );
      final keepGps = store.profile.value?.keepPhotoLocation ?? false;
      for (final ph in photos) {
        final prepared = await ImageTools.preparePhoto(
          ph.bytes,
          keepGps: keepGps,
        );
        await repo.addPhoto(
          itemId: id,
          jpeg: prepared.jpeg,
          source: ph.source,
          sha256: prepared.sha256,
          gpsKept: prepared.gpsKept,
          deviceTakenAt: prepared.takenAt,
          label: ph.label,
        );
      }
      Get.back<void>();
      Toast.show('Saved to $roomName');
    } catch (e) {
      _fail("That didn't save. Check your connection and try again.");
    } finally {
      saving.value = false;
    }
  }

  void _fail(String message) => error.value = message;

  @override
  void onClose() {
    name.dispose();
    qty.dispose();
    year.dispose();
    price.dispose();
    super.onClose();
  }
}

/// 18 Add item without receipt: older belongings with a photo and estimate.
class AddItemView extends GetView<AddItemController> {
  const AddItemView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(
      () => AppPage(
        title: 'Add something you own',
        subtitle:
            "No receipt? Add a photo and your best estimate so it's on your "
            'home inventory.',
        actions: [
          VaultButton(
            label: controller.roomId.value == null
                ? 'Save'
                : 'Save to ${controller.roomName}',
            loading: controller.saving.value,
            onPressed: controller.save,
          ),
        ],
        children: [
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final ph in controller.photos)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              ph.bytes,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                            ),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ph.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                tooltip: 'Remove photo',
                                onPressed: () => controller.photos.remove(ph),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Semantics(
                  button: true,
                  label: 'Add photo',
                  child: InkWell(
                    onTap: () => controller.addPhoto(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.muted),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined),
                          SizedBox(height: 6),
                          Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          LabeledField(
            label: 'What is it?',
            controller: controller.name,
            hint: 'e.g. Oak sideboard',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: PickerField(
                  label: 'Room',
                  value: controller.roomId.value == null
                      ? null
                      : controller.roomName,
                  placeholder: 'Choose a room',
                  onTap: () => controller.pickRoom(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LabeledField(
                  label: 'Quantity',
                  controller: controller.qty,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Year bought (about)',
                  controller: controller.year,
                  hint: 'e.g. 2019',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LabeledField(
                  label: 'Price paid (about)',
                  controller: controller.price,
                  prefix: Money.symbolFor(
                    controller.store.profile.value?.mainCurrency ?? 'GBP',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const InfoNote(
            "Shown as an estimate on your inventory, so an insurer knows "
            "there's no receipt.",
          ),
          if (controller.error.value != null) ...[
            const SizedBox(height: 12),
            InfoNote(
              controller.error.value!,
              warning: true,
              icon: Icons.error_outline,
            ),
          ],
        ],
      ),
    );
  }
}
