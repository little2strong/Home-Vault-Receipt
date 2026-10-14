import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';

/// 14 Edit item sheet: one item's tags, with "More details" behind a
/// heading so nothing optional gets in the way.
class EditItemSheet extends StatefulWidget {
  const EditItemSheet({
    super.key,
    required this.item,
    required this.currency,
    this.purchaseDate,
    this.savedItemId,
    this.onViewOnReceipt,
    this.onDelete,
  });

  final DraftItem item;
  final String currency;
  final DateTime? purchaseDate;

  /// Set when editing a saved item: photos and warranty open their pages.
  final String? savedItemId;
  final VoidCallback? onViewOnReceipt;
  final VoidCallback? onDelete;

  static Future<DraftItem?> open({
    required DraftItem item,
    required String currency,
    DateTime? purchaseDate,
    String? savedItemId,
    VoidCallback? onViewOnReceipt,
    VoidCallback? onDelete,
  }) => SheetFrame.show<DraftItem>(
    EditItemSheet(
      item: item.copy(),
      currency: currency,
      purchaseDate: purchaseDate,
      savedItemId: savedItemId,
      onViewOnReceipt: onViewOnReceipt,
      onDelete: onDelete,
    ),
  );

  @override
  State<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<EditItemSheet> {
  final store = Get.find<VaultStore>();
  late final DraftItem item = widget.item;
  late final name = TextEditingController(text: item.name);
  late final qty = TextEditingController(text: '${item.quantity}');
  late final price = TextEditingController(
    text: item.lineTotalMinor == null
        ? ''
        : Money.toInput(item.lineTotalMinor!),
  );

  @override
  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  void _syncNumbers() {
    final q = int.tryParse(qty.text.trim());
    if (q != null && q > 0 && q < 1000 && q != item.quantity) {
      item.quantity = q;
      if (!item.isSplit) item.setRoom(item.roomId);
    }
    final line = Money.parse(price.text);
    item.lineTotalMinor = line;
    item.unitPriceMinor = line == null ? null : line ~/ item.quantity;
  }

  Future<void> _pickRoom() async {
    if (store.rooms.isEmpty) {
      await Get.toNamed(Routes.homeSetup);
      if (store.rooms.isEmpty) return;
    }
    if (!mounted) return;
    final id = await Pickers.room(
      context,
      rooms: store.rooms,
      selected: item.roomId,
      onSetUp: () => Get.toNamed(Routes.homeSetup),
    );
    if (id != null) setState(() => item.setRoom(id));
  }

  Future<void> _split() async {
    _syncNumbers();
    if (store.rooms.isEmpty) await Get.toNamed(Routes.homeSetup);
    if (store.rooms.isEmpty || !mounted) return;
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SplitRoomsSheet(
        rooms: store.rooms,
        quantity: item.quantity,
        initial: item.allocations,
      ),
    );
    if (result != null) setState(() => item.allocations = result);
  }

  Future<void> _car() async {
    final cars = store.cars;
    if (cars.length == 1) {
      item.carId = cars.first.id;
      return;
    }
    if (cars.isEmpty) {
      final car = await Pickers.text(
        context,
        title: 'Which car is this for?',
        hint: 'e.g. Golf',
        action: 'Add car',
        caps: TextCapitalization.words,
      );
      if (car == null || car.trim().isEmpty) return;
      final id = await Get.find<VaultRepository>().saveCar(name: car);
      setState(() => item.carId = id);
      return;
    }
    if (!mounted) return;
    final id = await Pickers.choose<String>(
      context,
      title: 'Which car?',
      values: [for (final c in cars) c.id],
      label: (id) => cars.firstWhere((c) => c.id == id).name,
      selected: item.carId,
    );
    if (id != null) setState(() => item.carId = id);
  }

  Future<void> _warranty() async {
    if (widget.savedItemId != null) {
      Get.back<void>();
      await Get.toNamed(Routes.warranty(widget.savedItemId!));
      return;
    }
    final from = widget.purchaseDate ?? DateTime.now();
    final choice = await Pickers.choose<int>(
      context,
      title: 'How long is the warranty?',
      values: const [12, 24, 36, 60, 0],
      label: (m) => m == 0
          ? 'Pick the end date'
          : '${m ~/ 12} year${m == 12 ? '' : 's'} from purchase',
      selected: item.warrantyMonths,
      footer: item.warrantyEnd == null
          ? null
          : TextButton(
              onPressed: () => Navigator.of(context).pop(-1),
              child: const Text('Remove warranty'),
            ),
    );
    if (choice == null || !mounted) return;
    if (choice == -1) {
      setState(() {
        item.warrantyEnd = null;
        item.warrantyMonths = null;
      });
      return;
    }
    if (choice == 0) {
      final end = await Pickers.date(
        context,
        initial: Dates.addMonths(from, 12),
        first: from,
        help: 'Warranty end date',
      );
      if (end == null) return;
      setState(() {
        item.warrantyEnd = end;
        item.warrantyMonths = null;
      });
    } else {
      setState(() {
        item.warrantyMonths = choice;
        item.warrantyEnd = Dates.addMonths(from, choice);
      });
    }
  }

  Future<void> _serial() async {
    final serial = TextEditingController(text: item.serial);
    final model = TextEditingController(text: item.model);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serial and model number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serial,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Serial number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: model,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Model number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        item.serial = serial.text.trim().isEmpty ? null : serial.text.trim();
        item.model = model.text.trim().isEmpty ? null : model.text.trim();
      });
    }
  }

  void _done() {
    _syncNumbers();
    item.name = name.text.trim();
    if (item.name.isEmpty) {
      Toast.show('Give the item a name.');
      return;
    }
    Get.back(result: item);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rooms = store.rooms;
    String roomName(String id) =>
        rooms.firstWhereOrNull((r) => r.id == id)?.name ?? 'Room';
    final roomLabel = item.allocations.isEmpty
        ? null
        : item.isSplit
        ? item.allocations.entries
              .map((e) => '${roomName(e.key)} ${e.value}')
              .join(' · ')
        : roomName(item.roomId!);
    final car = store.car(item.carId);

    return SheetFrame(
      title: 'Edit item',
      trailing: widget.onViewOnReceipt == null
          ? null
          : TextButton(
              onPressed: widget.onViewOnReceipt,
              child: const Text(
                'View on receipt',
                style: TextStyle(fontSize: 16),
              ),
            ),
      children: [
        LabeledField(
          label: 'Name',
          controller: name,
          textCapitalization: TextCapitalization.sentences,
        ),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Quantity',
                controller: qty,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(_syncNumbers),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: LabeledField(
                label:
                    'Price paid (${Money.symbolFor(widget.currency).trim()})',
                controller: price,
                hint: 'Not stated',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        PickerField(
          label: 'Category',
          value: item.category.label,
          onTap: () async {
            final c = await Pickers.choose<Category>(
              context,
              title: 'Category',
              values: Category.values,
              label: (c) => c.label,
              selected: item.category,
            );
            if (c != null) setState(() => item.setCategory(c));
          },
        ),
        const FieldLabel('Type'),
        ChoiceGroup<ItemType>(
          values: ItemType.values,
          selected: item.type,
          label: (v) => v.label,
          onSelected: (v) => setState(() {
            item.type = v;
            item.typeTouched = true;
          }),
        ),
        const FieldLabel('Purpose'),
        ChoiceGroup<Purpose>(
          values: Purpose.values,
          selected: item.purpose,
          label: (v) => v.label,
          onSelected: (v) async {
            setState(() => item.purpose = v);
            if (v == Purpose.car) {
              await _car();
              setState(() {});
            }
          },
        ),
        if (item.purpose == Purpose.car)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () async {
                await _car();
                setState(() {});
              },
              icon: const Icon(Icons.directions_car_outlined),
              label: Text(car == null ? 'Choose a car' : 'For ${car.name}'),
            ),
          ),
        if (item.isPhysical) ...[
          const SizedBox(height: 12),
          SwitchRow(
            title: 'In my home',
            subtitle: 'Adds it to your home inventory',
            value: item.inHome,
            onChanged: (v) => setState(() => item.inHome = v),
          ),
          if (item.inHome) ...[
            PickerField(
              label: 'Room · quantity ${item.quantity}',
              value: roomLabel,
              placeholder: rooms.isEmpty
                  ? 'Set up your rooms'
                  : 'Choose a room',
              onTap: _pickRoom,
            ),
            if (item.quantity > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _split,
                  child: const Text('Split across rooms'),
                ),
              ),
          ],
        ],
        const SizedBox(height: 18),
        Text(
          'More details · optional',
          style: context.textStyles.labelLarge?.copyWith(
            color: p.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Divider(),
        _MoreRow(
          'Warranty',
          item.warrantyEnd == null
              ? 'Add end date'
              : 'Ends ${Formatters.medium(item.warrantyEnd!)}',
          _warranty,
        ),
        _MoreRow(
          'Item photos',
          widget.savedItemId == null ? 'Add after saving' : 'Open',
          widget.savedItemId == null
              ? null
              : () {
                  Get.back<void>();
                  Get.toNamed(Routes.photos(widget.savedItemId!));
                },
        ),
        _MoreRow(
          'Serial and model number',
          [item.serial, item.model].whereType<String>().join(' · '),
          _serial,
        ),
        _MoreRow(
          'High value',
          item.highValue ? 'On' : 'Off',
          () => setState(() => item.highValue = !item.highValue),
        ),
        _MoreRow('Notes', item.notes ?? '', () async {
          final n = await Pickers.text(
            context,
            title: 'Notes',
            initial: item.notes,
          );
          if (n != null) {
            setState(() => item.notes = n.trim().isEmpty ? null : n.trim());
          }
        }),
        if (widget.onDelete != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinkButton(
              label: 'Remove this item',
              color: p.dangerInk,
              onPressed: () {
                Get.back<void>();
                widget.onDelete!();
              },
            ),
          ),
        const SizedBox(height: 16),
        VaultButton(label: 'Done', onPressed: _done),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow(this.label, this.value, this.onTap);

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 18)),
                ),
                Flexible(
                  child: Text(
                    onTap == null ? value : '$value ›',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Splits a quantity across rooms (2 × lamp → bedroom 1, sitting room 1).
class SplitRoomsSheet extends StatefulWidget {
  const SplitRoomsSheet({
    super.key,
    required this.rooms,
    required this.quantity,
    required this.initial,
  });

  final List<Room> rooms;
  final int quantity;
  final Map<String, int> initial;

  @override
  State<SplitRoomsSheet> createState() => _SplitRoomsSheetState();
}

class _SplitRoomsSheetState extends State<SplitRoomsSheet> {
  late final counts = {
    for (final r in widget.rooms) r.id: widget.initial[r.id] ?? 0,
  };

  int get used => counts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final left = widget.quantity - used;
    return SheetFrame(
      title: 'Split across rooms',
      children: [
        Text(
          left == 0
              ? 'All ${widget.quantity} placed.'
              : '$left of ${widget.quantity} still to place.',
          style: TextStyle(
            color: left == 0
                ? context.palette.primary
                : context.palette.warningInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final r in widget.rooms)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(r.name, style: const TextStyle(fontSize: 17)),
                ),
                Counter(
                  value: counts[r.id]!,
                  label: r.name,
                  max: counts[r.id]! + left,
                  onChanged: (v) => setState(() => counts[r.id] = v),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        VaultButton(
          label: 'Done',
          onPressed: left != 0
              ? null
              : () => Navigator.of(context).pop({
                  for (final e in counts.entries)
                    if (e.value > 0) e.key: e.value,
                }),
        ),
      ],
    );
  }
}
