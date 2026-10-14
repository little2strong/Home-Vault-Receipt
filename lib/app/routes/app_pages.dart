import 'package:get/get.dart';

import '../../features/account/view/account_pages.dart';
import '../../features/add/view/add_item_view.dart';
import '../../features/add/view/camera_view.dart';
import '../../features/add/view/manual_view.dart';
import '../../features/add/view/pages_view.dart';
import '../../features/add/view/reading_view.dart';
import '../../features/add/view/review_details_view.dart';
import '../../features/add/view/review_items_view.dart';
import '../../features/add/view/saved_view.dart';
import '../../features/home/controller/home_controller.dart';
import '../../features/home/view/search_view.dart';
import '../../features/products/controller/products_controller.dart';
import '../../features/products/view/item_detail_view.dart';
import '../../features/products/view/item_photos_view.dart';
import '../../features/products/view/original_viewer_view.dart';
import '../../features/products/view/receipt_detail_view.dart';
import '../../features/rooms/view/room_video_view.dart';
import '../../features/rooms/view/rooms_views.dart';
import '../../features/shell/controller/shell_controller.dart';
import '../../features/shell/view/shell_view.dart';
import '../../features/start/binding/start_bindings.dart';
import '../../features/start/view/start_views.dart';
import '../../features/warranties/view/edit_warranty_view.dart';
import '../../features/web/view/web_pages.dart';
import 'app_routes.dart';

/// GetPage list: route → view + binding.
abstract final class AppPages {
  static final _common = <GetPage<dynamic>>[
    GetPage(
      name: Routes.originalPattern,
      page: () => const OriginalViewerView(),
      binding: BindingsBuilder(
        () =>
            Get.lazyPut(() => OriginalViewerController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.deleteAccount,
      page: () => const DeleteAccountView(),
      binding: _deleteBinding,
    ),
    GetPage(name: Routes.privacy, page: () => const LegalView(terms: false)),
    GetPage(name: Routes.terms, page: () => const LegalView(terms: true)),
  ];

  static final _deleteBinding = BindingsBuilder(
    () => Get.lazyPut(
      () => DeleteAccountController(Get.find(), Get.find(), Get.find()),
    ),
  );

  /// The phone app: 38 pages.
  static final app = <GetPage<dynamic>>[
    ..._common,
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.welcome, page: () => const WelcomeView()),
    GetPage(
      name: Routes.signIn,
      page: () => const SignInView(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: Routes.signUp,
      page: () => const SignUpView(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      fullscreenDialog: true,
    ),
    GetPage(
      name: Routes.shell,
      page: () => const ShellView(),
      binding: BindingsBuilder(() {
        Get
          ..lazyPut(ShellController.new)
          ..lazyPut(() => HomeController(Get.find(), Get.find()))
          ..put(ProductsController(Get.find()));
      }),
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => VaultSearchController(Get.find())),
      ),
    ),
    GetPage(
      name: Routes.camera,
      page: () => const CameraView(),
      binding: BindingsBuilder(() => Get.lazyPut(CameraCaptureController.new)),
      fullscreenDialog: true,
    ),
    GetPage(
      name: Routes.pages,
      page: () => const PagesView(),
      binding: BindingsBuilder(() => Get.lazyPut(PagesController.new)),
    ),
    GetPage(
      name: Routes.reading,
      page: () => const ReadingView(),
      binding: BindingsBuilder(() => Get.lazyPut(ReadingController.new)),
    ),
    GetPage(
      name: Routes.reviewDetails,
      page: () => const ReviewDetailsView(),
      binding: BindingsBuilder(() => Get.lazyPut(ReviewDetailsController.new)),
    ),
    GetPage(
      name: Routes.reviewItems,
      page: () => const ReviewItemsView(),
      binding: BindingsBuilder(() => Get.lazyPut(ReviewItemsController.new)),
    ),
    GetPage(
      name: Routes.saved,
      page: () => const SavedView(),
      binding: BindingsBuilder(() => Get.lazyPut(SavedController.new)),
    ),
    GetPage(
      name: Routes.manual,
      page: () => const ManualView(),
      binding: BindingsBuilder(() => Get.lazyPut(ManualController.new)),
    ),
    GetPage(
      name: Routes.addItem,
      page: () => const AddItemView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => AddItemController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.warrantyPattern,
      page: () => const EditWarrantyView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => EditWarrantyController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.photosPattern,
      page: () => const ItemPhotosView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => ItemPhotosController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.itemPattern,
      page: () => const ItemDetailView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => ItemDetailController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.receiptPattern,
      page: () => const ReceiptDetailView(),
      binding: BindingsBuilder(
        () =>
            Get.lazyPut(() => ReceiptDetailController(Get.find(), Get.find())),
      ),
    ),
    GetPage(name: Routes.photoTips, page: () => const PhotoTipsView()),
    GetPage(
      name: Routes.homeSetup,
      page: () => const HomeSetupView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => HomeSetupController(Get.find())),
      ),
    ),
    GetPage(
      name: Routes.rooms,
      page: () => const RoomsView(),
      binding: _roomsBinding,
    ),
    GetPage(
      name: Routes.roomVideoPattern,
      page: () => const RoomVideoView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => RoomVideoController(Get.find(), Get.find(), Get.find()),
        ),
      ),
      fullscreenDialog: true,
    ),
    GetPage(
      name: Routes.roomPattern,
      page: () => const RoomDetailView(),
      binding: _roomsBinding,
    ),
    GetPage(name: Routes.spending, page: () => const SpendingView()),
    GetPage(name: Routes.cars, page: () => const CarsView()),
    GetPage(
      name: Routes.export,
      page: () => const ExportView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => ExportController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.exportReadyPattern,
      page: () => const ExportReadyView(),
    ),
    GetPage(name: Routes.settings, page: () => const SettingsView()),
    GetPage(name: Routes.pending, page: () => const PendingView()),
    GetPage(name: Routes.help, page: () => const HelpView()),
  ];

  static final _roomsBinding = BindingsBuilder(
    () => Get.lazyPut(() => RoomsController(Get.find(), Get.find())),
  );

  /// The website: 6 pages.
  static final web = <GetPage<dynamic>>[
    ..._common,
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.webSignIn,
      page: () => const WebSignInView(),
      binding: SignInBinding(),
    ),
    GetPage(name: Routes.webDashboard, page: () => const WebDashboardView()),
    GetPage(
      name: Routes.webProducts,
      page: () => const WebProductsView(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => WebProductsController(Get.find())),
      ),
    ),
    GetPage(name: Routes.webItemPattern, page: () => const WebItemView()),
    GetPage(name: Routes.webInventory, page: () => const WebInventoryView()),
    GetPage(name: Routes.webDownloads, page: () => const WebDownloadsView()),
    GetPage(
      name: Routes.webDeleteAccount,
      page: () => const DeleteAccountView(),
      binding: _deleteBinding,
    ),
  ];
}
