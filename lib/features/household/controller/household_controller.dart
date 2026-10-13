import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 82 · Households, 83 · Members, 84 · Invite, 85 · Property records,
/// 97 · Activity history.
class HouseholdController extends GetxController {
  HouseholdController({required this._ownership});

  final OwnershipRepository _ownership;

  final inviteKey = GlobalKey<FormState>();
  final inviteEmail = TextEditingController();
  final inviteRole = MemberRole.contributor.obs;

  List<Household> get households => _ownership.households;

  List<HouseholdMember> get members => _ownership.members;

  List<ActivityEntry> get activity => _ownership.activity;

  /// Property records grouped by room.
  Map<String, List<Possession>> get byRoom {
    final map = <String, List<Possession>>{};
    for (final p in _ownership.possessions) {
      map.putIfAbsent(p.room, () => []).add(p);
    }
    return map;
  }

  /// Only owners can delete a household; contributors and above can add.
  bool get canAddRecords => inviteRole.value != MemberRole.viewer;

  bool get canDeleteHousehold => inviteRole.value == MemberRole.owner;

  Future<void> addHousehold(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'Add household',
      label: 'Name',
    );
    if (name == null || name.isEmpty) return;
    if (households.any((h) => h.name.toLowerCase() == name.toLowerCase())) {
      Toast.show('$name already exists');
      return;
    }
    _ownership.addHousehold(name);
  }

  void openMembers() => Get.toNamed(Routes.householdMembers);

  void openInvite() {
    inviteEmail.clear();
    inviteRole.value = MemberRole.contributor;
    Get.toNamed(Routes.invite);
  }

  void addPropertyItem() => Get.toNamed(Routes.addPossession);

  void openPossession(Possession p) =>
      Get.toNamed(Routes.possessionDetail, arguments: p.id);

  Future<void> pickRole(BuildContext context) async {
    // Ownership cannot be handed over by invitation.
    final roles = MemberRole.values
        .where((r) => r != MemberRole.owner)
        .toList();
    final i = await showOptionSheet(
      context,
      title: 'Role',
      options: [for (final r in roles) '${r.label} · ${r.access}'],
      selected: roles.indexOf(inviteRole.value),
    );
    if (i != null) inviteRole.value = roles[i];
  }

  void sendInvite() {
    if (!(inviteKey.currentState?.validate() ?? false)) return;
    final email = inviteEmail.text.trim();
    if (members.any((m) => m.email?.toLowerCase() == email.toLowerCase())) {
      Toast.show('$email has already been invited');
      return;
    }
    _ownership.addMember(
      HouseholdMember(
        id: Ids.next('u'),
        name: email,
        email: email,
        role: inviteRole.value,
        pending: true,
      ),
    );
    Get.back();
    Toast.show(
      'Invitation prepared for $email · preview only, nothing is sent',
    );
  }

  @override
  void onClose() {
    inviteEmail.dispose();
    super.onClose();
  }
}
