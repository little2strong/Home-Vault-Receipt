# Home Vault Receipt

A Flutter app for keeping track of home purchase receipts, built with
[GetX](https://pub.dev/packages/get) for state management, routing and
dependency injection.

## Getting started

```bash
flutter pub get
flutter run
flutter test
```

## Folder structure

```
lib/
├── main.dart                          # Entry point
│
├── app/                               # App shell: setup that ties features together
│   ├── app.dart                       # GetMaterialApp (theme, routes, initial binding)
│   ├── bindings/
│   │   └── initial_binding.dart       # App-wide dependencies (permanent)
│   └── routes/
│       ├── app_routes.dart            # Route name constants
│       └── app_pages.dart             # GetPage list: route -> view + binding
│
├── core/                              # Shared code used by every feature
│   ├── constants/                     # app_colors, app_sizes, app_strings
│   ├── error/                         # app_exception
│   ├── models/                        # receipt_model (data class + JSON)
│   ├── repositories/                  # receipt_repository (data access)
│   ├── theme/                         # app_theme (light + dark)
│   ├── utils/                         # formatters
│   └── widgets/                       # Shared widgets (loader, message view,
│                                      # text field, receipt_category_icon)
│
└── features/                          # One folder per screen
    ├── splash/
    │   ├── binding/splash_binding.dart
    │   ├── controller/splash_controller.dart
    │   ├── view/splash_view.dart
    │   └── widgets/splash_logo.dart
    │
    ├── home/
    │   ├── binding/home_binding.dart
    │   ├── controller/home_controller.dart
    │   ├── view/home_view.dart
    │   └── widgets/                   # receipt_card, receipt_summary_card,
    │                                  # category_filter_bar
    │
    └── add_receipt/
        ├── binding/add_receipt_binding.dart
        ├── controller/add_receipt_controller.dart
        └── view/add_receipt_view.dart
```

### What goes where

| Folder              | Responsibility                                                         |
| ------------------- | ---------------------------------------------------------------------- |
| `binding/`          | Registers the screen's controller with `Get.lazyPut`.                  |
| `controller/`       | `GetxController` holding reactive state (`.obs`) and screen logic.     |
| `view/`             | The screen, extending `GetView<Controller>`; reactive parts use `Obx`. |
| `widgets/`          | Optional. UI pieces used only by this screen.                          |
| `core/models/`      | Data classes with `fromJson` / `toJson`.                               |
| `core/repositories/`| Fetches and saves data (local store, API, database).                   |

Feature folders contain only `binding/`, `controller/`, `view/` and, when
needed, `widgets/`. Models, repositories and widgets used by more than one
screen live in `core/`.

## Adding a new feature

1. Create `lib/features/<feature_name>/` with `binding/`, `controller/` and
   `view/` (add `widgets/` only if the screen has its own widgets).
2. Add a route name in `lib/app/routes/app_routes.dart`.
3. Register a `GetPage` with its view and binding in
   `lib/app/routes/app_pages.dart`.

## Data

Receipts are currently stored in memory by `ReceiptRepository` (seeded with
sample data), so they reset on restart. Replace its internals with an API
client or local database to persist data; controllers and views stay the same.
