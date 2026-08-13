import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/funding_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_notifications_provider.dart';
import '../../providers/opportunities_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/opportunity_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(FundingCallCard call) async {
    await ref.read(toggleFavoriteUseCaseProvider).call(callId: call.id, currentlyFavorite: call.isFavorite);
    ref.invalidate(favoritesListProvider);
    ref.invalidate(recommendedOpportunitiesProvider);
    ref.invalidate(urgentOpportunitiesProvider);
    ref.invalidate(opportunitiesListProvider);
  }

  void _runSearch(String query) {
    setState(() => _searchActive = query.trim().isNotEmpty);
    ref.read(opportunityFiltersProvider.notifier).updateSearch(query.trim().isEmpty ? null : query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text("Bonjour, ${user?.fullName.split(' ').first ?? ''} 👋"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push("/notifications"),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recommendedOpportunitiesProvider);
          ref.invalidate(urgentOpportunitiesProvider);
          ref.invalidate(opportunitiesListProvider);
          ref.invalidate(favoritesListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Barre de recherche ---
            TextField(
              controller: _searchController,
              onSubmitted: _runSearch,
              onChanged: (v) {
                if (v.isEmpty) _runSearch(v);
              },
              decoration: InputDecoration(
                hintText: "Rechercher un appel à projets...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchActive
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _runSearch("");
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            if (_searchActive)
              _SearchResultsSection(onToggleFavorite: _toggleFavorite)
            else ...[
              const _SectionHeader(title: "Recommandées pour vous", icon: Icons.auto_awesome),
              const SizedBox(height: 12),
              _HorizontalOpportunityList(
                provider: recommendedOpportunitiesProvider,
                onToggleFavorite: _toggleFavorite,
                emptyMessage: "Complétez votre profil pour recevoir des recommandations personnalisées.",
              ),
              const SizedBox(height: 28),
              const _SectionHeader(title: "Date limite proche", icon: Icons.timer_outlined),
              const SizedBox(height: 12),
              _HorizontalOpportunityList(
                provider: urgentOpportunitiesProvider,
                onToggleFavorite: _toggleFavorite,
                emptyMessage: "Aucune échéance urgente pour le moment.",
              ),
              const SizedBox(height: 28),
              const _SectionHeader(title: "Tous les appels", icon: Icons.list_alt),
              const SizedBox(height: 12),
              _AllOpportunitiesList(onToggleFavorite: _toggleFavorite),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

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

class _HorizontalOpportunityList extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<FundingCallCard>> provider;
  final Future<void> Function(FundingCallCard) onToggleFavorite;
  final String emptyMessage;

  const _HorizontalOpportunityList({
    required this.provider,
    required this.onToggleFavorite,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      data: (calls) {
        if (calls.isEmpty) {
          return Text(emptyMessage, style: Theme.of(context).textTheme.bodySmall);
        }
        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: calls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final call = calls[index];
              return SizedBox(
                width: 300,
                child: OpportunityCard(
                  call: call,
                  onTap: () => context.push("/opportunity/${call.id}"),
                  onToggleFavorite: () => onToggleFavorite(call),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 240, child: LoadingView()),
      error: (e, _) => ErrorView(message: "$e"),
    );
  }
}

class _AllOpportunitiesList extends ConsumerWidget {
  final Future<void> Function(FundingCallCard) onToggleFavorite;
  const _AllOpportunitiesList({required this.onToggleFavorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(opportunitiesListProvider);
    return async.when(
      data: (calls) {
        if (calls.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: "Aucun appel à projets",
            message: "Revenez bientôt, de nouvelles opportunités sont ajoutées régulièrement.",
          );
        }
        return Column(
          children: calls
              .map((call) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OpportunityCard(
                      call: call,
                      onTap: () => context.push("/opportunity/${call.id}"),
                      onToggleFavorite: () => onToggleFavorite(call),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingView()),
      error: (e, _) => ErrorView(message: "$e"),
    );
  }
}

class _SearchResultsSection extends ConsumerWidget {
  final Future<void> Function(FundingCallCard) onToggleFavorite;
  const _SearchResultsSection({required this.onToggleFavorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(opportunitiesListProvider);
    return async.when(
      data: (calls) {
        if (calls.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: "Aucun résultat",
            message: "Essayez avec d'autres mots-clés.",
          );
        }
        return Column(
          children: calls
              .map((call) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OpportunityCard(
                      call: call,
                      onTap: () => context.push("/opportunity/${call.id}"),
                      onToggleFavorite: () => onToggleFavorite(call),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingView()),
      error: (e, _) => ErrorView(message: "$e"),
    );
  }
}
