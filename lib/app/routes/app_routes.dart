/// Route names. Numbers refer to screens in the Home Vault design.
abstract final class Routes {
  static const splash = '/splash';

  // Onboarding and account (01–06)
  static const welcome = '/welcome';
  static const howItWorks = '/how-it-works';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const verifyEmail = '/verify-email';
  static const resetPassword = '/reset-password';

  // Tabs: dashboard (07–08), receipts (09–11), settings (43)
  static const shell = '/home';

  // Receipts (12–14)
  static const receiptFilters = '/receipts/filters';
  static const categories = '/receipts/categories';
  static const categoryProducts = '/receipts/category';

  // Capture (15–22, 39–40)
  static const addSource = '/capture';
  static const cameraPermission = '/capture/camera-permission';
  static const scanner = '/capture/scanner';
  static const crop = '/capture/crop';
  static const multiPhoto = '/capture/photos';
  static const pdfImport = '/capture/pdf';
  static const pdfBlocked = '/capture/pdf-locked';
  static const ocrProcessing = '/capture/reading';
  static const unreadable = '/capture/unreadable';
  static const pilotQuota = '/capture/quota';

  // Review (23–29)
  static const reviewSummary = '/review';
  static const reviewItems = '/review/products';
  static const editDate = '/review/date';
  static const editItem = '/review/product';
  static const returnTerms = '/review/return-terms';
  static const duplicate = '/review/duplicate';
  static const manualReceipt = '/review/manual';

  // Saving (30–31, 37–38)
  static const saving = '/saving';
  static const saved = '/saving/done';
  static const pendingUploads = '/saving/pending';
  static const uploadFailure = '/saving/failed';

  // Receipt detail (32–36)
  static const receiptDetail = '/receipt';
  static const originalDocument = '/receipt/original';
  static const editReceipt = '/receipt/edit';
  static const deleteReceipt = '/receipt/delete';

  // Reminders (41–42)
  static const reminders = '/reminders';
  static const reminderDetail = '/reminders/detail';

  // Settings (44–51)
  static const notificationSettings = '/settings/notifications';
  static const accountSecurity = '/settings/security';
  static const devices = '/settings/devices';
  static const privacy = '/settings/privacy';
  static const exportData = '/settings/export';
  static const exportReady = '/settings/export/ready';
  static const deleteAccount = '/settings/delete-account';
  static const help = '/settings/help';

  // Roadmap (52–98)
  static const moreTools = '/more';
  static const inventory = '/possessions';
  static const addPossession = '/possessions/add';
  static const productIdentification = '/possessions/identify';
  static const serialNumber = '/possessions/serial';
  static const possessionDetail = '/possessions/detail';
  static const itemGallery = '/possessions/gallery';
  static const itemDocuments = '/possessions/documents';
  static const documentExtraction = '/possessions/documents/extract';
  static const rooms = '/rooms';
  static const roomDetail = '/rooms/detail';
  static const roomScan = '/rooms/scan';
  static const roomScanReview = '/rooms/scan/review';
  static const rapidInventory = '/rooms/rapid';
  static const inbox = '/inbox';
  static const duplicateMerge = '/inbox/merge';
  static const completeness = '/inbox/completeness';
  static const warranties = '/protection/warranties';
  static const warrantyAssistant = '/protection/warranty';
  static const maintenance = '/protection/maintenance';
  static const maintenanceRecord = '/protection/maintenance/add';
  static const repairRecord = '/protection/repair';
  static const recallAlert = '/protection/recall';
  static const insuranceReadiness = '/insurance';
  static const insuranceReport = '/insurance/report';
  static const newClaim = '/insurance/claim';
  static const claimWorkspace = '/insurance/claim/workspace';
  static const claimPackage = '/insurance/claim/package';
  static const valuation = '/insurance/valuation';
  static const ownershipTimeline = '/lifecycle/timeline';
  static const resaleDraft = '/lifecycle/resale';
  static const ownershipStatus = '/lifecycle/status';
  static const collections = '/lifecycle/collections';
  static const appraisal = '/lifecycle/appraisal';
  static const secureSharing = '/lifecycle/share';
  static const households = '/household';
  static const householdMembers = '/household/members';
  static const invite = '/household/invite';
  static const propertyInventory = '/household/property';
  static const activity = '/household/activity';
  static const emailImports = '/imports/email';
  static const retailerImports = '/imports/retailers';
  static const moving = '/moving';
  static const movingBox = '/moving/box';
  static const boxLabel = '/moving/label';
  static const assistant = '/assistant';
  static const plans = '/plans';
}
