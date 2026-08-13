import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/detail/opportunity_detail_screen.dart';
import '../presentation/screens/favorites/favorites_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/home/notifications_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

/// Notifie GoRouter à chaque changement de [authProvider], afin que la
/// logique de redirection (voir `redirect` ci-dessous) soit ré-évaluée
/// automatiquement à chaque connexion/déconnexion/onboarding complété.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: "/",
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final loggedIn = user != null;
      final location = state.matchedLocation;

      final isAuthRoute = ["/login", "/register", "/forgot-password"].contains(location);
      final isSplash = location == "/";
      final isOnboarding = location == "/onboarding";

      if (isLoading) {
        return isSplash ? null : "/";
      }
      if (!loggedIn) {
        return isAuthRoute ? null : "/login";
      }
      // Connecté mais onboarding non terminé -> forcer l'onboarding
      if (loggedIn && !user.onboardingCompleted && !isOnboarding) {
        return "/onboarding";
      }
      // Connecté, onboarding terminé -> ne pas rester sur splash/auth/onboarding
      if (loggedIn && user.onboardingCompleted && (isSplash || isAuthRoute || isOnboarding)) {
        return "/home";
      }
      return null;
    },
    routes: [
      GoRoute(path: "/", builder: (context, state) => const SplashScreen()),
      GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
      GoRoute(path: "/register", builder: (context, state) => const RegisterScreen()),
      GoRoute(path: "/forgot-password", builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: "/onboarding", builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: "/home", builder: (context, state) => const HomeScreen()),
      GoRoute(path: "/favorites", builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: "/notifications", builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: "/profile", builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: "/opportunity/:id",
        builder: (context, state) {
          final id = int.parse(state.pathParameters["id"]!);
          return OpportunityDetailScreen(callId: id);
        },
      ),
    ],
  );
});
