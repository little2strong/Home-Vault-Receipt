// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.10.0"),
        .package(name: "cloud_functions", path: "../.packages/cloud_functions-6.5.0"),
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-7.3.2"),
        .package(name: "file_picker_darwin", path: "../.packages/file_picker_darwin-2.3.0"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5+1"),
        .package(name: "firebase_app_check", path: "../.packages/firebase_app_check-0.4.8"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.7.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.15.0"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.4.0"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.7.0"),
        .package(name: "firebase_remote_config", path: "../.packages/firebase_remote_config-6.7.0"),
        .package(name: "firebase_storage", path: "../.packages/firebase_storage-13.6.0"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.2"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.1"),
        .package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios-6.3.7"),
        .package(name: "pdfx", path: "../.packages/pdfx-2.11.0"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.3.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.7"),
        .package(name: "sign_in_with_apple", path: "../.packages/sign_in_with_apple-8.2.0"),
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.6"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.12.1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "cloud-functions", package: "cloud_functions"),
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "file-picker-darwin", package: "file_picker_darwin"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-app-check", package: "firebase_app_check"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-remote-config", package: "firebase_remote_config"),
                .product(name: "firebase-storage", package: "firebase_storage"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "google-sign-in-ios", package: "google_sign_in_ios"),
                .product(name: "pdfx", package: "pdfx"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sign-in-with-apple", package: "sign_in_with_apple"),
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
