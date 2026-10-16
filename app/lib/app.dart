import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seelocals/core/env/env.dart';
import 'package:seelocals/core/l10n/l10n.dart';
import 'package:seelocals/core/l10n/locale_controller.dart';
import 'package:seelocals/core/router/app_router.dart';
import 'package:seelocals/core/theme/app_theme.dart';

class SeeLocalsApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => Env.isDev
          ? Banner(
              message: Env.flavor.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: child,
            )
          : child!,
    );
  }
}
