import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/funding_models.dart';
import '../../providers/favorites_notifications_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/opportunity_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _query = "";

  Future<void> _removeFavorite(FundingCallCard call) async {
    await ref.read(favoriteRepositoryProvider).remove(call.id);
    ref.invalidate(favoritesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mes favoris")),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: favoritesAsync.when(
        data: (favorites) {
          final filtered = _query.isEmpty
              ? favorites
              : favorites.where((f) => f.title.toLowerCase().contains(_query.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: "Rechercher dans mes favoris...",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.bookmark_border,
                        title: favorites.isEmpty ? "Aucun favori" : "Aucun résultat",
                        message: favorites.isEmpty
                            ? "Enregistrez des appels à projets pour les retrouver ici facilement."
                            : "Essayez avec d'autres mots-clés.",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final call = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(call.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                              ),
                              onDismissed: (_) => _removeFavorite(call),
                              child: OpportunityCard(
                                call: call,
                                onTap: () => context.push("/opportunity/${call.id}"),
                                onToggleFavorite: () => _removeFavorite(call),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: "$e", onRetry: () => ref.invalidate(favoritesListProvider)),
      ),
    );
  }
}
