import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/funding_models.dart';

/// Carte représentant un appel à projets dans une liste (Accueil, Favoris,
/// résultats de recherche). Affiche : titre, bailleur, montant, date limite,
/// pays, secteur et score de pertinence, avec un bouton favori rapide.
class OpportunityCard extends StatelessWidget {
  final FundingCallCard call;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const OpportunityCard({
    super.key,
    required this.call,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = Formatters.daysUntil(call.deadline);
    final isUrgent = daysLeft <= 7 && daysLeft >= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FunderLogo(name: call.fundingSource.name, logoUrl: call.fundingSource.logoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          call.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          call.fundingSource.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      call.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: call.isFavorite ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    tooltip: call.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.payments_outlined, label: Formatters.amountRange(call.amountMin, call.amountMax, call.currency)),
                  _InfoChip(icon: Icons.public, label: call.country?.name ?? "International"),
                  _InfoChip(icon: Icons.category_outlined, label: call.category.name),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: isUrgent ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.daysUntilLabel(call.deadline),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUrgent ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  _RelevanceBadge(score: call.relevanceScore),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FunderLogo extends StatelessWidget {
  final String name;
  final String? logoUrl;
  const _FunderLogo({required this.name, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                logoUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsText(theme, initials),
              ),
            )
          : _initialsText(theme, initials),
    );
  }

  Widget _initialsText(ThemeData theme, String initials) {
    return Text(
      initials,
      style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimaryContainer),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _RelevanceBadge extends StatelessWidget {
  final double score;
  const _RelevanceBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score >= 70
        ? Colors.green.shade700
        : score >= 40
            ? Colors.orange.shade800
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            "${score.round()}% pertinent",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
