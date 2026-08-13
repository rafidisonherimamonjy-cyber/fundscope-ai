import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/reference_provider.dart';
import 'routes/app_router.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("fr_FR", null);

  // L'initialisation Firebase est encapsulée et tolérante à l'absence de
  // fichiers de configuration (google-services.json / GoogleService-Info.plist)
  // afin que le prototype démarre même si Firebase n'est pas encore configuré
  // (voir services/push_notification_service.dart et le README pour la mise en place).
  await PushNotificationService.tryInitialize();

  runApp(const ProviderScope(child: FundScopeApp()));
}

class FundScopeApp extends ConsumerWidget {
  const FundScopeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: "FundScope AI",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale("fr"),
      supportedLocales: const [Locale("fr"), Locale("en")],
    );
  }
}
