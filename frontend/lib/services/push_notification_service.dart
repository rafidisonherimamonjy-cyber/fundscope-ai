import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Encapsule l'intégration Firebase Cloud Messaging.
///
/// L'initialisation est volontairement protégée par un try/catch : tant que
/// les fichiers de configuration Firebase (google-services.json côté
/// Android) n'ont pas été ajoutés au projet par l'équipe, l'application doit
/// pouvoir démarrer et fonctionner normalement (sans notifications push).
/// Voir le README pour la procédure de configuration Firebase complète.
class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;

  static Future<void> tryInitialize() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      _initialized = true;
    } catch (e) {
      // Firebase non configuré pour cette plateforme/cet environnement :
      // l'application continue de fonctionner sans notifications push.
      debugPrint("[PushNotificationService] Firebase non initialisé : $e");
    }
  }

  /// Retourne le jeton FCM de l'appareil, ou null si Firebase n'est pas
  /// initialisé. À enregistrer côté backend via `UserRepository.updateMe`
  /// après connexion, afin que le serveur puisse cibler l'appareil lors de
  /// l'envoi de notifications (voir app/services/push.py côté backend).
  static Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Écoute les notifications reçues alors que l'application est au premier
  /// plan (par défaut, iOS/Android n'affichent pas de bannière système dans
  /// ce cas — libre à l'UI d'afficher un SnackBar ou un badge local).
  static Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
