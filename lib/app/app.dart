import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/data/vault_store.dart';
import '../core/theme/app_theme.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Home Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(mobile: !kIsWeb),
      initialRoute: Routes.splash,
      getPages: [
        for (final page in kIsWeb ? AppPages.web : AppPages.app)
          kIsWeb &&
                  page.name != Routes.splash &&
                  page.name != Routes.webSignIn &&
                  page.name != Routes.privacy &&
                  page.name != Routes.terms
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
