import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/favorites_notifications_provider.dart';

/// Barre de navigation inférieure commune aux écrans Accueil, Favoris,
/// Notifications et Profil. Chaque écran racine (route top-level) l'inclut
/// avec son propre index — approche simple et suffisante pour le MVP,
/// qui pourra évoluer vers un `StatefulShellRoute` de go_router si des
/// piles de navigation indépendantes par onglet deviennent nécessaires.
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = ["/home", "/favorites", "/notifications", "/profile"];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => context.go(_routes[index]),
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Accueil"),
        const NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: "Favoris"),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text("$unreadCount"),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: const Icon(Icons.notifications),
          label: "Alertes",
        ),
        const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: "Profil"),
      ],
    );
  }
}
