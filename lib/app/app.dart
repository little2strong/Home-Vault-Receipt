import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/data/auth_repository.dart';
import '../core/data/vault_store.dart';
import '../core/theme/app_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class App extends StatefulWidget {
  const App({super.key, this.initialLink});

  /// An email sign-in link that launched the app.
  final String? initialLink;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _links = AppLinks().uriLinkStream.listen((uri) {
        final link = uri.toString();
        if (Get.isRegistered<AuthRepository>() &&
            Get.find<AuthRepository>().isEmailLink(link)) {
          Get.offAllNamed(Routes.finishSignIn, arguments: link);
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Home Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(mobile: !kIsWeb),
      initialRoute: widget.initialLink != null
          ? Routes.finishSignIn
          : Routes.splash,
      getPages: [
        for (final page in kIsWeb ? AppPages.web : AppPages.app)
          kIsWeb &&
                  page.name != Routes.splash &&
                  page.name != Routes.webSignIn &&
                  page.name != Routes.finishSignIn &&
                  page.name != Routes.privacy &&
                  page.name != Routes.terms &&
                  page.name != Routes.checkEmail
              ? page.copy(middlewares: [WebAuthGuard()])
              : page,
      ],
      defaultTransition: kIsWeb
          ? Transition.noTransition
          : Transition.cupertino,
      builder: (context, child) {
        // Text scales to 200% for readability, never beyond.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 2),
          ),
          child: child!,
        );
      },
      onReady: () {
        final link = widget.initialLink;
        if (link != null) {
          Get.offAllNamed(Routes.finishSignIn, arguments: link);
        }
      },
    );
  }
}

/// Website pages need a signed-in user; others go to sign-in.
class WebAuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<VaultStore>()) return null;
    final store = Get.find<VaultStore>();
    if (!store.ready.isCompleted) {
      // Come back to this page once the sign-in state is known.
      return RouteSettings(name: Routes.splash, arguments: route);
    }
    if (store.user.value == null) {
      return const RouteSettings(name: Routes.webSignIn);
    }
    return null;
  }
}
