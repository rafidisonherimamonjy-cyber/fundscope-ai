import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

/// Écran de démarrage : affiche le logo le temps de vérifier si une session
/// valide existe déjà (token stocké), puis redirige automatiquement via le
/// routeur (voir routes/app_router.dart, qui écoute [authProvider]).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La navigation elle-même est gérée par le redirect de GoRouter, qui
    // observe authProvider. Cet écran se contente d'un affichage de marque
    // pendant que build() (vérification de session) s'exécute.
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: Text(
                "FS",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "FundScope AI",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              "Votre assistant intelligent de financement",
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
