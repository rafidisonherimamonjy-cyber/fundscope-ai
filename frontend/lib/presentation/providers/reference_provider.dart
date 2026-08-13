import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reference_models.dart';
import 'repository_providers.dart';

final countriesProvider = FutureProvider<List<Country>>((ref) {
  return ref.watch(referenceRepositoryProvider).getCountries();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(referenceRepositoryProvider).getCategories();
});

/// Préférence d'affichage du mode sombre / clair (par défaut : celui du système).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
