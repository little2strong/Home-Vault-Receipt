import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_filter.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../capture/capture_launcher.dart';

class DashboardController extends GetxController {
  DashboardController({
    required this._receipts,
    required this._auth,
    this._clock = DateTime.now,
  });

  final ReceiptRepository _receipts;
  final AuthRepository _auth;
  final Clock _clock;

  /// Nothing saved and nothing pending: show the first-receipt state.
  bool get isEmpty => _receipts.receipts.isEmpty;

  int get savedCount => _receipts.savedCount;

  int get draftCount => _receipts.drafts.length;

  /// Queued or failed uploads, distinct from drafts awaiting review.
  int get waitingCount => _receipts.pending.length - draftCount;

  int get withoutOriginalCount =>
      _receipts.saved.where((r) => !r.hasOriginal).length;

  List<Receipt> get deadlinesSoon =>
      _receipts.openDeadlines(withinDays: ReceiptFilter.soonWindowDays);

  List<Receipt> get recentlySaved {
    final saved = _receipts.saved
      ..sort(
        (a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt),
      );
    return saved.take(2).toList();
  }

  int daysLeft(Receipt r) => r.daysUntilReturn(_receipts.today) ?? 0;

  String get greeting {
    final hour = _clock().hour;
    final part = hour < 12
        ? 'morning'
        : hour < 18
        ? 'afternoon'
        : 'evening';
    final name = _auth.currentUser.value?.displayName;
    return name == null ? 'Good $part.' : 'Good $part, $name.';
  }

  void addReceipt() => CaptureLauncher.start();

  void openReceipt(Receipt r) =>
      Get.toNamed(Routes.receiptDetail, arguments: r.id);

  void openReminder(Receipt r) =>
      Get.toNamed(Routes.reminderDetail, arguments: r.id);

  void openReminders() => Get.toNamed(Routes.reminders);

  void openPending() => Get.toNamed(Routes.pendingUploads);
}
