"""
Service orchestrant la notification des utilisateurs lors de l'ajout d'un
nouvel appel à projets : calcule la pertinence pour chaque utilisateur ayant
terminé son onboarding, et notifie ceux dont le score dépasse un seuil.
"""
import logging

from sqlalchemy.orm import Session

from app.models.activity import Notification
from app.models.funding import FundingCall
from app.models.user import User
from app.services.push import get_push_client
from app.services.recommendation import compute_relevance_score

logger = logging.getLogger(__name__)

RELEVANCE_THRESHOLD = 60.0  # score minimum pour déclencher une notification


def notify_matching_users(db: Session, funding_call: FundingCall) -> int:
    """
    Parcourt les utilisateurs actifs ayant terminé l'onboarding, calcule leur
    score de pertinence pour ce nouvel appel, et crée + envoie une
    notification pour ceux au-dessus du seuil.

    Retourne le nombre de notifications créées.
    """
    push_client = get_push_client()
    users = db.query(User).filter(User.is_active.is_(True), User.onboarding_completed.is_(True)).all()

    notified_count = 0
    for user in users:
        score = compute_relevance_score(user.preferences, funding_call)
        if score < RELEVANCE_THRESHOLD:
            continue

        title = "Nouvelle opportunité pour vous 🎯"
        body = f"{funding_call.title} — pertinence {int(score)}%"

        notification = Notification(
            user_id=user.id,
            funding_call_id=funding_call.id,
            title=title,
            body=body,
        )
        db.add(notification)

        if user.fcm_token:
            sent = push_client.send(
                token=user.fcm_token,
                title=title,
                body=body,
                data={"funding_call_id": funding_call.id, "type": "new_opportunity"},
            )
            notification.is_sent = sent
        notified_count += 1

    db.commit()
    logger.info("Notifications créées pour l'appel #%s : %s utilisateur(s)", funding_call.id, notified_count)
    return notified_count
