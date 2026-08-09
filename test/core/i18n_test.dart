import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/core/i18n/app_language.dart';
import 'package:mi_app_constructora/core/i18n/app_strings.dart';
import 'package:mi_app_constructora/core/i18n/sections/common_strings.dart';
import 'package:mi_app_constructora/core/i18n/strings_en.dart';
import 'package:mi_app_constructora/core/i18n/strings_es.dart';
import 'package:mi_app_constructora/core/i18n/strings_pt.dart';
import 'package:mi_app_constructora/core/utils/validators.dart';
import 'package:mi_app_constructora/features/home/domain/app_module.dart';

/// Pruebas de las tablas de traducción.
///
/// Que no falte un texto lo garantiza el compilador —[AppStrings] es una clase
/// con campos obligatorios—, así que aquí se comprueba lo que el compilador no
/// ve: que no haya textos vacíos, que los módulos estén todos, y que las
/// plantillas conserven sus huecos al traducirse. Un `{p}` perdido en la
/// versión inglesa saldría en pantalla como una frase a medias.
void main() {
  const Map<AppLanguage, AppStrings> tables = <AppLanguage, AppStrings>{
    AppLanguage.es: kStringsEs,
    AppLanguage.pt: kStringsPt,
    AppLanguage.en: kStringsEn,
  };

  test('hay una tabla por idioma y cada una se declara a sí misma', () {
    expect(tables.length, AppLanguage.values.length);
    for (final MapEntry<AppLanguage, AppStrings> entry in tables.entries) {
      expect(entry.value.language, entry.key);
    }
  });

  test('todos los módulos del menú tienen título en los tres idiomas', () {
    for (final MapEntry<AppLanguage, AppStrings> entry in tables.entries) {
      for (final AppModule module in kAppModules) {
        final String title = entry.value.module(module.id);
        expect(
          title,
          isNotEmpty,
          reason: '«${module.id}» sin traducir en ${entry.key.code}',
        );
      }
    }
  });

  test('las plantillas conservan sus huecos en los tres idiomas', () {
    // Se comparan contra el español, que es el original.
    final List<(String, String Function(AppStrings))> templates =
        <(String, String Function(AppStrings))>[
          ('{p}', (AppStrings s) => s.expenses.emptyMessage),
          ('{p}', (AppStrings s) => s.budgets.emptyMessage),
          ('{p}', (AppStrings s) => s.photos.emptyMessage),
          ('{p}', (AppStrings s) => s.documents.emptyMessage),
          ('{n}', (AppStrings s) => s.expenses.countMany),
          ('{n}', (AppStrings s) => s.users.permissionsCount),
          ('{n}', (AppStrings s) => s.unreadMany),
          ('{t}', (AppStrings s) => s.budgets.deleteMessage),
          ('{a}', (AppStrings s) => s.dashboard.overBudget),
          ('{i}', (AppStrings s) => s.invoices.dates),
          ('{d}', (AppStrings s) => s.invoices.dates),
        ];

    for (final AppStrings table in tables.values) {
      for (final (String hole, String Function(AppStrings) pick) in templates) {
        expect(
          pick(table),
          contains(hole),
          reason:
              'falta el hueco $hole en ${table.language.code}: '
              '«${pick(table)}»',
        );
      }
    }
  });

  test('el plural elige la forma correcta y sustituye la cifra', () {
    expect(plural(1, 'una cosa', '{n} cosas'), 'una cosa');
    expect(plural(4, 'una cosa', '{n} cosas'), '4 cosas');
  });

  test('los mensajes de validación siguen al idioma', () {
    addTearDown(() => Validators.messages = kStringsEs.common.validation);

    Validators.messages = kStringsEn.common.validation;
    expect(Validators.email(''), 'Enter your email');
    expect(Validators.password('abc'), contains('at least 6'));
    expect(Validators.required(' '), 'Required field');

    Validators.messages = kStringsPt.common.validation;
    expect(Validators.amount('x'), 'Valor inválido');
  });
}
