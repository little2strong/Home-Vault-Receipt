import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/assistant/binding/assistant_binding.dart';
import '../../features/assistant/view/assistant_view.dart';
import '../../features/auth/binding/auth_bindings.dart';
import '../../features/auth/view/create_account_view.dart';
import '../../features/auth/view/reset_password_view.dart';
import '../../features/auth/view/sign_in_view.dart';
import '../../features/auth/view/verify_email_view.dart';
import '../../features/capture/binding/capture_binding.dart';
import '../../features/capture/view/add_source_view.dart';
import '../../features/capture/view/camera_permission_view.dart';
import '../../features/capture/view/crop_view.dart';
import '../../features/capture/view/multi_photo_view.dart';
import '../../features/capture/view/ocr_processing_view.dart';
import '../../features/capture/view/pdf_blocked_view.dart';
import '../../features/capture/view/pdf_import_view.dart';
import '../../features/capture/view/pilot_quota_view.dart';
import '../../features/capture/view/scanner_view.dart';
import '../../features/capture/view/unreadable_view.dart';
import '../../features/household/binding/household_binding.dart';
import '../../features/household/view/activity_view.dart';
import '../../features/household/view/household_members_view.dart';
import '../../features/household/view/households_view.dart';
import '../../features/household/view/invite_view.dart';
import '../../features/household/view/property_inventory_view.dart';
import '../../features/imports/view/email_imports_view.dart';
import '../../features/imports/view/retailer_imports_view.dart';
import '../../features/inbox/binding/inbox_binding.dart';
import '../../features/inbox/view/completeness_view.dart';
import '../../features/inbox/view/duplicate_merge_view.dart';
import '../../features/inbox/view/inbox_view.dart';
import '../../features/insurance/binding/insurance_binding.dart';
import '../../features/insurance/view/claim_package_view.dart';
import '../../features/insurance/view/claim_workspace_view.dart';
import '../../features/insurance/view/insurance_readiness_view.dart';
import '../../features/insurance/view/insurance_report_view.dart';
import '../../features/insurance/view/new_claim_view.dart';
import '../../features/insurance/view/valuation_view.dart';
import '../../features/lifecycle/binding/lifecycle_bindings.dart';
import '../../features/lifecycle/view/appraisal_view.dart';
import '../../features/lifecycle/view/collections_view.dart';
import '../../features/lifecycle/view/ownership_status_view.dart';
import '../../features/lifecycle/view/ownership_timeline_view.dart';
import '../../features/lifecycle/view/resale_draft_view.dart';
import '../../features/lifecycle/view/secure_sharing_view.dart';
import '../../features/more_tools/view/more_tools_view.dart';
import '../../features/moving/binding/moving_binding.dart';
import '../../features/moving/view/box_label_view.dart';
import '../../features/moving/view/moving_box_view.dart';
import '../../features/moving/view/moving_view.dart';
import '../../features/onboarding/binding/onboarding_binding.dart';
import '../../features/onboarding/view/how_it_works_view.dart';
import '../../features/onboarding/view/welcome_view.dart';
import '../../features/plans/view/plans_view.dart';
import '../../features/possessions/binding/possessions_bindings.dart';
import '../../features/possessions/view/add_possession_view.dart';
import '../../features/possessions/view/document_extraction_view.dart';
import '../../features/possessions/view/inventory_view.dart';
import '../../features/possessions/view/item_documents_view.dart';
import '../../features/possessions/view/item_gallery_view.dart';
import '../../features/possessions/view/possession_detail_view.dart';
import '../../features/possessions/view/product_identification_view.dart';
import '../../features/possessions/view/serial_number_view.dart';
import '../../features/protection/binding/protection_binding.dart';
import '../../features/protection/view/maintenance_record_view.dart';
import '../../features/protection/view/maintenance_view.dart';
import '../../features/protection/view/recall_alert_view.dart';
import '../../features/protection/view/repair_record_view.dart';
import '../../features/protection/view/warranties_view.dart';
import '../../features/protection/view/warranty_assistant_view.dart';
import '../../features/receipt_detail/binding/receipt_detail_bindings.dart';
import '../../features/receipt_detail/view/delete_receipt_view.dart';
import '../../features/receipt_detail/view/edit_receipt_view.dart';
import '../../features/receipt_detail/view/original_document_view.dart';
import '../../features/receipt_detail/view/receipt_detail_view.dart';
import '../../features/receipts/binding/receipts_bindings.dart';
import '../../features/receipts/view/categories_view.dart';
import '../../features/receipts/view/category_products_view.dart';
import '../../features/receipts/view/receipt_filters_view.dart';
import '../../features/reminders/binding/reminders_bindings.dart';
import '../../features/reminders/view/reminder_detail_view.dart';
import '../../features/reminders/view/reminders_view.dart';
import '../../features/review/binding/review_bindings.dart';
import '../../features/review/view/duplicate_view.dart';
import '../../features/review/view/edit_date_view.dart';
import '../../features/review/view/edit_item_view.dart';
import '../../features/review/view/manual_receipt_view.dart';
import '../../features/review/view/return_terms_view.dart';
import '../../features/review/view/review_items_view.dart';
import '../../features/review/view/review_summary_view.dart';
import '../../features/rooms/binding/rooms_binding.dart';
import '../../features/rooms/view/rapid_inventory_view.dart';
import '../../features/rooms/view/room_detail_view.dart';
import '../../features/rooms/view/room_scan_review_view.dart';
import '../../features/rooms/view/room_scan_view.dart';
import '../../features/rooms/view/rooms_view.dart';
import '../../features/saving/binding/saving_bindings.dart';
import '../../features/saving/view/pending_uploads_view.dart';
import '../../features/saving/view/saved_view.dart';
import '../../features/saving/view/saving_view.dart';
import '../../features/saving/view/upload_failure_view.dart';
import '../../features/settings/binding/settings_bindings.dart';
import '../../features/settings/view/account_security_view.dart';
import '../../features/settings/view/delete_account_view.dart';
import '../../features/settings/view/devices_view.dart';
import '../../features/settings/view/export_ready_view.dart';
import '../../features/settings/view/export_view.dart';
import '../../features/settings/view/help_view.dart';
import '../../features/settings/view/notification_settings_view.dart';
import '../../features/settings/view/privacy_view.dart';
import '../../features/shell/binding/shell_binding.dart';
import '../../features/shell/view/shell_view.dart';
import '../../features/splash/binding/splash_binding.dart';
import '../../features/splash/view/splash_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = Routes.splash;

  static GetPage _page(
    String name,
    Widget Function() page, [
    Bindings? binding,
  ]) => GetPage(name: name, page: page, binding: binding);

  static final pages = <GetPage>[
    _page(Routes.splash, () => const SplashView(), SplashBinding()),

    // Onboarding and account
    _page(Routes.welcome, () => const WelcomeView(), OnboardingBinding()),
    _page(Routes.howItWorks, () => const HowItWorksView(), OnboardingBinding()),
    _page(Routes.signIn, () => const SignInView(), SignInBinding()),
    _page(
      Routes.createAccount,
      () => const CreateAccountView(),
      CreateAccountBinding(),
    ),
    _page(
      Routes.verifyEmail,
      () => const VerifyEmailView(),
      VerifyEmailBinding(),
    ),
    _page(
      Routes.resetPassword,
      () => const ResetPasswordView(),
      ResetPasswordBinding(),
    ),

    // Tabs and receipts
    _page(Routes.shell, () => const ShellView(), ShellBinding()),
    _page(
      Routes.receiptFilters,
      () => const ReceiptFiltersView(),
      ReceiptFiltersBinding(),
    ),
    _page(Routes.categories, () => const CategoriesView(), CategoriesBinding()),
    _page(
      Routes.categoryProducts,
      () => const CategoryProductsView(),
      CategoryProductsBinding(),
    ),

    // Capture
    _page(Routes.addSource, () => const AddSourceView(), CaptureBinding()),
    _page(
      Routes.cameraPermission,
      () => const CameraPermissionView(),
      CaptureBinding(),
    ),
    _page(Routes.scanner, () => const ScannerView(), CaptureBinding()),
    _page(Routes.crop, () => const CropView(), CaptureBinding()),
    _page(Routes.multiPhoto, () => const MultiPhotoView(), CaptureBinding()),
    _page(Routes.pdfImport, () => const PdfImportView(), CaptureBinding()),
    _page(Routes.pdfBlocked, () => const PdfBlockedView(), CaptureBinding()),
    _page(
      Routes.ocrProcessing,
      () => const OcrProcessingView(),
      CaptureBinding(),
    ),
    _page(Routes.unreadable, () => const UnreadableView(), CaptureBinding()),
    _page(Routes.pilotQuota, () => const PilotQuotaView()),

    // Review
    _page(
      Routes.reviewSummary,
      () => const ReviewSummaryView(),
      ReviewBinding(),
    ),
    _page(Routes.reviewItems, () => const ReviewItemsView(), ReviewBinding()),
    _page(Routes.editDate, () => const EditDateView(), ReviewBinding()),
    _page(Routes.duplicate, () => const DuplicateView(), ReviewBinding()),
    _page(Routes.editItem, () => const EditItemView(), EditItemBinding()),
    _page(
      Routes.returnTerms,
      () => const ReturnTermsView(),
      ReturnTermsBinding(),
    ),
    _page(
      Routes.manualReceipt,
      () => const ManualReceiptView(),
      ManualReceiptBinding(),
    ),

    // Saving
    _page(Routes.saving, () => const SavingView(), SavingBinding()),
    _page(Routes.saved, () => const SavedView(), SaveResultBinding()),
    _page(
      Routes.uploadFailure,
      () => const UploadFailureView(),
      SaveResultBinding(),
    ),
    _page(
      Routes.pendingUploads,
      () => const PendingUploadsView(),
      PendingBinding(),
    ),

    // Receipt detail
    _page(
      Routes.receiptDetail,
      () => const ReceiptDetailView(),
      ReceiptDetailBinding(),
    ),
    _page(
      Routes.originalDocument,
      () => const OriginalDocumentView(),
      ReceiptDetailBinding(),
    ),
    _page(
      Routes.deleteReceipt,
      () => const DeleteReceiptView(),
      ReceiptDetailBinding(),
    ),
    _page(
      Routes.editReceipt,
      () => const EditReceiptView(),
      EditReceiptBinding(),
    ),

    // Reminders
    _page(Routes.reminders, () => const RemindersView(), RemindersBinding()),
    _page(
      Routes.reminderDetail,
      () => const ReminderDetailView(),
      ReminderDetailBinding(),
    ),

    // Settings
    _page(
      Routes.notificationSettings,
      () => const NotificationSettingsView(),
      NotificationSettingsBinding(),
    ),
    _page(
      Routes.accountSecurity,
      () => const AccountSecurityView(),
      AccountSecurityBinding(),
    ),
    _page(Routes.devices, () => const DevicesView(), AccountSecurityBinding()),
    _page(Routes.privacy, () => const PrivacyView()),
    _page(Routes.exportData, () => const ExportView(), ExportBinding()),
    _page(Routes.exportReady, () => const ExportReadyView(), ExportBinding()),
    _page(
      Routes.deleteAccount,
      () => const DeleteAccountView(),
      DeleteAccountBinding(),
    ),
    _page(Routes.help, () => const HelpView(), HelpBinding()),

    // Roadmap
    _page(Routes.moreTools, () => const MoreToolsView()),
    _page(Routes.inventory, () => const InventoryView(), InventoryBinding()),
    _page(
      Routes.addPossession,
      () => const AddPossessionView(),
      AddPossessionBinding(),
    ),
    _page(
      Routes.productIdentification,
      () => const ProductIdentificationView(),
      AddPossessionBinding(),
    ),
    _page(
      Routes.serialNumber,
      () => const SerialNumberView(),
      AddPossessionBinding(),
    ),
    _page(
      Routes.possessionDetail,
      () => const PossessionDetailView(),
      PossessionDetailBinding(),
    ),
    _page(
      Routes.itemGallery,
      () => const ItemGalleryView(),
      PossessionDetailBinding(),
    ),
    _page(
      Routes.itemDocuments,
      () => const ItemDocumentsView(),
      PossessionDetailBinding(),
    ),
    _page(
      Routes.documentExtraction,
      () => const DocumentExtractionView(),
      PossessionDetailBinding(),
    ),
    _page(Routes.rooms, () => const RoomsView(), RoomsBinding()),
    _page(Routes.roomDetail, () => const RoomDetailView(), RoomsBinding()),
    _page(Routes.roomScan, () => const RoomScanView(), RoomsBinding()),
    _page(
      Routes.roomScanReview,
      () => const RoomScanReviewView(),
      RoomsBinding(),
    ),
    _page(
      Routes.rapidInventory,
      () => const RapidInventoryView(),
      RoomsBinding(),
    ),
    _page(Routes.inbox, () => const InboxView(), InboxBinding()),
    _page(
      Routes.duplicateMerge,
      () => const DuplicateMergeView(),
      InboxBinding(),
    ),
    _page(Routes.completeness, () => const CompletenessView(), InboxBinding()),
    _page(Routes.warranties, () => const WarrantiesView(), ProtectionBinding()),
    _page(
      Routes.warrantyAssistant,
      () => const WarrantyAssistantView(),
      ProtectionBinding(),
    ),
    _page(
      Routes.maintenance,
      () => const MaintenanceView(),
      ProtectionBinding(),
    ),
    _page(
      Routes.maintenanceRecord,
      () => const MaintenanceRecordView(),
      ProtectionBinding(),
    ),
    _page(
      Routes.repairRecord,
      () => const RepairRecordView(),
      ProtectionBinding(),
    ),
    _page(
      Routes.recallAlert,
      () => const RecallAlertView(),
      ProtectionBinding(),
    ),
    _page(
      Routes.insuranceReadiness,
      () => const InsuranceReadinessView(),
      InsuranceBinding(),
    ),
    _page(
      Routes.insuranceReport,
      () => const InsuranceReportView(),
      InsuranceBinding(),
    ),
    _page(Routes.newClaim, () => const NewClaimView(), InsuranceBinding()),
    _page(
      Routes.claimWorkspace,
      () => const ClaimWorkspaceView(),
      InsuranceBinding(),
    ),
    _page(
      Routes.claimPackage,
      () => const ClaimPackageView(),
      InsuranceBinding(),
    ),
    _page(Routes.valuation, () => const ValuationView(), InsuranceBinding()),
    _page(
      Routes.ownershipTimeline,
      () => const OwnershipTimelineView(),
      LifecycleBinding(),
    ),
    _page(
      Routes.resaleDraft,
      () => const ResaleDraftView(),
      LifecycleBinding(),
    ),
    _page(
      Routes.ownershipStatus,
      () => const OwnershipStatusView(),
      LifecycleBinding(),
    ),
    _page(
      Routes.secureSharing,
      () => const SecureSharingView(),
      LifecycleBinding(),
    ),
    _page(
      Routes.collections,
      () => const CollectionsView(),
      CollectionsBinding(),
    ),
    _page(Routes.appraisal, () => const AppraisalView(), CollectionsBinding()),
    _page(Routes.households, () => const HouseholdsView(), HouseholdBinding()),
    _page(
      Routes.householdMembers,
      () => const HouseholdMembersView(),
      HouseholdBinding(),
    ),
    _page(Routes.invite, () => const InviteView(), HouseholdBinding()),
    _page(
      Routes.propertyInventory,
      () => const PropertyInventoryView(),
      HouseholdBinding(),
    ),
    _page(Routes.activity, () => const ActivityView(), HouseholdBinding()),
    _page(Routes.emailImports, () => const EmailImportsView()),
    _page(Routes.retailerImports, () => const RetailerImportsView()),
    _page(Routes.moving, () => const MovingView(), MovingBinding()),
    _page(Routes.movingBox, () => const MovingBoxView(), MovingBinding()),
    _page(Routes.boxLabel, () => const BoxLabelView(), MovingBinding()),
    _page(Routes.assistant, () => const AssistantView(), AssistantBinding()),
    _page(Routes.plans, () => const PlansView()),
  ];
}
