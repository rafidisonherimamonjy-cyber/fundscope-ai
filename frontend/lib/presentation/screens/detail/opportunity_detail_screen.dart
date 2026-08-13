import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/funding_models.dart';
import '../../providers/favorites_notifications_provider.dart';
import '../../providers/opportunities_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common_widgets.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  final int callId;
  const OpportunityDetailScreen({super.key, required this.callId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(opportunityDetailProvider(callId));

    return Scaffold(
      appBar: AppBar(title: const Text("Détail de l'appel")),
      body: async.when(
        data: (call) => _DetailBody(call: call),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: "$e",
          onRetry: () => ref.invalidate(opportunityDetailProvider(callId)),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final FundingCallDetail call;
  const _DetailBody({required this.call});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  late bool _isFavorite = widget.call.isFavorite;
  bool _togglingFavorite = false;

  Future<void> _toggleFavorite() async {
    setState(() => _togglingFavorite = true);
    try {
      await ref.read(toggleFavoriteUseCaseProvider).call(callId: widget.call.id, currentlyFavorite: _isFavorite);
      setState(() => _isFavorite = !_isFavorite);
      ref.invalidate(favoritesListProvider);
    } finally {
      if (mounted) setState(() => _togglingFavorite = false);
    }
  }

  Future<void> _openOfficialSite() async {
    final url = widget.call.sourceUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final call = widget.call;
    Share.share(
      "${call.title} — ${call.fundingSource.name}\n"
      "Date limite : ${Formatters.date(call.deadline)}\n"
      "${call.sourceUrl ?? ''}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final theme = Theme.of(context);
    final daysLeft = Formatters.daysUntil(call.deadline);
    final isUrgent = daysLeft <= 7 && daysLeft >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(call.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.business, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(call.fundingSource.name, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Badges clés ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(avatar: const Icon(Icons.payments_outlined, size: 15), label: Text(Formatters.amountRange(call.amountMin, call.amountMax, call.currency))),
              Chip(avatar: const Icon(Icons.public, size: 15), label: Text(call.country?.name ?? "International")),
              Chip(avatar: const Icon(Icons.category_outlined, size: 15), label: Text(call.category.name)),
              if (call.durationMonths != null)
                Chip(avatar: const Icon(Icons.timelapse, size: 15), label: Text("${call.durationMonths} mois")),
              if (call.aiDifficulty != null)
                Chip(avatar: const Icon(Icons.speed, size: 15), label: Text("Difficulté : ${call.aiDifficulty}")),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUrgent ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: isUrgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Date limite : ${Formatters.date(call.deadline)} · ${Formatters.daysUntilLabel(call.deadline)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isUrgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (call.aiSummary != null) ...[
            _SectionTitle(icon: Icons.auto_awesome, title: "Résumé IA"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(call.aiSummary!, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),
          ],

          if (call.objective != null) ...[
            _SectionTitle(icon: Icons.flag_outlined, title: "Objectif"),
            const SizedBox(height: 8),
            Text(call.objective!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
          ],

          if (call.eligibility != null) ...[
            _SectionTitle(icon: Icons.checklist_outlined, title: "Critères d'éligibilité"),
            const SizedBox(height: 8),
            Text(call.eligibility!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
          ],

          if (call.documentsRequired.isNotEmpty) ...[
            _SectionTitle(icon: Icons.description_outlined, title: "Documents demandés"),
            const SizedBox(height: 8),
            ...call.documentsRequired.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(doc, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: "Voir le site officiel",
                  icon: Icons.open_in_new,
                  onPressed: call.sourceUrl != null ? _openOfficialSite : null,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _togglingFavorite ? null : _toggleFavorite,
                child: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _share,
                child: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
