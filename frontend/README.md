# FundScope AI — Application mobile (Flutter)

Application Android-first construite avec **Flutter**, **Material 3**, **Riverpod** (state management + injection de dépendances) et **go_router** (navigation), suivant une architecture en couches (Clean Architecture) : `data` / `domain` / `presentation`.

## 1. Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) récent (canal stable recommandé)
- Un backend FundScope AI lancé (voir `../backend/README.md`)
- Android Studio (émulateur) ou un appareil Android physique

## 2. Installation

Ce dépôt contient le code Dart (`lib/`) mais **pas encore les dossiers natifs** `android/` et `ios/` (générés par l'outil `flutter create`, propres à chaque machine/version de SDK) :

```bash
cd frontend
flutter create .          # génère android/, ios/, etc. en conservant lib/ et pubspec.yaml existants
flutter pub get
```

## 3. Lancer l'application

```bash
# Émulateur Android (10.0.2.2 = machine hôte vue depuis l'émulateur) :
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Appareil physique sur le même réseau Wi-Fi (remplacez par l'IP locale de votre machine) :
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Sans ce paramètre, l'application pointe par défaut vers `http://10.0.2.2:8000/api/v1` (voir `lib/core/constants/app_constants.dart`).

## 4. Comptes de test

Après avoir lancé `python -m app.seed.seed_data` côté backend :
- N'importe quel email de la liste des utilisateurs de démo (affichée dans la console lors du seed) / mot de passe `Demo1234!`
- Ou créez un nouveau compte directement depuis l'écran d'inscription

## 5. Notifications push (Firebase Cloud Messaging) — optionnel

L'application démarre et fonctionne normalement sans configuration Firebase (voir `lib/services/push_notification_service.dart`, qui tolère l'absence de configuration). Pour activer les vraies notifications :

1. Créer un projet sur la [console Firebase](https://console.firebase.google.com/)
2. Ajouter une application Android (package name : `com.fundscope.ai`, à ajuster si besoin dans `android/app/build.gradle` après `flutter create .`)
3. Télécharger `google-services.json` et le placer dans `android/app/`
4. Ajouter le plugin Google Services au build Gradle (`android/build.gradle` et `android/app/build.gradle`) — voir la [documentation FlutterFire](https://firebase.google.com/docs/flutter/setup)
5. Configurer côté backend : `NOTIFICATION_PROVIDER=fcm` + `FCM_CREDENTIALS_FILE` (voir `../backend/README.md`)

## 6. Lancer les tests

```bash
flutter test
```

Tests unitaires fournis : validateurs de formulaire (`test/validators_test.dart`) et formatteurs d'affichage (`test/formatters_test.dart`).

## 7. Construire l'APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://votre-domaine-api.com/api/v1
```

L'APK signé (release) se trouve dans `build/app/outputs/flutter-apk/`.

## 8. Architecture du dossier `lib/`

```
lib/
├── core/                  thème Material 3, constantes, client HTTP (Dio), validateurs, formatteurs
├── data/
│   ├── models/            DTOs (sérialisation JSON <-> objets Dart)
│   ├── datasources/       (implicite : appels HTTP via ApiClient dans les repositories)
│   └── repositories/      implémentations concrètes des interfaces du domaine
├── domain/
│   ├── repositories/      interfaces abstraites (contrats), indépendantes de Dio/HTTP
│   └── usecases/          cas d'usage métier (ex: ToggleFavoriteUseCase)
├── presentation/
│   ├── providers/         état applicatif Riverpod (auth, opportunités, favoris, notifications, thème) + câblage DI
│   ├── screens/           les 8 écrans du MVP (splash, auth, onboarding, home, detail, favorites, profile)
│   └── widgets/           composants réutilisables (carte d'opportunité, boutons, états vides/erreur)
├── routes/                configuration go_router + logique de redirection (auth/onboarding)
├── services/              intégrations transverses (notifications push)
└── main.dart               point d'entrée
```

### Pourquoi cette organisation ?

- **`domain/repositories`** ne dépend d'aucun package HTTP : les écrans et providers ne connaissent que ces interfaces, jamais `Dio` directement — cela permet de remplacer la source de données (ex: ajouter un cache local, du offline-first) sans toucher à l'UI.
- **Un seul point de contact avec Dio** : `core/network/api_client.dart`. Toute la gestion du token JWT et des erreurs y est centralisée.
- **Riverpod fait office de conteneur d'injection de dépendances** : voir `presentation/providers/repository_providers.dart`, qui câble chaque repository et cas d'usage — un seul endroit à modifier pour changer une implémentation.
