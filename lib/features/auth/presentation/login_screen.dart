import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/neon_background.dart';
import '../../../core/widgets/neon_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';

/// Pantalla de inicio de sesión (`POST /login`).
///
/// Incluye «Recordar datos»: al marcarlo, email y contraseña se guardan en el
/// almacenamiento cifrado del dispositivo (Android Keystore / iOS Keychain) y
/// se reponen automáticamente la próxima vez que se abre esta pantalla.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _loadingRemembered = true;

  @override
  void initState() {
    super.initState();
    _restoreRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Prerrellena el formulario con lo guardado por «Recordar datos».
  Future<void> _restoreRememberedCredentials() async {
    final RememberedCredentials? saved = await ref
        .read(authControllerProvider.notifier)
        .rememberedCredentials();
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _emailController.text = saved.email;
        _passwordController.text = saved.password;
        _rememberMe = true;
      }
      _loadingRemembered = false;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!ok || !mounted) return;
    // La navegación la resuelve el `redirect` del router al cambiar el estado
    // de autenticación; aquí solo se confirma al usuario.
    showAppSnackBar(context, 'Bienvenido de nuevo');
  }

  @override
  Widget build(BuildContext context) {
    // `select` mantiene los rebuilds acotados a lo que la vista realmente usa.
    final bool isSubmitting = ref.watch(
      authControllerProvider.select((AuthState s) => s.isSubmitting),
    );
    final String? errorMessage = ref.watch(
      authControllerProvider.select((AuthState s) => s.errorMessage),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: NeonBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _Header(),
                        const SizedBox(height: 34),
                        if (errorMessage != null) ...<Widget>[
                          ErrorBanner(
                            message: errorMessage,
                            onDismiss: ref
                                .read(authControllerProvider.notifier)
                                .clearError,
                          ),
                          const SizedBox(height: 18),
                        ],
                        _EmailField(
                          controller: _emailController,
                          enabled: !isSubmitting && !_loadingRemembered,
                          onSubmitted: _passwordFocus.requestFocus,
                        ),
                        const SizedBox(height: 16),
                        _PasswordField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          enabled: !isSubmitting && !_loadingRemembered,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onSubmitted: _submit,
                        ),
                        const SizedBox(height: 6),
                        _RememberMeRow(
                          value: _rememberMe,
                          enabled: !isSubmitting,
                          onChanged: (bool value) =>
                              setState(() => _rememberMe = value),
                        ),
                        const SizedBox(height: 22),
                        NeonButton(
                          label: 'Iniciar sesión',
                          icon: Icons.login_rounded,
                          isLoading: isSubmitting,
                          onPressed: _loadingRemembered ? null : _submit,
                        ),
                        const SizedBox(height: 26),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // En pantallas bajas (o con el teclado abierto) el logotipo se encoge para
    // que el botón de entrar siga alcanzable sin hacer scroll.
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    return Column(
      children: <Widget>[
        BrandMark(size: compact ? 84 : 120),
        const SizedBox(height: 14),
        const Text(
          AppConfig.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gestiona obras, presupuestos y equipos\ndesde un solo lugar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
    autocorrect: false,
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.deny(RegExp(r'\s')),
    ],
    validator: Validators.email,
    onFieldSubmitted: (_) => onSubmitted(),
    decoration: const InputDecoration(
      labelText: 'Correo electrónico',
      hintText: 'tucorreo@empresa.com',
      prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    obscureText: obscure,
    textInputAction: TextInputAction.done,
    autofillHints: const <String>[AutofillHints.password],
    validator: Validators.password,
    onFieldSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      labelText: 'Contraseña',
      hintText: '••••••••',
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        onPressed: onToggleObscure,
        tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
      ),
    ),
  );
}

/// Fila «Recordar datos». Toda la fila es pulsable, no solo la casilla.
class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: const BorderRadius.all(Radius.circular(10)),
    onTap: enabled ? () => onChanged(!value) : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: value,
            onChanged: enabled
                ? (bool? checked) => onChanged(checked ?? false)
                : null,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recordar datos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (value)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.shield_moon_outlined,
                  size: 15,
                  color: AppColors.cyanNeon,
                ),
                SizedBox(width: 5),
                Text(
                  'Cifrado',
                  style: TextStyle(
                    color: AppColors.cyanNeon,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(Icons.lock_rounded, size: 13, color: AppColors.textDisabled),
      SizedBox(width: 6),
      // `Flexible` + ellipsis: el texto se adapta a pantallas estrechas y a
      // escalas de fuente grandes en lugar de desbordar la fila.
      Flexible(
        child: Text(
          'Conexión segura · Datos cifrados en el dispositivo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textDisabled, fontSize: 11.5),
        ),
      ),
    ],
  );
}
