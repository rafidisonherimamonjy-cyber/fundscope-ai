/**
 * Tableau de bord admin FundScope AI — JavaScript vanilla (aucune dépendance).
 * Communique avec l'API FastAPI via fetch(), en JSON, avec un token JWT
 * stocké dans localStorage après connexion.
 */
const API_BASE = "/api/v1";

const state = {
  token: localStorage.getItem("fundscope_admin_token") || null,
  countries: [],
  categories: [],
  fundingSources: [],
};

// --- Helpers HTTP ------------------------------------------------------

async function apiFetch(path, options = {}) {
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  if (state.token) headers["Authorization"] = `Bearer ${state.token}`;
  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (res.status === 401 || res.status === 403) {
    logout();
    throw new Error("Session expirée, veuillez vous reconnecter.");
  }
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || `Erreur API (${res.status})`);
  }
  if (res.status === 204) return null;
  return res.json();
}

// --- Authentification ----------------------------------------------------

document.getElementById("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("login-email").value;
  const password = document.getElementById("login-password").value;
  const errorEl = document.getElementById("login-error");
  errorEl.textContent = "";
  try {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) throw new Error("Email ou mot de passe incorrect.");
    const data = await res.json();
    state.token = data.access_token;
    localStorage.setItem("fundscope_admin_token", state.token);

    const me = await apiFetch("/users/me");
    if (me.role !== "admin") {
      errorEl.textContent = "Ce compte n'a pas les droits administrateur.";
      logout();
      return;
    }
    showApp();
  } catch (err) {
    errorEl.textContent = err.message;
  }
});

document.getElementById("logout-btn").addEventListener("click", logout);

function logout() {
  state.token = null;
  localStorage.removeItem("fundscope_admin_token");
  document.getElementById("app").classList.add("hidden");
  document.getElementById("login-screen").classList.remove("hidden");
}

function showApp() {
  document.getElementById("login-screen").classList.add("hidden");
  document.getElementById("app").classList.remove("hidden");
  loadReferenceData().then(() => {
    switchView("dashboard");
  });
}

// --- Navigation ------------------------------------------------------------

document.querySelectorAll(".nav-btn").forEach((btn) => {
  btn.addEventListener("click", () => switchView(btn.dataset.view));
});

function switchView(view) {
  document.querySelectorAll(".nav-btn").forEach((b) => b.classList.toggle("active", b.dataset.view === view));
  document.querySelectorAll(".view").forEach((v) => v.classList.add("hidden"));
  document.getElementById(`view-${view}`).classList.remove("hidden");
  if (view === "dashboard") loadDashboard();
  if (view === "opportunities") loadOpportunities();
  if (view === "users") loadUsers();
}

// --- Données de référence (pour les formulaires) --------------------------

async function loadReferenceData() {
  const [countries, categories, sources] = await Promise.all([
    apiFetch("/countries"),
    apiFetch("/categories"),
    apiFetch("/admin/funding-sources"),
  ]);
  state.countries = countries;
  state.categories = categories;
  state.fundingSources = sources;

  fillSelect("opp-country", countries, "Choisir un pays (optionnel)", true);
  fillSelect("opp-category", categories, "Choisir un secteur");
  fillSelect("opp-funding-source", sources, "Choisir un bailleur");
}

function fillSelect(id, items, placeholder, keepFirstOption = false) {
  const select = document.getElementById(id);
  const firstOption = keepFirstOption ? select.firstElementChild.outerHTML : "";
  select.innerHTML = firstOption + items.map((i) => `<option value="${i.id}">${i.name}</option>`).join("");
}

// --- Vue : Statistiques ------------------------------------------------------

async function loadDashboard() {
  const stats = await apiFetch("/admin/stats");
  document.getElementById("stats-grid").innerHTML = `
    ${statCard(stats.total_users, "Utilisateurs")}
    ${statCard(stats.total_funding_calls, "Appels à projets")}
    ${statCard(stats.total_funding_sources, "Bailleurs")}
    ${statCard(stats.total_favorites, "Favoris enregistrés")}
    ${statCard(stats.calls_expiring_soon, "Deadlines < 7 jours")}
  `;
  renderBarChart("chart-users-country", stats.users_by_country);
  renderBarChart("chart-calls-sector", stats.calls_by_sector);
}

function statCard(value, label) {
  return `<div class="stat-card"><div class="value">${value}</div><div class="label">${label}</div></div>`;
}

function renderBarChart(containerId, dataObj) {
  const entries = Object.entries(dataObj || {});
  const max = Math.max(1, ...entries.map(([, v]) => v));
  const container = document.getElementById(containerId);
  if (entries.length === 0) {
    container.innerHTML = `<p style="color:var(--text-muted); font-size:13px;">Aucune donnée pour le moment.</p>`;
    return;
  }
  container.innerHTML = entries
    .map(
      ([label, value]) => `
      <div class="bar-row">
        <div class="bar-label">${label}</div>
        <div class="bar-track"><div class="bar-fill" style="width:${(value / max) * 100}%"></div></div>
        <div class="bar-value">${value}</div>
      </div>`
    )
    .join("");
}

// --- Vue : Appels à projets --------------------------------------------------

let opportunitiesCache = [];

async function loadOpportunities() {
  opportunitiesCache = await apiFetch("/admin/opportunities");
  const tbody = document.getElementById("opportunities-table-body");
  tbody.innerHTML = opportunitiesCache
    .map(
      (call) => `
      <tr>
        <td>${call.title}</td>
        <td>${call.category?.name || "-"}</td>
        <td>${call.country?.name || "International"}</td>
        <td>${formatAmount(call.amount_min, call.amount_max, call.currency)}</td>
        <td>${formatDate(call.deadline)}</td>
        <td><span class="badge ${call.status}">${call.status}</span></td>
        <td>
          <button class="table-action" onclick="editOpportunity(${call.id})">Modifier</button>
          <button class="table-action danger" onclick="deleteOpportunity(${call.id})">Supprimer</button>
        </td>
      </tr>`
    )
    .join("");
}

function formatAmount(min, max, currency) {
  if (!min && !max) return "-";
  return `${(min || 0).toLocaleString()} - ${(max || 0).toLocaleString()} ${currency}`;
}
function formatDate(iso) {
  return new Date(iso).toLocaleDateString("fr-FR");
}

document.getElementById("add-opportunity-btn").addEventListener("click", () => openOpportunityModal());
document.getElementById("cancel-opportunity-btn").addEventListener("click", closeOpportunityModal);

function openOpportunityModal(call = null) {
  document.getElementById("modal-title").textContent = call ? "Modifier l'appel à projets" : "Nouvel appel à projets";
  document.getElementById("opp-id").value = call?.id || "";
  document.getElementById("opp-title").value = call?.title || "";
  document.getElementById("opp-funding-source").value = call?.funding_source?.id || "";
  document.getElementById("opp-category").value = call?.category?.id || "";
  document.getElementById("opp-country").value = call?.country?.id || "";
  document.getElementById("opp-funding-type").value = call?.funding_type || "grant";
  document.getElementById("opp-amount-min").value = call?.amount_min || "";
  document.getElementById("opp-amount-max").value = call?.amount_max || "";
  document.getElementById("opp-duration").value = call?.duration_months || "";
  document.getElementById("opp-deadline").value = call ? call.deadline.slice(0, 10) : "";
  document.getElementById("opp-source-url").value = call?.source_url || "";
  document.getElementById("opp-raw-text").value = call?.raw_text || "";
  document.getElementById("opp-run-ai").checked = !call; // par défaut coché seulement à la création
  document.getElementById("opportunity-modal").classList.remove("hidden");
}
function closeOpportunityModal() {
  document.getElementById("opportunity-modal").classList.add("hidden");
}

window.editOpportunity = (id) => {
  const call = opportunitiesCache.find((c) => c.id === id);
  if (call) openOpportunityModal(call);
};

window.deleteOpportunity = async (id) => {
  if (!confirm("Supprimer définitivement cet appel à projets ?")) return;
  await apiFetch(`/admin/opportunities/${id}`, { method: "DELETE" });
  loadOpportunities();
};

document.getElementById("opportunity-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const id = document.getElementById("opp-id").value;
  const payload = {
    title: document.getElementById("opp-title").value,
    funding_source_id: Number(document.getElementById("opp-funding-source").value),
    category_id: Number(document.getElementById("opp-category").value),
    country_id: document.getElementById("opp-country").value ? Number(document.getElementById("opp-country").value) : null,
    funding_type: document.getElementById("opp-funding-type").value,
    amount_min: numOrNull(document.getElementById("opp-amount-min").value),
    amount_max: numOrNull(document.getElementById("opp-amount-max").value),
    currency: "USD",
    duration_months: numOrNull(document.getElementById("opp-duration").value),
    deadline: new Date(document.getElementById("opp-deadline").value).toISOString(),
    source_url: document.getElementById("opp-source-url").value || null,
    raw_text: document.getElementById("opp-raw-text").value || null,
    documents_required: [],
    run_ai_analysis: document.getElementById("opp-run-ai").checked,
  };

  try {
    if (id) {
      delete payload.run_ai_analysis;
      await apiFetch(`/admin/opportunities/${id}`, { method: "PUT", body: JSON.stringify(payload) });
    } else {
      await apiFetch("/admin/opportunities", { method: "POST", body: JSON.stringify(payload) });
    }
    closeOpportunityModal();
    loadOpportunities();
  } catch (err) {
    alert(err.message);
  }
});

function numOrNull(value) {
  return value === "" ? null : Number(value);
}

// --- Vue : Utilisateurs -----------------------------------------------------

async function loadUsers() {
  const users = await apiFetch("/admin/users");
  document.getElementById("users-table-body").innerHTML = users
    .map(
      (u) => `
      <tr>
        <td>${u.full_name}</td>
        <td>${u.email}</td>
        <td>${u.organization?.name || "-"}</td>
        <td>${u.country?.name || "-"}</td>
        <td>${u.role}</td>
        <td>${formatDate(u.created_at)}</td>
      </tr>`
    )
    .join("");
}

// --- Démarrage --------------------------------------------------------------

if (state.token) {
  apiFetch("/users/me")
    .then((me) => (me.role === "admin" ? showApp() : logout()))
    .catch(() => logout());
}
