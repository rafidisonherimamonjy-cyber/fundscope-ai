import 'package:flutter_test/flutter_test.dart';
import 'package:fundscope_ai/core/utils/formatters.dart';

void main() {
  group('Formatters.amountRange', () {
    test('retourne un intervalle formaté quand min et max sont fournis', () {
      final result = Formatters.amountRange(1000, 5000, "USD");
      expect(result, contains("USD"));
      expect(result, contains("-"));
    });

    test('retourne un message par défaut quand aucun montant n\'est fourni', () {
      final result = Formatters.amountRange(null, null, "USD");
      expect(result, "Montant non précisé");
    });
  });

  group('Formatters.daysUntil', () {
    test('retourne un nombre positif pour une date future', () {
      final future = DateTime.now().add(const Duration(days: 10));
      expect(Formatters.daysUntil(future), greaterThanOrEqualTo(9));
    });

    test('retourne un nombre négatif pour une date passée', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      expect(Formatters.daysUntil(past), lessThan(0));
    });
  });

  group('Formatters.daysUntilLabel', () {
    test('affiche "Clôturé" pour une échéance passée', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(Formatters.daysUntilLabel(past), "Clôturé");
    });
  });
}
