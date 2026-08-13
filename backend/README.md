# FundScope AI — Backend

API REST construite avec **FastAPI**, **SQLAlchemy** et **PostgreSQL** (ou **SQLite** en développement), incluant le service d'intelligence artificielle, le moteur de recommandation, les notifications, et un tableau de bord d'administration.

## 1. Installation

```bash
python3 -m venv venv
source venv/bin/activate          # Windows : venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
```

Le fichier `.env` fonctionne tel quel pour un démarrage immédiat (SQLite, IA en mode `mock`, notifications en mode `mock`). Ajustez-le pour PostgreSQL/OpenAI/Firebase — voir la section Configuration ci-dessous.

## 2. Initialiser la base et les données de démonstration

```bash
python -m app.seed.seed_data
```

Ceci crée : 10 pays, 5 secteurs, 5 bailleurs, 20 appels à projets (analysés par le service IA), 10 utilisateurs de démo (mot de passe `Demo1234!`) et 1 compte admin (`admin@fundscope.ai` / `Admin123!` par défaut).

> Le script est idempotent au sens où il ne recrée pas les données si la table `countries` n'est pas vide — supprimez `fundscope.db` (SQLite) pour repartir de zéro.

## 3. Lancer le serveur

```bash
uvicorn app.main:app --reload
```

- Documentation interactive (Swagger) : http://localhost:8000/docs
- Documentation alternative (ReDoc) : http://localhost:8000/redoc
- Tableau de bord admin : http://localhost:8000/admin

## 4. Lancer les tests

```bash
pytest -v
```

Les tests utilisent une base SQLite en mémoire et le fournisseur IA `mock` — aucune dépendance externe requise.

## 5. Configuration (`.env`)

| Variable | Description | Valeurs |
|---|---|---|
| `DATABASE_URL` | Connexion base de données | `sqlite:///./fundscope.db` (dev) ou `postgresql+psycopg2://user:pass@host:5432/db` (prod) |
| `SECRET_KEY` | Clé de signature JWT | chaîne aléatoire longue en production |
| `AI_PROVIDER` | Fournisseur IA actif | `mock` (par défaut, sans clé) ou `openai` |
| `OPENAI_API_KEY` | Clé API OpenAI | requis seulement si `AI_PROVIDER=openai` |
| `NOTIFICATION_PROVIDER` | Canal de notifications push | `mock` (par défaut, journalisé) ou `fcm` |
| `FCM_CREDENTIALS_FILE` | Chemin du fichier de credentials Firebase Admin | requis seulement si `NOTIFICATION_PROVIDER=fcm` |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Compte admin créé par le seed | — |

### Basculer vers PostgreSQL

```bash
# 1. Créer la base et l'utilisateur
psql -U postgres -c "CREATE DATABASE fundscope;"
psql -U postgres -c "CREATE USER fundscope_user WITH PASSWORD 'fundscope_pass';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE fundscope TO fundscope_user;"

# 2. Modifier .env
DATABASE_URL=postgresql+psycopg2://fundscope_user:fundscope_pass@localhost:5432/fundscope

# 3. Relancer le seed
python -m app.seed.seed_data
```

### Activer le vrai fournisseur IA (OpenAI)

```env
AI_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
```

Aucune autre modification n'est nécessaire : `app/services/ai/ai_service.py` sélectionne automatiquement `OpenAIProvider`. En cas d'erreur réseau ou de quota, le service bascule automatiquement sur le fournisseur `mock` pour ne jamais bloquer l'application.

### Activer les vraies notifications push (Firebase)

```env
NOTIFICATION_PROVIDER=fcm
FCM_CREDENTIALS_FILE=/chemin/vers/service-account.json
```

## 6. Aperçu des endpoints principaux

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Créer un compte |
| POST | `/api/v1/auth/login` | Connexion (retourne un JWT) |
| GET | `/api/v1/users/me` | Profil de l'utilisateur connecté |
| PUT | `/api/v1/users/me/preferences` | Enregistrer les préférences (onboarding/profil) |
| GET | `/api/v1/opportunities` | Liste des appels, avec scoring, recherche et filtres |
| GET | `/api/v1/opportunities/{id}` | Détail d'un appel (avec résumé IA) |
| POST/DELETE | `/api/v1/favorites/{id}` | Ajouter / retirer un favori |
| GET | `/api/v1/notifications` | Notifications de l'utilisateur |
| POST | `/api/v1/admin/opportunities` | (admin) Créer un appel + déclencher l'analyse IA + notifier les utilisateurs concernés |
| GET | `/api/v1/admin/stats` | (admin) Statistiques globales |

La liste complète et interactive est disponible sur `/docs`.

## 7. Architecture du dossier `app/`

```
app/
├── core/          configuration, sécurité (JWT/bcrypt), connexion DB, dépendances FastAPI
├── models/        modèles SQLAlchemy (tables)
├── schemas/       schémas Pydantic (validation entrée/sortie API)
├── routers/       endpoints REST, regroupés par domaine métier
├── services/
│   ├── ai/        abstraction du fournisseur IA (mock / openai)
│   ├── push.py    abstraction des notifications push (mock / fcm)
│   ├── recommendation.py   moteur de scoring
│   └── notification_service.py   orchestration : nouvel appel -> qui notifier
├── seed/          génération des données de démonstration
├── static/admin/  tableau de bord admin (HTML/CSS/JS)
└── main.py        point d'entrée FastAPI
```
