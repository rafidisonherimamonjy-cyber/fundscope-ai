import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reference_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common_widgets.dart';

/// Onboarding en plusieurs étapes, exécuté une seule fois après l'inscription
/// (ou modifiable ensuite depuis l'écran Profil). Alimente directement le
/// moteur de recommandation côté backend.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _fundingTypeLabels = {
  "grant": "Subvention",
  "loan": "Prêt",
  "equity": "Investissement",
  "prize": "Concours / Prix",
  "technical_assistance": "Assistance technique",
};

const _languageLabels = {"fr": "Français", "en": "English"};

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final Set<int> _selectedSectors = {};
  final Set<int> _selectedCountries = {};
  final Set<String> _selectedFundingTypes = {};
  double _amountMin = 0;
  double _amountMax = 100000;
  String _language = "fr";
  bool _isSaving = false;

  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    // Pré-remplit les étapes si l'utilisateur a déjà des préférences
    // enregistrées (cas d'une modification depuis l'écran Profil).
    final existing = ref.read(authProvider).valueOrNull?.preferences;
    if (existing != null) {
      _selectedSectors.addAll(existing.sectorIds);
      _selectedCountries.addAll(existing.countryIds);
      _selectedFundingTypes.addAll(existing.fundingTypes);
      if (existing.amountMin != null) _amountMin = existing.amountMin!.toDouble();
      if (existing.amountMax != null) _amountMax = existing.amountMax!.toDouble();
      _language = existing.language;
    }
  }

  void _goNext() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    try {
      final preference = UserPreference(
        sectorIds: _selectedSectors.toList(),
        countryIds: _selectedCountries.toList(),
        fundingTypes: _selectedFundingTypes.toList(),
        amountMin: _amountMin.round(),
        amountMax: _amountMax.round(),
        language: _language,
      );
      await ref.read(savePreferencesUseCaseProvider).call(preference);
      await ref.read(authProvider.notifier).refreshUser();
      // La redirection vers l'Accueil est gérée automatiquement par le
      // routeur dès que `onboardingCompleted` passe à true.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SectorStep(selected: _selectedSectors, onChanged: () => setState(() {})),
                  _CountryStep(selected: _selectedCountries, onChanged: () => setState(() {})),
                  _FundingTypeStep(selected: _selectedFundingTypes, onChanged: () => setState(() {})),
                  _AmountStep(
                    min: _amountMin,
                    max: _amountMax,
                    onChanged: (min, max) => setState(() {
                      _amountMin = min;
                      _amountMax = max;
                    }),
                  ),
                  _LanguageStep(selected: _language, onChanged: (lang) => setState(() => _language = lang)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(onPressed: _goBack, child: const Text("Retour")),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _step == _totalSteps - 1 ? "Terminer" : "Continuer",
                      onPressed: _goNext,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _StepScaffold({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _SectorStep extends ConsumerWidget {
  final Set<int> selected;
  final VoidCallback onChanged;
  const _SectorStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return _StepScaffold(
      title: "Vos secteurs d'intérêt",
      subtitle: "Sélectionnez un ou plusieurs secteurs qui correspondent à votre activité.",
      child: categoriesAsync.when(
        data: (categories) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final isSelected = selected.contains(c.id);
            return FilterChip(
              label: Text(c.name),
              selected: isSelected,
              onSelected: (_) {
                isSelected ? selected.remove(c.id) : selected.add(c.id);
                onChanged();
              },
            );
          }).toList(),
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: "$e"),
      ),
    );
  }
}

class _CountryStep extends ConsumerWidget {
  final Set<int> selected;
  final VoidCallback onChanged;
  const _CountryStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);
    return _StepScaffold(
      title: "Vos pays cibles",
      subtitle: "Dans quels pays recherchez-vous des financements ?",
      child: countriesAsync.when(
        data: (countries) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: countries.map((c) {
            final isSelected = selected.contains(c.id);
            return FilterChip(
              label: Text(c.name),
              selected: isSelected,
              onSelected: (_) {
                isSelected ? selected.remove(c.id) : selected.add(c.id);
                onChanged();
              },
            );
          }).toList(),
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: "$e"),
      ),
    );
  }
}

class _FundingTypeStep extends StatelessWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _FundingTypeStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "Type de financement recherché",
      subtitle: "Quels types de financement vous intéressent ?",
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _fundingTypeLabels.entries.map((entry) {
          final isSelected = selected.contains(entry.key);
          return FilterChip(
            label: Text(entry.value),
            selected: isSelected,
            onSelected: (_) {
              isSelected ? selected.remove(entry.key) : selected.add(entry.key);
              onChanged();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  final double min;
  final double max;
  final void Function(double min, double max) onChanged;
  const _AmountStep({required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "Montant recherché",
      subtitle: "Quelle fourchette de financement correspond à votre projet ?",
      child: Column(
        children: [
          RangeSlider(
            values: RangeValues(min, max),
            min: 0,
            max: 150000,
            divisions: 30,
            labels: RangeLabels("${min.round()} \$", "${max.round()} \$"),
            onChanged: (values) => onChanged(values.start, values.end),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${min.round()} USD"),
              Text("${max.round()} USD"),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _LanguageStep({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "Langue préférée",
      subtitle: "Dans quelle langue souhaitez-vous recevoir vos résumés et notifications ?",
      child: Column(
        children: _languageLabels.entries.map((entry) {
          return RadioListTile<String>(
            value: entry.key,
            groupValue: selected,
            title: Text(entry.value),
            onChanged: (value) => onChanged(value!),
          );
        }).toList(),
      ),
    );
  }
}
