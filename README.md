# FundScope AI 🎯

**Assistant intelligent de recherche de financements et d'appels à projets** — MVP fonctionnel destiné aux entrepreneurs, startups, PME, ONG, associations, structures d'appui à l'entrepreneuriat et consultants.

Ce dépôt contient un prototype **réellement exécutable** (pas une maquette) : un backend API complet, une application mobile Flutter, un tableau de bord d'administration web, et des données de démonstration prêtes à l'emploi.

---

## 📦 Structure du dépôt

```
fundscope-ai/
├── backend/                API FastAPI + PostgreSQL/SQLite + service IA + dashboard admin
├── frontend/               Application mobile Flutter (Android prioritaire)
├── database/               schema.sql — référence du modèle de données PostgreSQL
├── docs/                   Documentation complémentaire (architecture, roadmap)
└── .github/workflows/      build-apk.yml — compilation automatique de l'APK dans le cloud
```

## 🚀 Démarrage rapide

### 1. Backend (API + tableau de bord admin)

```bash
cd backend
python3 -m venv venv && source venv/bin/activate   # Windows : venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env

# Génère la base (SQLite par défaut) et les données de démonstration :
python -m app.seed.seed_data

# Lance le serveur :
uvicorn app.main:app --reload
```

- API + documentation interactive : http://localhost:8000/docs
- Tableau de bord admin : http://localhost:8000/admin
  → connectez-vous avec `admin@fundscope.ai` / `Admin123!` (modifiable dans `.env`)
- Comptes utilisateurs de démo : voir la sortie du script de seed (mot de passe commun `Demo1234!`)

👉 Détails complets : [`backend/README.md`](backend/README.md)

### 2. Application Flutter

```bash
cd frontend
flutter create .        # génère les dossiers natifs android/ ios/ (une seule fois)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` est l'adresse de la machine hôte vue depuis l'émulateur Android. Pour un appareil physique, remplacez par l'adresse IP locale de votre machine (ex: `http://192.168.1.10:8000/api/v1`).

👉 Détails complets (Firebase, build APK, tests) : [`frontend/README.md`](frontend/README.md)

### 3. Obtenir un APK installable — sans installer Flutter

Un workflow GitHub Actions (`.github/workflows/build-apk.yml`) est fourni pour compiler l'APK dans le cloud et le publier automatiquement en tant que **Release GitHub téléchargeable**, sans rien installer sur votre machine :

1. Poussez ce dépôt sur GitHub (public ou privé).
2. Onglet **Actions** → workflow **"Build & Release Android APK"** → **Run workflow**. Renseignez l'URL de votre backend déployé (ou laissez la valeur par défaut si vous testez plus tard).
3. Une fois le build terminé (~5 min), l'APK apparaît dans l'onglet **Releases** du dépôt, avec un lien de téléchargement direct de la forme :
   `https://github.com/<votre-compte>/<votre-repo>/releases/download/apk-<numéro>/fundscope-ai-<numéro>.apk`

Cet APK est signé avec une clé de debug (suffisant pour installer/tester par sideload) — une vraie clé de signature est nécessaire avant une publication sur le Play Store.

---

## 🧭 Parcours utilisateur couvert par le MVP

1. **Inscription** (nom, organisation, pays, secteur, email, téléphone, mot de passe) et **connexion**
2. **Onboarding** en 5 étapes : secteurs d'intérêt, pays cibles, type de financement, montant recherché, langue
3. **Accueil** : opportunités recommandées (scorées par le moteur de recommandation), échéances proches, recherche, liste complète
4. **Détail d'un appel** : résumé exécutif généré par l'IA, objectif, critères d'éligibilité, documents demandés, montant, durée, lien vers le site officiel, favori, partage
5. **Favoris** : liste, recherche, suppression (glisser pour retirer)
6. **Profil** : modification des informations, des préférences de recherche, mode sombre, déconnexion
7. **Notifications** : reçues automatiquement lorsqu'un nouvel appel correspond au profil de l'utilisateur

## 🛠️ Stack technique

| Couche | Choix | Remarque |
|---|---|---|
| Frontend | Flutter 3, Material 3, Riverpod, go_router | Clean Architecture (data / domain / presentation) |
| Backend | FastAPI, SQLAlchemy, Pydantic v2, JWT | Repository pattern, DI via `Depends()` |
| Base de données | PostgreSQL (prod) / SQLite (dev, zéro config) | Bascule via une seule variable d'env `DATABASE_URL` |
| IA | Abstraction `AIProvider` : fournisseur `mock` (local, sans clé) ou `openai` | Changer de fournisseur = 1 ligne dans `.env` |
| Notifications push | Abstraction `PushClient` : `mock` (journalisé) ou `fcm` (Firebase réel) | Même principe que l'IA |
| Admin | Dashboard HTML/CSS/JS vanilla servi par FastAPI | Aucun framework front supplémentaire requis |

## 🧠 Pourquoi cette architecture évolue facilement

- **Aucune dépendance dure à OpenAI ni à Firebase** : tout passe par une interface abstraite (pattern Strategy), remplaçable sans toucher au reste du code — voir `backend/app/services/ai/` et `backend/app/services/push.py`.
- **SQLite en dev / PostgreSQL en prod** sans changement de code (une seule variable d'environnement).
- **Repository pattern des deux côtés** (Flutter et FastAPI) : la logique métier ne connaît jamais directement Dio, HTTP ou SQLAlchemy.
- **Le moteur de recommandation** est isolé dans un seul module (`app/services/recommendation.py`), remplaçable demain par un modèle plus avancé sans changer les routers qui l'utilisent.
- **Le dashboard admin** consomme les mêmes endpoints JSON que n'importe quel futur client (back-office React, app desktop...).

## 📚 Documentation complémentaire

- [`backend/README.md`](backend/README.md) — installation, configuration, tests, endpoints
- [`frontend/README.md`](frontend/README.md) — build Android, configuration Firebase, tests
- [`database/schema.sql`](database/schema.sql) — schéma PostgreSQL de référence, commenté
- [`docs/architecture.md`](docs/architecture.md) — décisions d'architecture et pistes d'évolution vers un SaaS complet

## ⚠️ Limites connues du prototype (assumées pour un MVP)

- Le fournisseur IA par défaut (`mock`) utilise des heuristiques locales plutôt qu'un vrai LLM — suffisant pour démontrer tout le pipeline (extraction + résumé + score) sans clé API, et remplaçable par OpenAI en une ligne de config.
- Les notifications push utilisent par défaut un client `mock` (journalisé, sans envoi réel) — un vrai projet Firebase (fichiers `google-services.json`) est nécessaire pour des notifications réelles sur appareil.
- Le dashboard admin est volontairement minimal (HTML/JS vanilla) : suffisant pour gérer le contenu en démo, à remplacer par un back-office plus riche en production si besoin.
- Les migrations de schéma utilisent `create_all()` (suffisant pour un MVP) plutôt qu'Alembic — recommandé avant une mise en production avec des données réelles.
