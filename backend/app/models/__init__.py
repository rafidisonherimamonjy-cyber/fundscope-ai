"""
Ce fichier importe explicitement tous les modèles SQLAlchemy afin que
`Base.metadata.create_all()` (voir app/main.py) connaisse l'ensemble des
tables, et que les `relationship(...)` référencées par leur nom de classe
(chaînes de caractères) puissent être résolues correctement.
"""
from app.models.reference import Country, Category         # noqa: F401
from app.models.organization import Organization            # noqa: F401
from app.models.user import User                            # noqa: F401
from app.models.preference import UserPreference             # noqa: F401
from app.models.funding import FundingSource, FundingCall    # noqa: F401
from app.models.activity import Favorite, Notification, ActivityLog  # noqa: F401

__all__ = [
    "Country",
    "Category",
    "Organization",
    "User",
    "UserPreference",
    "FundingSource",
    "FundingCall",
    "Favorite",
    "Notification",
    "ActivityLog",
]
