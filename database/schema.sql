-- ============================================================================
-- FundScope AI — Schéma de base de données PostgreSQL
-- ============================================================================
-- Ce fichier est fourni à titre de référence et de documentation. En usage
-- normal, les tables sont créées automatiquement par SQLAlchemy
-- (Base.metadata.create_all, voir backend/app/main.py). Pour une mise en
-- production sérieuse, remplacez ce mécanisme par des migrations Alembic.
--
-- Usage direct (optionnel) :
--   psql -U fundscope_user -d fundscope -f database/schema.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS countries (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(2) UNIQUE NOT NULL,
    name        VARCHAR(100) UNIQUE NOT NULL,
    region      VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(500),
    icon        VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS organizations (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    org_type    VARCHAR(50) NOT NULL DEFAULT 'startup',
    country_id  INTEGER REFERENCES countries(id),
    sector_id   INTEGER REFERENCES categories(id),
    website     VARCHAR(300),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
    id                     SERIAL PRIMARY KEY,
    full_name              VARCHAR(150) NOT NULL,
    email                  VARCHAR(150) UNIQUE NOT NULL,
    phone                  VARCHAR(30),
    password_hash          VARCHAR(255) NOT NULL,
    organization_id        INTEGER REFERENCES organizations(id),
    country_id             INTEGER REFERENCES countries(id),
    role                   VARCHAR(20) NOT NULL DEFAULT 'user',
    language               VARCHAR(5) NOT NULL DEFAULT 'fr',
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    onboarding_completed   BOOLEAN NOT NULL DEFAULT FALSE,
    fcm_token              VARCHAR(255),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS user_preferences (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sector_ids      JSONB NOT NULL DEFAULT '[]',
    country_ids     JSONB NOT NULL DEFAULT '[]',
    funding_types   JSONB NOT NULL DEFAULT '[]',
    amount_min      INTEGER,
    amount_max      INTEGER,
    language        VARCHAR(5) NOT NULL DEFAULT 'fr'
);

CREATE TABLE IF NOT EXISTS funding_sources (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    logo_url    VARCHAR(500),
    website     VARCHAR(300),
    description TEXT,
    country_id  INTEGER REFERENCES countries(id)
);

CREATE TABLE IF NOT EXISTS funding_calls (
    id                  SERIAL PRIMARY KEY,
    title               VARCHAR(300) NOT NULL,
    funding_source_id   INTEGER NOT NULL REFERENCES funding_sources(id),
    category_id         INTEGER NOT NULL REFERENCES categories(id),
    country_id          INTEGER REFERENCES countries(id),  -- NULL = international
    funding_type        VARCHAR(30) NOT NULL DEFAULT 'grant',
    amount_min          INTEGER,
    amount_max          INTEGER,
    currency            VARCHAR(10) NOT NULL DEFAULT 'USD',
    duration_months     INTEGER,
    deadline            TIMESTAMPTZ NOT NULL,
    raw_text            TEXT,
    source_url          VARCHAR(500),
    objective           TEXT,
    eligibility         TEXT,
    documents_required  JSONB NOT NULL DEFAULT '[]',
    ai_summary          TEXT,
    ai_difficulty       VARCHAR(20),
    ai_processed_at     TIMESTAMPTZ,
    status              VARCHAR(20) NOT NULL DEFAULT 'published',  -- draft | published | closed
    view_count          INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_funding_calls_title ON funding_calls(title);
CREATE INDEX IF NOT EXISTS idx_funding_calls_deadline ON funding_calls(deadline);

CREATE TABLE IF NOT EXISTS favorites (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    funding_call_id INTEGER NOT NULL REFERENCES funding_calls(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, funding_call_id)
);

CREATE TABLE IF NOT EXISTS notifications (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    funding_call_id INTEGER REFERENCES funding_calls(id),
    title           VARCHAR(200) NOT NULL,
    body            VARCHAR(500) NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    is_sent         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS activity_logs (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    details     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- Diagramme relationnel (résumé) :
--
-- countries ─┬─< organizations >─┬─ categories
--            ├─< users           │
--            └─< funding_sources │
--                                │
-- users ─┬─ 1:1 ─ user_preferences
--        ├─< favorites >── funding_calls
--        ├─< notifications
--        └─< activity_logs
--
-- funding_sources ─< funding_calls >─ categories / countries
-- ============================================================================
