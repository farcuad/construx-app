import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../storage/secure_store.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'app_language.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_pt.dart';

/// Idioma elegido por el usuario, recordado entre arranques.
///
/// Arranca en [AppLanguage.fallback] y se corrige en cuanto el almacén
/// devuelve la elección guardada: leer el disco es asíncrono y la app no puede
/// esperar a eso para pintar el primer frame.
class LocaleController extends Notifier<AppLanguage> {
  bool _disposed = false;

  @override
  AppLanguage build() {
    ref.onDispose(() => _disposed = true);
    _restore();
    return AppLanguage.fallback;
  }

  Future<void> _restore() async {
    final String? code = await ref
        .read(secureStoreProvider)
        .read(StorageKeys.language);
    final AppLanguage? saved = AppLanguage.fromCode(code);
    if (saved == null || _disposed) return;
    _apply(saved);
  }

  /// Cambia el idioma de la interfaz y lo recuerda.
  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    _apply(language);
    await ref
        .read(secureStoreProvider)
        .write(StorageKeys.language, language.code);
  }

  void _apply(AppLanguage language) {
    state = language;
    // `Fmt` formatea fechas y montos con instancias de `intl` construidas una
    // sola vez; hay que avisarle para que las rehaga en el idioma nuevo.
    Fmt.locale = language.code;
    // Los validadores se pasan como referencia a método y no pueden leer un
    // provider, así que también se les avisa.
    Validators.messages = stringsFor(language).common.validation;
  }
}

/// Los textos de [language]. Fuera del provider para poder usarlos desde
/// código que no tiene `ref`.
AppStrings stringsFor(AppLanguage language) => switch (language) {
  AppLanguage.es => kStringsEs,
  AppLanguage.pt => kStringsPt,
  AppLanguage.en => kStringsEn,
};

final NotifierProvider<LocaleController, AppLanguage> localeControllerProvider =
    NotifierProvider<LocaleController, AppLanguage>(LocaleController.new);

/// Textos de la interfaz en el idioma activo.
///
/// Se observa con `ref.watch(stringsProvider)`: al cambiar de idioma solo se
/// reconstruyen los widgets que muestran texto, no la app entera.
final Provider<AppStrings> stringsProvider = Provider<AppStrings>(
  (Ref ref) => stringsFor(ref.watch(localeControllerProvider)),
);
