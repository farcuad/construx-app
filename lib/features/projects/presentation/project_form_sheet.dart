import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../clients/application/clients_controller.dart';
import '../../clients/domain/client.dart';
import '../application/projects_controller.dart';
import '../domain/project.dart';

/// Abre el formulario de proyecto como hoja inferior.
///
/// Con [project] edita; sin él, crea.
Future<void> showProjectFormSheet(BuildContext context, {Project? project}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _ProjectFormSheet(project: project),
    );

class _ProjectFormSheet extends ConsumerStatefulWidget {
  const _ProjectFormSheet({this.project});

  final Project? project;

  @override
  ConsumerState<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends ConsumerState<_ProjectFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _budgetController;

  String? _clientId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final Project? project = widget.project;
    _nameController = TextEditingController(text: project?.name ?? '');
    _locationController = TextEditingController(text: project?.location ?? '');
    _budgetController = TextEditingController(
      text: project?.budget == null ? '' : project!.budget!.toStringAsFixed(0),
    );
    _clientId = project?.clientId;
    _startDate = project?.startDate;
    _endDate = project?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial =
        (isStart ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Fecha de inicio' : 'Fecha de fin',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Mantiene el rango coherente sin obligar al usuario a corregirlo.
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'La fecha de fin debe ser posterior al inicio.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final Project payload = Project(
      id: widget.project?.id ?? '',
      name: _nameController.text.trim(),
      clientId: _clientId,
      location: _locationController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      budget: double.tryParse(
        _budgetController.text.trim().replaceAll(',', '.'),
      ),
    );

    try {
      final ProjectsController controller = ref.read(
        projectsControllerProvider.notifier,
      );
      if (_isEditing) {
        await controller.updateProject(payload);
      } else {
        await controller.create(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        _isEditing ? 'Proyecto actualizado' : 'Proyecto creado',
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
    final List<Client> clients =
        ref.watch(clientsControllerProvider).valueOrNull ?? const <Client>[];

    return Padding(
      // Deja el formulario por encima del teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 14),
              Text(
                _isEditing ? 'Editar proyecto' : 'Nuevo proyecto',
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
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) => Validators.required(
                  v,
                  message: 'Ingresa el nombre de la obra',
                ),
                decoration: const InputDecoration(
                  labelText: 'Nombre del proyecto',
                  prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: clients.any((Client c) => c.id == _clientId)
                    ? _clientId
                    : null,
                isExpanded: true,
                dropdownColor: AppColors.surfaceHigh,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.handshake_outlined, size: 20),
                ),
                hint: Text(
                  clients.isEmpty
                      ? 'No hay clientes registrados'
                      : 'Selecciona un cliente',
                  style: const TextStyle(color: AppColors.textDisabled),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final Client client in clients)
                    DropdownMenuItem<String>(
                      value: client.id,
                      child: Text(client.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (String? value) => setState(() => _clientId = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: Icon(Icons.place_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _budgetController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: (String? v) =>
                    Validators.amount(v, isRequired: false),
                decoration: const InputDecoration(
                  labelText: 'Presupuesto',
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DateField(
                      label: 'Inicio',
                      value: _startDate,
                      enabled: !_isSaving,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Fin',
                      value: _endDate,
                      enabled: !_isSaving,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: _isEditing ? 'Guardar cambios' : 'Crear proyecto',
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.event_outlined, size: 20),
      ),
      child: Text(
        value == null ? 'Sin definir' : Fmt.date(value),
        style: TextStyle(
          color: value == null ? AppColors.textDisabled : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    ),
  );
}
