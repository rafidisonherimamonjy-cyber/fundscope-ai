"""Tests de bout en bout des endpoints d'authentification."""


def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_register_creates_user(client, seeded_country):
    payload = {
        "full_name": "Test User",
        "organization_name": "Test Org",
        "org_type": "startup",
        "country_id": seeded_country.id,
        "email": "test@example.com",
        "phone": "+221000000",
        "password": "SuperSecret123",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "test@example.com"
    assert body["onboarding_completed"] is False


def test_register_duplicate_email_fails(client, seeded_country):
    payload = {
        "full_name": "Test User",
        "organization_name": "Test Org",
        "org_type": "startup",
        "country_id": seeded_country.id,
        "email": "dup@example.com",
        "password": "SuperSecret123",
    }
    first = client.post("/api/v1/auth/register", json=payload)
    assert first.status_code == 201
    second = client.post("/api/v1/auth/register", json=payload)
    assert second.status_code == 409


def test_login_and_access_protected_route(client, seeded_country):
    register_payload = {
        "full_name": "Login User",
        "organization_name": "Login Org",
        "org_type": "pme",
        "country_id": seeded_country.id,
        "email": "login@example.com",
        "password": "SuperSecret123",
    }
    client.post("/api/v1/auth/register", json=register_payload)

    login_response = client.post(
        "/api/v1/auth/login", json={"email": "login@example.com", "password": "SuperSecret123"}
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]

    me_response = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {token}"})
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "login@example.com"


def test_login_wrong_password_fails(client, seeded_country):
    client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Wrong Pass",
            "organization_name": "Org",
            "org_type": "pme",
            "country_id": seeded_country.id,
            "email": "wrong@example.com",
            "password": "CorrectPass123",
        },
    )
    response = client.post("/api/v1/auth/login", json={"email": "wrong@example.com", "password": "IncorrectPass"})
    assert response.status_code == 401


def test_protected_route_without_token_fails(client):
    response = client.get("/api/v1/users/me")
    assert response.status_code == 401
