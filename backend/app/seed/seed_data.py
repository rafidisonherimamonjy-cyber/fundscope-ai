"""
Script de génération des données de démonstration pour FundScope AI.

Crée :
    - 10 pays
    - 5 secteurs (catégories)
    - 5 bailleurs de fonds
    - 20 appels à projets (avec analyse IA automatique via le fournisseur configuré)
    - 10 utilisateurs de démonstration (mot de passe commun : "Demo1234!")
    - 1 compte administrateur (voir settings.ADMIN_EMAIL / ADMIN_PASSWORD)
    - quelques favoris pour illustrer la fonctionnalité

Usage :
    cd backend
    python -m app.seed.seed_data
"""
import random
from datetime import datetime, timedelta, timezone

from app.core.config import settings
from app.core.database import Base, SessionLocal, engine
from app.core.security import hash_password
import app.models  # noqa: F401
from app.models.activity import Favorite
from app.models.funding import FundingCall, FundingSource
from app.models.organization import Organization
from app.models.preference import UserPreference
from app.models.reference import Category, Country
from app.models.user import User
from app.services.ai.ai_service import get_ai_provider

random.seed(42)  # rend le jeu de données reproductible d'une exécution à l'autre

COUNTRIES = [
    ("SN", "Sénégal", "Afrique de l'Ouest"),
    ("CI", "Côte d'Ivoire", "Afrique de l'Ouest"),
    ("ML", "Mali", "Afrique de l'Ouest"),
    ("BJ", "Bénin", "Afrique de l'Ouest"),
    ("BF", "Burkina Faso", "Afrique de l'Ouest"),
    ("CM", "Cameroun", "Afrique Centrale"),
    ("MA", "Maroc", "Afrique du Nord"),
    ("TN", "Tunisie", "Afrique du Nord"),
    ("RW", "Rwanda", "Afrique de l'Est"),
    ("FR", "France", "Europe"),
]

CATEGORIES = [
    ("Agriculture", "Agriculture, agroalimentaire, élevage et pêche", "eco"),
    ("Santé", "Santé publique et innovation médicale", "health_and_safety"),
    ("Éducation", "Éducation, formation professionnelle et jeunesse", "school"),
    ("Numérique & Technologie", "Startups tech, digitalisation, innovation", "computer"),
    ("Environnement & Climat", "Énergies renouvelables, climat, économie circulaire", "eco"),
]

FUNDING_SOURCES = [
    ("Fondation Africa Innov", "https://africa-innov.example.org", "Fondation panafricaine soutenant l'entrepreneuriat innovant."),
    ("Agence Française de Développement (AFD)", "https://afd.example.org", "Agence publique de financement du développement."),
    ("Banque Mondiale — Programme PME", "https://worldbank.example.org", "Programme d'appui aux petites et moyennes entreprises."),
    ("Union Européenne — DG INTPA", "https://ec.example.eu", "Direction générale des partenariats internationaux de l'UE."),
    ("Orange Social Venture Prize", "https://orange.example.com", "Concours d'innovation sociale du groupe Orange."),
]

FUNDING_TYPES = ["grant", "loan", "equity", "prize", "technical_assistance"]

# Modèles de titres / TDR combinés par secteur pour générer 20 appels variés et réalistes
CALL_TEMPLATES = [
    {
        "sector": "Agriculture",
        "title": "Appel à projets — Résilience climatique des exploitations agricoles familiales",
        "raw_text": (
            "Le présent appel à projets vise à soutenir les initiatives portées par des coopératives agricoles "
            "et des PME agroalimentaires qui contribuent à renforcer la résilience climatique des petites "
            "exploitations familiales. L'objectif est d'améliorer les rendements et la sécurité alimentaire "
            "tout en réduisant l'empreinte environnementale des pratiques agricoles. Sont éligibles les "
            "coopératives, PME et startups enregistrées depuis plus de 12 mois, disposant d'au moins deux "
            "collaborateurs permanents. Le budget alloué par projet varie entre 8 000 et 45 000 USD sur une "
            "durée de 12 à 18 mois. Les dossiers de candidature doivent inclure un business plan détaillé, un "
            "budget prévisionnel, les statuts de la structure, le registre de commerce (RCCM) et une lettre de "
            "motivation. Date limite : 30/11/2026."
        ),
    },
    {
        "sector": "Agriculture",
        "title": "Concours Jeunes Agripreneurs — Innovation agricole",
        "raw_text": (
            "Ce concours a pour objectif de repérer et d'accompagner les jeunes entrepreneurs de moins de 35 ans "
            "porteurs de projets agricoles innovants (irrigation intelligente, transformation locale, "
            "commercialisation digitale). Peuvent candidater les startups agricoles de moins de 3 ans dirigées "
            "par un(e) jeune entrepreneur(e). Une dotation de 5 000 à 15 000 USD est remise aux lauréats sur "
            "une durée de 6 mois, en complément d'un programme de mentorat. Documents demandés : CV du "
            "porteur de projet, plan d'affaires, pièce d'identité. Deadline : 15/12/2026."
        ),
    },
    {
        "sector": "Santé",
        "title": "Fonds d'innovation pour l'accès aux soins de santé primaires",
        "raw_text": (
            "L'appel à projets vise à améliorer l'accès aux soins de santé primaires dans les zones rurales et "
            "péri-urbaines, à travers des solutions innovantes (télémédecine, cliniques mobiles, chaînes "
            "d'approvisionnement en médicaments). Sont éligibles les ONG, associations et startups de la santé "
            "ayant déjà un prototype ou un service pilote en cours. Le financement accordé va de 10 000 à "
            "60 000 USD pour une durée de 18 à 24 mois. Le dossier doit comprendre : note conceptuelle, budget "
            "prévisionnel, états financiers des deux dernières années, statuts de l'organisation. La date "
            "limite de soumission est fixée au 20/11/2026."
        ),
    },
    {
        "sector": "Santé",
        "title": "Programme d'assistance technique en santé maternelle et infantile",
        "raw_text": (
            "Ce programme d'assistance technique accompagne les associations et structures de santé "
            "communautaire qui œuvrent pour la réduction de la mortalité maternelle et infantile. Il offre un "
            "appui en formation, en équipement et en structuration organisationnelle, sans dotation financière "
            "directe mais avec une valorisation estimée de 20 000 USD par structure accompagnée sur 12 mois. "
            "Éligibilité : associations enregistrées depuis au moins 2 ans, actives dans au moins une région "
            "rurale. Documents requis : statuts, rapport d'activité, lettre de recommandation. Date limite : "
            "10/01/2027."
        ),
    },
    {
        "sector": "Éducation",
        "title": "Appel à projets EdTech pour l'Afrique francophone",
        "raw_text": (
            "L'appel à projets soutient les startups EdTech qui développent des solutions numériques "
            "d'apprentissage adaptées aux réalités de l'Afrique francophone (contenus hors-ligne, "
            "alphabétisation numérique, formation professionnelle à distance). Peuvent candidater les startups "
            "et PME technologiques de moins de 5 ans. Le financement va de 15 000 à 80 000 USD sous forme de "
            "subvention, pour un projet d'une durée de 12 mois. Documents demandés : business plan, CV des "
            "fondateurs, budget prévisionnel, statuts. Deadline : 05/12/2026."
        ),
    },
    {
        "sector": "Éducation",
        "title": "Bourse d'appui à la formation professionnelle des jeunes",
        "raw_text": (
            "Ce programme finance des centres de formation professionnelle et des associations œuvrant pour "
            "l'insertion socio-économique des jeunes de 18 à 30 ans, notamment dans les métiers techniques et "
            "numériques. Sont éligibles les associations et structures d'appui à l'entrepreneuriat justifiant "
            "d'au moins un an d'activité. Montant : 6 000 à 25 000 USD, durée 9 mois. Documents requis : "
            "attestation fiscale, plan d'affaires, CV de l'équipe pédagogique. Date limite : 28/02/2027."
        ),
    },
    {
        "sector": "Numérique & Technologie",
        "title": "Programme d'accélération pour startups technologiques",
        "raw_text": (
            "Ce programme d'accélération vise à soutenir la croissance de startups technologiques à fort "
            "potentiel dans les domaines de la fintech, l'e-commerce et les solutions logicielles B2B. Les "
            "startups éligibles doivent avoir un produit déjà lancé (MVP ou version commerciale) et une équipe "
            "d'au moins 3 personnes. L'accompagnement inclut un investissement en capital (equity) de 20 000 à "
            "100 000 USD en échange d'une prise de participation minoritaire, sur une durée de 24 mois. "
            "Documents requis : pitch deck, business plan, états financiers, statuts, registre de commerce. "
            "Date limite de candidature : 18/12/2026."
        ),
    },
    {
        "sector": "Numérique & Technologie",
        "title": "Prix de l'Innovation Sociale Digitale",
        "raw_text": (
            "Le prix récompense les startups et associations qui développent des solutions numériques à "
            "impact social positif (inclusion financière, accès à l'information, autonomisation des femmes). "
            "Ouvert à toute structure enregistrée depuis moins de 4 ans. Dotation : 10 000 USD pour le premier "
            "prix, 5 000 USD pour le second, remise en une seule fois. Documents demandés : note conceptuelle, "
            "CV du porteur de projet, lettre de motivation. Deadline : 01/12/2026."
        ),
    },
    {
        "sector": "Numérique & Technologie",
        "title": "Fonds d'amorçage pour startups en phase de démarrage",
        "raw_text": (
            "Ce fonds d'amorçage cible les startups technologiques en phase de démarrage (moins de 18 mois "
            "d'existence) ayant besoin d'un premier financement pour valider leur modèle économique. Montant "
            "du prêt à taux zéro : 5 000 à 20 000 USD, remboursable sur 36 mois après un différé de 12 mois. "
            "Éligibilité : startups avec au moins un prototype fonctionnel. Documents requis : business plan, "
            "pièce d'identité, statuts. Date limite : 22/01/2027."
        ),
    },
    {
        "sector": "Environnement & Climat",
        "title": "Appel à projets Énergies Renouvelables en zones rurales",
        "raw_text": (
            "L'appel à projets finance des initiatives d'accès à l'énergie solaire et aux énergies "
            "renouvelables dans les zones rurales non connectées au réseau électrique national. Sont éligibles "
            "les PME, coopératives et ONG ayant une expérience avérée dans le secteur de l'énergie. Le "
            "financement varie de 20 000 à 90 000 USD, sous forme de subvention, pour une durée de 18 mois. "
            "Documents requis : plan d'affaires, budget prévisionnel, statuts, registre de commerce, états "
            "financiers. Date limite : 12/12/2026."
        ),
    },
    {
        "sector": "Environnement & Climat",
        "title": "Programme Économie Circulaire et Gestion des Déchets",
        "raw_text": (
            "Ce programme soutient les entrepreneurs et associations qui développent des solutions de "
            "valorisation des déchets et d'économie circulaire en milieu urbain. Sont éligibles les startups, "
            "PME et associations de moins de 5 ans. Financement : 8 000 à 35 000 USD, durée 12 mois. Documents "
            "demandés : note conceptuelle, business plan, CV de l'équipe, statuts. Deadline : 08/01/2027."
        ),
    },
    {
        "sector": "Environnement & Climat",
        "title": "Concours Climat & Jeunesse — Solutions bas-carbone",
        "raw_text": (
            "Concours destiné aux jeunes entrepreneurs (moins de 35 ans) porteurs de solutions bas-carbone "
            "innovantes (mobilité verte, agriculture régénérative, efficacité énergétique). Dotation : 12 000 "
            "USD pour le lauréat, accompagnement technique inclus sur 6 mois. Documents requis : CV, note "
            "conceptuelle, pièce d'identité. Date limite : 25/11/2026."
        ),
    },
    {
        "sector": "Agriculture",
        "title": "Appui à la transformation agroalimentaire locale",
        "raw_text": (
            "Ce financement soutient les PME de transformation agroalimentaire qui valorisent les filières "
            "locales (céréales, fruits, produits laitiers). Sont éligibles les PME formalisées depuis plus de "
            "2 ans avec un chiffre d'affaires établi. Montant : 25 000 à 70 000 USD, sous forme de prêt à taux "
            "préférentiel, durée 24 mois. Documents requis : états financiers, business plan, registre de "
            "commerce, attestation fiscale. Date limite : 15/01/2027."
        ),
    },
    {
        "sector": "Santé",
        "title": "Appel à projets Santé Numérique et Télémédecine",
        "raw_text": (
            "L'appel à projets cible les startups développant des solutions de télémédecine et de dossiers "
            "médicaux numériques adaptées au contexte local. Éligibilité : startups avec un MVP fonctionnel et "
            "une équipe technique. Financement en subvention : 15 000 à 50 000 USD, durée 15 mois. Documents "
            "demandés : pitch deck, plan d'affaires, CV des fondateurs, statuts. Deadline : 03/12/2026."
        ),
    },
    {
        "sector": "Éducation",
        "title": "Fonds d'appui aux structures d'accompagnement entrepreneurial",
        "raw_text": (
            "Ce fonds soutient les incubateurs, structures d'appui à l'entrepreneuriat et consultants qui "
            "accompagnent des porteurs de projets dans leur structuration. Éligibilité : structures d'appui "
            "enregistrées depuis plus d'un an, ayant déjà accompagné au moins 10 entrepreneurs. Montant : "
            "10 000 à 40 000 USD, durée 12 mois. Documents requis : rapport d'activité, statuts, budget "
            "prévisionnel. Date limite : 19/12/2026."
        ),
    },
    {
        "sector": "Numérique & Technologie",
        "title": "Programme d'incubation Femmes Entrepreneures Tech",
        "raw_text": (
            "Programme dédié aux femmes entrepreneures dans le secteur technologique, combinant incubation, "
            "mentorat et financement d'amorçage. Éligibilité : startups dirigées ou co-dirigées par une femme, "
            "de moins de 3 ans. Dotation : 8 000 à 30 000 USD, durée 12 mois. Documents demandés : business "
            "plan, CV de la fondatrice, pièce d'identité, statuts. Deadline : 29/11/2026."
        ),
    },
    {
        "sector": "Environnement & Climat",
        "title": "Appel à projets Adaptation au Changement Climatique",
        "raw_text": (
            "Ce financement international soutient des projets d'adaptation au changement climatique portés "
            "par des ONG et associations locales, avec un focus sur la gestion de l'eau et la protection des "
            "sols. Éligibilité : ONG et associations enregistrées depuis plus de 3 ans. Montant : 30 000 à "
            "120 000 USD, durée 24 à 36 mois. Documents requis : note conceptuelle, budget prévisionnel, "
            "états financiers, statuts, lettres de recommandation. Date limite : 10/02/2027."
        ),
    },
    {
        "sector": "Agriculture",
        "title": "Prix de l'Agro-Innovation Panafricain",
        "raw_text": (
            "Ce prix panafricain récompense les innovations technologiques appliquées à l'agriculture "
            "(capteurs IoT, applications mobiles pour agriculteurs, drones agricoles). Ouvert aux startups de "
            "toute l'Afrique subsaharienne, de moins de 5 ans. Dotation : 20 000 USD pour le grand gagnant, "
            "visibilité internationale incluse. Documents requis : pitch deck, business plan, CV de l'équipe. "
            "Deadline : 07/01/2027."
        ),
    },
    {
        "sector": "Santé",
        "title": "Programme de Renforcement des Capacités des ONG de Santé",
        "raw_text": (
            "Ce programme d'assistance technique renforce les capacités organisationnelles et financières des "
            "ONG actives dans le secteur de la santé communautaire. Éligibilité : ONG de moins de 5 ans, "
            "actives dans au moins deux régions. Valorisation de l'accompagnement : 18 000 USD, durée 12 mois, "
            "sans versement direct de fonds. Documents requis : statuts, rapport d'activité, attestation "
            "fiscale. Date limite : 14/12/2026."
        ),
    },
    {
        "sector": "Numérique & Technologie",
        "title": "Appel à candidatures — Cybersécurité pour PME Africaines",
        "raw_text": (
            "Cet appel à candidatures cible les startups développant des solutions de cybersécurité "
            "accessibles aux PME africaines. Éligibilité : startups avec un produit en phase pilote. "
            "Financement en subvention : 10 000 à 45 000 USD, durée 12 mois. Documents demandés : business "
            "plan, pitch deck, CV des fondateurs, registre de commerce. Deadline : 26/01/2027."
        ),
    },
]

DEMO_USERS = [
    ("Aïssatou Diop", "aissatou.diop@example.com", "startup", "SN"),
    ("Moussa Traoré", "moussa.traore@example.com", "pme", "ML"),
    ("Fatou Ndiaye", "fatou.ndiaye@example.com", "ong", "SN"),
    ("Kwame Mensah", "kwame.mensah@example.com", "startup", "CI"),
    ("Aminata Koné", "aminata.kone@example.com", "association", "CI"),
    ("Ibrahim Ouédraogo", "ibrahim.ouedraogo@example.com", "cooperative", "BF"),
    ("Chantal Mballa", "chantal.mballa@example.com", "startup", "CM"),
    ("Youssef El Amrani", "youssef.elamrani@example.com", "consultant", "MA"),
    ("Grace Uwase", "grace.uwase@example.com", "structure_appui", "RW"),
    ("Julien Martin", "julien.martin@example.com", "pme", "FR"),
]

DEMO_PASSWORD = "Demo1234!"


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(Country).count() > 0:
            print("Les données existent déjà — seed ignoré (base non vide).")
            return

        print("Création des pays...")
        countries = {}
        for code, name, region in COUNTRIES:
            c = Country(code=code, name=name, region=region)
            db.add(c)
            countries[code] = c
        db.flush()

        print("Création des secteurs...")
        categories = {}
        for name, description, icon in CATEGORIES:
            c = Category(name=name, description=description, icon=icon)
            db.add(c)
            categories[name] = c
        db.flush()

        print("Création des bailleurs...")
        sources = []
        for name, website, description in FUNDING_SOURCES:
            s = FundingSource(
                name=name,
                website=website,
                description=description,
                logo_url=f"https://api.dicebear.com/7.x/initials/svg?seed={name.split()[0]}",
                country_id=random.choice(list(countries.values())).id,
            )
            db.add(s)
            sources.append(s)
        db.flush()

        print("Création des appels à projets (avec analyse IA)...")
        ai_provider = get_ai_provider()
        country_list = list(countries.values())
        now = datetime.now(timezone.utc)

        for i, template in enumerate(CALL_TEMPLATES):
            analysis = ai_provider.analyze_call(template["raw_text"], title=template["title"])
            deadline = now + timedelta(days=random.randint(10, 180))
            target_country = random.choice(country_list) if random.random() > 0.2 else None
            call = FundingCall(
                title=template["title"],
                funding_source_id=random.choice(sources).id,
                category_id=categories[template["sector"]].id,
                country_id=target_country.id if target_country else None,
                funding_type=random.choice(FUNDING_TYPES),
                amount_min=random.choice([5000, 8000, 10000, 15000, 20000]),
                amount_max=random.choice([25000, 40000, 60000, 90000, 120000]),
                currency="USD",
                duration_months=random.choice([6, 9, 12, 18, 24, 36]),
                deadline=deadline,
                raw_text=template["raw_text"],
                source_url="https://example.org/appel-a-projets",
                objective=analysis.objective,
                eligibility=analysis.eligibility,
                documents_required=analysis.documents_required,
                ai_summary=analysis.executive_summary,
                ai_difficulty=analysis.difficulty,
                ai_processed_at=now,
                status="published",
            )
            db.add(call)
        db.flush()

        print("Création des utilisateurs de démonstration...")
        password_hash = hash_password(DEMO_PASSWORD)
        all_category_ids = [c.id for c in categories.values()]
        all_country_ids = [c.id for c in countries.values()]

        created_users = []
        for full_name, email, org_type, country_code in DEMO_USERS:
            org = Organization(
                name=f"{full_name.split()[0]} {org_type.upper()}",
                org_type=org_type,
                country_id=countries[country_code].id,
                sector_id=random.choice(list(categories.values())).id,
            )
            db.add(org)
            db.flush()

            user = User(
                full_name=full_name,
                email=email,
                phone="+000000000",
                password_hash=password_hash,
                organization_id=org.id,
                country_id=countries[country_code].id,
                role="user",
                onboarding_completed=True,
            )
            db.add(user)
            db.flush()

            pref = UserPreference(
                user_id=user.id,
                sector_ids=random.sample(all_category_ids, k=random.randint(1, 3)),
                country_ids=random.sample(all_country_ids, k=random.randint(1, 4)),
                funding_types=random.sample(FUNDING_TYPES, k=random.randint(1, 3)),
                amount_min=random.choice([0, 5000, 10000]),
                amount_max=random.choice([50000, 80000, 150000]),
                language="fr",
            )
            db.add(pref)
            created_users.append(user)

        # Compte administrateur
        admin_org = Organization(name="FundScope AI — Administration", org_type="autre")
        db.add(admin_org)
        db.flush()
        admin_user = User(
            full_name="Administrateur FundScope",
            email=settings.ADMIN_EMAIL,
            password_hash=hash_password(settings.ADMIN_PASSWORD),
            organization_id=admin_org.id,
            role="admin",
            onboarding_completed=True,
        )
        db.add(admin_user)
        db.flush()

        db.flush()

        print("Création de quelques favoris de démonstration...")
        all_calls = db.query(FundingCall).all()
        for user in created_users[:5]:
            for call in random.sample(all_calls, k=random.randint(1, 4)):
                db.add(Favorite(user_id=user.id, funding_call_id=call.id))

        db.commit()
        print("✅ Seed terminé avec succès.")
        print(f"   - {len(countries)} pays, {len(categories)} secteurs, {len(sources)} bailleurs")
        print(f"   - {len(CALL_TEMPLATES)} appels à projets")
        print(f"   - {len(created_users)} utilisateurs de démo (mot de passe : {DEMO_PASSWORD})")
        print(f"   - 1 compte admin : {settings.ADMIN_EMAIL} / {settings.ADMIN_PASSWORD}")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
