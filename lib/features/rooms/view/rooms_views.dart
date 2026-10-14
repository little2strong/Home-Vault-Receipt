import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/item.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/item_rows.dart';
import '../../../core/widgets/vault_ui.dart';

class HomeSetupController extends GetxController {
  HomeSetupController(this.repo);

  final VaultRepository repo;
  final counts = {
    for (final t in RoomType.values)
      if (t != RoomType.custom) t: t.defaultCount,
  }.obs;
  final custom = <String>[].obs;
  final saving = false.obs;

  int get total => counts.values.fold(0, (a, b) => a + b) + custom.length;

  Future<void> addCustom(BuildContext context) async {
    final name = await Pickers.text(
      context,
      title: 'Add a different room',
      hint: 'e.g. Utility room',
      action: 'Add',
      caps: TextCapitalization.words,
    );
    if (name != null && name.trim().isNotEmpty) custom.add(name.trim());
  }

  Future<void> create() async {
    if (total == 0) return;
    saving.value = true;
    try {
      await repo.createRooms([
        for (final e in counts.entries)
          for (var i = 1; i <= e.value; i++)
            (
              type: e.key,
              name: e.value == 1 ? e.key.label : '${e.key.label} $i',
            ),
        for (final c in custom) (type: RoomType.custom, name: c),
      ]);
      Get.back<void>();
    } catch (_) {
      Toast.show("Rooms weren't created. Check your connection and try again.");
    } finally {
      saving.value = false;
    }
  }
}

/// 26 Home setup — asked the first time an item is placed in a room.
class HomeSetupView extends GetView<HomeSetupController> {
  const HomeSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppPage(
        title: 'Which rooms do you have?',
        subtitle:
            'So you can say where things are. You can rename or add rooms any time.',
        titleInHeader: false,
        trailing: TextButton(
          onPressed: Get.back,
          child: const Text('Skip', style: TextStyle(fontSize: 17)),
        ),
        actions: [
          VaultButton(
            label: controller.total == 0
                ? 'Choose at least one room'
                : 'Create ${Formatters.count(controller.total, 'room')}',
            loading: controller.saving.value,
            onPressed: controller.total == 0 ? null : controller.create,
          ),
        ],
        children: [
          ListCard(
            children: [
              for (final e in controller.counts.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key.label,
                          style: context.textStyles.titleMedium,
                        ),
                      ),
                      Counter(
                        value: e.value,
                        label: e.key.label,
                        onChanged: (v) => controller.counts[e.key] = v,
                      ),
                    ],
                  ),
                ),
              for (final c in controller.custom)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c, style: context.textStyles.titleMedium),
                      ),
                      IconButton(
                        tooltip: 'Remove $c',
                        onPressed: () => controller.custom.remove(c),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => controller.addCustom(context),
              child: const Text(
                '+ Add a different room',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomsController extends GetxController {
  RoomsController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;

  Future<void> editRooms(BuildContext context) async {
    final action = await Pickers.choose<String>(
      context,
      title: 'Edit rooms',
      values: ['add', for (final r in store.rooms) r.id],
      label: (v) => v == 'add'
          ? '+ Add a room'
          : 'Rename or remove ${store.room(v)!.name}',
    );
    if (action == null || !context.mounted) return;
    if (action == 'add') {
      final name = await Pickers.text(
        context,
        title: 'New room',
        hint: 'e.g. Spare room',
        action: 'Add',
        caps: TextCapitalization.words,
      );
      if (name != null && name.trim().isNotEmpty) {
        await repo.createRooms([(type: RoomType.custom, name: name.trim())]);
      }
      return;
    }
    await manageRoom(context, store.room(action)!);
  }

  Future<void> manageRoom(BuildContext context, Room room) async {
    final choice = await Pickers.choose<String>(
      context,
      title: room.name,
      values: const ['rename', 'delete'],
      label: (v) => v == 'rename' ? 'Rename' : 'Remove this room',
    );
    if (!context.mounted) return;
    if (choice == 'rename') {
      final name = await Pickers.text(
        context,
        title: 'Rename room',
        initial: room.name,
        caps: TextCapitalization.words,
      );
      if (name != null && name.trim().isNotEmpty) {
        await repo.renameRoom(room.id, name);
      }
    } else if (choice == 'delete') {
      final n = store.itemCountInRoom(room.id);
      final ok = await Pickers.confirm(
        context,
        title: 'Remove ${room.name}?',
        message: n == 0
            ? 'The room and its walkthrough video are removed.'
            : 'Its ${Formatters.count(n, 'item')} stay in Home Vault with no room set. '
                  'Its walkthrough video is deleted.',
        action: 'Remove',
        destructive: true,
      );
      if (!ok) return;
      try {
        await repo.deleteRoom(room.id);
        if (Get.currentRoute.startsWith('/room/')) Get.back<void>();
      } catch (e) {
        Toast.show('$e');
      }
    }
  }
}

/// 27 Rooms: the home inventory by room with totals.
class RoomsView extends GetView<RoomsController> {
  const RoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final store = controller.store;
      final rooms = store.rooms;
      final inv = store.inventory;
      final main = store.profile.value?.mainCurrency ?? 'GBP';
      final noRoom = inv.where((i) => i.allocations.isEmpty).toList();
      final noPhoto = store.highValueWithoutPhoto;
      return AppPage(
        title: 'Home inventory',
        trailing: rooms.isEmpty
            ? null
            : TextButton(
                onPressed: () => controller.editRooms(context),
                child: const Text('Edit rooms', style: TextStyle(fontSize: 17)),
              ),
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paid for items in your home',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          moneyTotals(store.inventoryTotals(), main: main),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${Formatters.count(inv.length, 'item')} · ${Formatters.count(rooms.length, 'room')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Get.toNamed(
                    Routes.export,
                    arguments: ExportKind.inventory,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download for insurer'),
                ),
              ],
            ),
          ),
          if (noPhoto.isNotEmpty) ...[
            const SizedBox(height: 14),
            InfoNote(
              '${Formatters.count(noPhoto.length, 'high-value item')} '
              '${noPhoto.length == 1 ? 'has' : 'have'} no photo',
              icon: Icons.photo_camera_outlined,
              warning: true,
              onTap: () => Get.toNamed(Routes.photos(noPhoto.first.id)),
            ),
          ],
          const SizedBox(height: 14),
          if (rooms.isEmpty)
            EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'Set up your rooms',
              message:
                  'Say which rooms you have, then put items in them for a '
                  'room-by-room list.',
              action: VaultButton(
                label: 'Set up rooms',
                expand: false,
                onPressed: () => Get.toNamed(Routes.homeSetup),
              ),
            )
          else
            TwoColumn(
              children: [
                for (final r in rooms)
                  _RoomCard(
                    icon: r.type.icon,
                    name: r.name,
                    line: [
                      Formatters.count(store.itemCountInRoom(r.id), 'item'),
                      if (r.hasVideo) 'video',
                    ].join(' · '),
                    total: moneyTotals(store.inventoryTotals(r.id), main: main),
                    onTap: () => Get.toNamed(Routes.room(r.id)),
                  ),
              ],
            ),
          if (noRoom.isNotEmpty) ...[
            const SectionLabel('No room yet'),
            ListCard(
              indent: 82,
              children: [for (final i in noRoom) ItemRow(i)],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Prices are what you paid, not replacement value. Your insurer '
            'decides what is covered.',
            style: TextStyle(color: p.muted),
          ),
        ],
      );
    });
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.icon,
    required this.name,
    required this.line,
    required this.total,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final String line;
  final String total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VaultCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 44),
          const SizedBox(height: 18),
          Text(
            name,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(line, style: TextStyle(color: context.palette.muted)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// 28 Room detail: items in one room and its walkthrough video.
class RoomDetailView extends GetView<RoomsController> {
  const RoomDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'] ?? '';
    final p = context.palette;
    return Obx(() {
      final store = controller.store;
      final room = store.room(id);
      if (room == null) {
        return const AppPage(
          title: 'Room',
          children: [
            EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'This room is no longer here',
              message: 'It may have been removed on another device.',
            ),
          ],
        );
      }
      final items = store.itemsInRoom(id);
      final main = store.profile.value?.mainCurrency ?? 'GBP';
      return AppPage(
        title: room.name,
        trailing: IconButton(
          tooltip: 'Room options',
          onPressed: () => controller.manageRoom(context, room),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        children: [
          Text(
            '${Formatters.count(items.length, 'item')} · '
            '${moneyTotals(store.inventoryTotals(id), main: main)} paid',
            style: TextStyle(color: p.muted, fontSize: 16),
          ),
          const SizedBox(height: 16),
          VaultCard(
            onTap: () => Get.toNamed(Routes.roomVideo(id)),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F6A66),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        room.hasVideo
                            ? Icons.play_arrow_rounded
                            : Icons.videocam_outlined,
                        color: p.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room walkthrough',
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        room.hasVideo
                            ? [
                                if (room.videoSeconds != null)
                                  Formatters.duration(room.videoSeconds!),
                                if (room.videoUploadedAt != null)
                                  Formatters.medium(room.videoUploadedAt!),
                              ].join(' · ')
                            : 'Record a slow walk around the room',
                        style: TextStyle(color: p.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (items.isNotEmpty)
            ListCard(
              indent: 82,
              children: [
                for (final i in items) _RoomItemRow(item: i, roomId: id),
              ],
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Get.toNamed(Routes.addItem, arguments: id),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              foregroundColor: p.ink,
              side: BorderSide(color: p.muted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '+ Add something to this room',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    });
  }
}

class _RoomItemRow extends StatelessWidget {
  const _RoomItemRow({required this.item, required this.roomId});

  final Item item;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final String line;
    if (item.isSplit) {
      final others = item.allocations.keys
          .where((k) => k != roomId)
          .map((k) => store.room(k)?.name ?? 'another room');
      line =
          '${item.allocations[roomId]} of ${item.quantity} · other in ${others.join(', ')}';
    } else {
      line = [
        item.hasReceipt ? 'Receipt' : 'No receipt',
        if (item.estimated) 'estimate',
        item.photoCount == 0
            ? 'no photo'
            : Formatters.count(item.photoCount, 'photo'),
      ].join(' · ');
    }
    return RowTile(
      leading: ItemLeading(item),
      title: item.isSplit ? item.name : item.displayName,
      subtitle: line,
      badges: [
        if (item.highValue) const Pill('High value', tone: PillTone.amber),
      ],
      trailingText: money(
        item.valueInRoom(roomId),
        item.currency,
        estimate: item.estimated,
      ),
      onTap: () => Get.toNamed(Routes.item(item.id)),
    );
  }
}
