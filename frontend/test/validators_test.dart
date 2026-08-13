import 'package:flutter_test/flutter_test.dart';
import 'package:fundscope_ai/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepte un email valide', () {
      expect(Validators.email("contact@fundscope.ai"), isNull);
    });

    test('rejette un email vide', () {
      expect(Validators.email(""), isNotNull);
    });

    test('rejette un format invalide', () {
      expect(Validators.email("pas-un-email"), isNotNull);
    });
  });

  group('Validators.password', () {
    test('rejette un mot de passe trop court', () {
      expect(Validators.password("123"), isNotNull);
    });

    test('accepte un mot de passe de 6 caractères ou plus', () {
      expect(Validators.password("Demo1234!"), isNull);
    });
  });

  group('Validators.required', () {
    test('rejette une valeur nulle ou vide', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required("   "), isNotNull);
    });

    test('accepte une valeur non vide', () {
      expect(Validators.required("FundScope AI"), isNull);
    });
  });
}
