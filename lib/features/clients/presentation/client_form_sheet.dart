import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../application/clients_controller.dart';
import '../domain/client.dart';

/// Abre el formulario de cliente como hoja inferior.
///
/// Con [client] edita; sin él, crea.
Future<void> showClientFormSheet(BuildContext context, {Client? client}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _ClientFormSheet(client: client),
    );

class _ClientFormSheet extends ConsumerStatefulWidget {
  const _ClientFormSheet({this.client});

  final Client? client;

  @override
  ConsumerState<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends ConsumerState<_ClientFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nit;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    final Client? client = widget.client;
    _name = TextEditingController(text: client?.name ?? '');
    _nit = TextEditingController(text: client?.nit ?? '');
    _address = TextEditingController(text: client?.address ?? '');
    _phone = TextEditingController(text: client?.phone ?? '');
    _email = TextEditingController(text: client?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _nit.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final Client payload = Client(
      id: widget.client?.id ?? '',
      name: _name.text.trim(),
      nit: _nit.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    );

    try {
      final ClientsController controller = ref.read(
        clientsControllerProvider.notifier,
      );
      if (_isEditing) {
        await controller.updateClient(payload);
      } else {
        await controller.create(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        _isEditing
            ? ref.read(stringsProvider).clients.updated
            : ref.read(stringsProvider).clients.created,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings all = ref.watch(stringsProvider);
    final ClientsStrings strings = all.clients;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isEditing ? strings.formEdit : strings.formNew,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                validator: (String? v) =>
                    Validators.required(v, message: strings.nameRequired),
                decoration: InputDecoration(
                  labelText: strings.name,
                  prefixIcon: const Icon(Icons.business_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nit,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: strings.taxIdField,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: all.common.address,
                  prefixIcon: const Icon(Icons.place_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: all.common.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? null
                    : Validators.email(v),
                decoration: InputDecoration(
                  labelText: all.common.email,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: _isEditing ? all.common.saveChanges : strings.submit,
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
