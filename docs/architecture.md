# Architecture — FundScope AI

## 1. Vue d'ensemble

```
┌─────────────────┐        HTTPS / JSON        ┌──────────────────────┐
│  App Flutter      │  ─────────────────────────▶ │   API FastAPI          │
│  (Android/iOS)     │  ◀───────────────────────── │   (routers REST)       │
└─────────────────┘                              └──────────┬───────────┘
                                                              │
                              ┌───────────────────────────────┼───────────────────────────────┐
                              │                                │                                │
                     ┌────────▼────────┐            ┌──────────▼──────────┐          ┌──────────▼──────────┐
                     │  PostgreSQL/       │            │  Service IA           │          │  Notifications push   │
                     │  SQLite (SQLAlchemy)│           │  (mock / OpenAI)      │          │  (mock / Firebase FCM)│
                     └────────────────┘            └─────────────────────┘          └─────────────────────┘
                                                              ▲
                                                              │ HTML/JS vanilla, sert /api/v1/admin/*
                                                     ┌──────────┴──────────┐
                                                     │  Dashboard Admin       │
                                                     │  (servi par FastAPI)  │
                                                     └─────────────────────┘
```

## 2. Décisions d'architecture clés

### 2.1 Abstraction du fournisseur IA (pattern Strategy)

`app/services/ai/base.py` définit l'interface `AIProvider`. Deux implémentations :
- `MockAIProvider` : heuristiques locales (regex, mots-clés), aucune dépendance externe — utilisée par défaut et dans les tests.
- `OpenAIProvider` : appelle l'API OpenAI en mode JSON structuré, avec repli automatique sur le mock en cas d'échec réseau.

**Pourquoi** : garantir que l'application démarre et fonctionne intégralement (démo, tests, CI) sans clé API, tout en gardant la voie ouverte vers un vrai LLM en une seule variable d'environnement (`AI_PROVIDER`). Ajouter un troisième fournisseur (Mistral, Claude, un modèle auto-hébergé) ne nécessite qu'une nouvelle classe + une entrée dans le dictionnaire `_PROVIDERS` de `ai_service.py`.

### 2.2 Abstraction des notifications push

Même principe (`app/services/push.py`) : `PushClient` abstrait, avec `MockPushClient` (journalisation) et `FCMPushClient` (Firebase Admin SDK réel).

### 2.3 Repository Pattern (backend ET frontend)

- **Backend** : les routers ne manipulent jamais directement SQLAlchemy pour la logique métier complexe — celle-ci est isolée dans `app/services/` (recommandation, notifications).
- **Frontend** : `domain/repositories/` définit des interfaces indépendantes de Dio ; `data/repositories/` les implémente. Les écrans et providers Riverpod ne dépendent que des interfaces.

**Pourquoi** : remplacer une source de données (ex: ajouter du cache local offline-first côté Flutter, ou passer d'un ORM à un autre côté backend) sans modifier la couche présentation/métier.

### 2.4 Moteur de recommandation isolé

`app/services/recommendation.py` calcule un score pondéré (secteur 40%, pays 25%, type de financement 20%, montant 15%). Volontairement simple (rule-based) pour le MVP : rapide, explicable, sans données d'entraînement nécessaires.

**Évolution possible** : remplacer par un modèle de scoring plus avancé (collaborative filtering, embeddings sémantiques sur les TDR) sans changer la signature `compute_relevance_score(preference, call) -> float`, donc sans impact sur les routers qui l'appellent.

### 2.5 SQLite en développement, PostgreSQL en production

Les modèles SQLAlchemy évitent les types spécifiques à un moteur (JSON plutôt que JSONB natif, pas de fonctions PostgreSQL propriétaires), ce qui permet de développer/tester instantanément sans installer de serveur de base de données, tout en restant 100% compatible PostgreSQL en production (juste changer `DATABASE_URL`).

## 3. Pistes d'évolution vers une plateforme SaaS complète

Ce MVP a été conçu pour que les évolutions suivantes n'exigent **pas** de refonte majeure :

| Évolution | Ce qui doit changer | Ce qui NE change PAS |
|---|---|---|
| Multi-tenant (plusieurs organisations clientes) | Ajouter un `tenant_id` sur les tables concernées + middleware de filtrage | L'architecture en couches, les schémas Pydantic |
| Migrations de schéma versionnées | Introduire Alembic à la place de `create_all()` | Les modèles SQLAlchemy eux-mêmes |
| Scraping automatique de nouveaux appels à projets | Ajouter un job planifié (Celery/APScheduler) qui appelle le service IA existant pour analyser les TDR récupérés | Le service IA, le moteur de recommandation, les notifications |
| Recherche sémantique (embeddings) | Ajouter un provider d'embeddings + une table vectorielle (pgvector) | L'interface `AIProvider`, qui peut exposer une méthode `embed()` supplémentaire |
| Abonnements payants / facturation | Ajouter un module `billing` (routers + modèles dédiés) | Le reste de l'application, non couplé à la facturation |
| Offline-first sur mobile | Ajouter une couche de cache local (ex: Drift/SQLite côté Flutter) implémentant les mêmes interfaces `domain/repositories/` | Les écrans et providers Riverpod, qui ne connaissent que ces interfaces |
| Back-office plus riche que le dashboard HTML actuel | Construire une SPA React/Vue consommant les mêmes endpoints `/api/v1/admin/*` | L'API elle-même, déjà conçue comme contrat stable |

## 4. Sécurité — points d'attention avant une mise en production

- Remplacer `SECRET_KEY` par une valeur aléatoire longue, stockée en secret manager (pas dans `.env` versionné).
- Restreindre `CORS_ORIGINS` aux domaines réels (actuellement `["*"]` pour faciliter le développement).
- Ajouter une politique de rate-limiting sur `/auth/login` et `/auth/register` (brute-force).
- Ajouter la vérification d'email à l'inscription (actuellement, un compte est actif immédiatement).
- Chiffrer les données sensibles au repos si hébergé sur une infrastructure mutualisée.
