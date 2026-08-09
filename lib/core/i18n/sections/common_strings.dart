import 'package:flutter/foundation.dart';

/// Elige singular o plural y sustituye `{n}` por la cifra.
///
/// Basta para los tres idiomas de la app, que distinguen solo dos formas. Si
/// algún día entra uno con más (ruso, polaco), esto se queda corto.
String plural(int count, String one, String many) =>
    (count == 1 ? one : many).replaceFirst('{n}', '$count');

/// Sustituye los huecos `{clave}` de una plantilla.
String fill(String template, Map<String, String> values) {
  String result = template;
  for (final MapEntry<String, String> entry in values.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}

/// Palabras que se repiten en varios módulos: acciones, rótulos de campo y
/// estados. Tenerlas una sola vez evita que «Proveedor» se traduzca de tres
/// maneras distintas según la pantalla.
@immutable
class CommonStrings {
  const CommonStrings({
    required this.newItem,
    required this.delete,
    required this.saveChanges,
    required this.total,
    required this.totalUpper,
    required this.project,
    required this.client,
    required this.supplier,
    required this.start,
    required this.end,
    required this.balance,
    required this.pending,
    required this.paid,
    required this.active,
    required this.inactive,
    required this.location,
    required this.budget,
    required this.phone,
    required this.email,
    required this.address,
    required this.amount,
    required this.date,
    required this.quantity,
    required this.description,
    required this.descriptionOptional,
    required this.notesOptional,
    required this.you,
    required this.validation,
  });

  final String newItem;
  final String delete;
  final String saveChanges;
  final String total;

  /// En versalitas, para los rótulos pequeños de las tarjetas.
  final String totalUpper;

  final String project;
  final String client;
  final String supplier;
  final String start;
  final String end;
  final String balance;
  final String pending;
  final String paid;
  final String active;
  final String inactive;
  final String location;
  final String budget;
  final String phone;
  final String email;
  final String address;
  final String amount;
  final String date;
  final String quantity;
  final String description;
  final String descriptionOptional;
  final String notesOptional;

  /// Marca la fila del usuario que ha iniciado sesión.
  final String you;

  final ValidationStrings validation;
}

/// Mensajes de los validadores de formulario.
///
/// Van aparte porque no los consume un widget, sino [Validators], que es
/// estático y no puede leer providers.
@immutable
class ValidationStrings {
  const ValidationStrings({
    required this.requiredField,
    required this.emailEmpty,
    required this.emailInvalid,
    required this.passwordEmpty,
    required this.passwordTooShort,
    required this.amountEmpty,
    required this.amountInvalid,
    required this.amountNegative,
  });

  final String requiredField;
  final String emailEmpty;
  final String emailInvalid;
  final String passwordEmpty;

  /// Con `{n}` como hueco para la longitud mínima.
  final String passwordTooShort;

  final String amountEmpty;
  final String amountInvalid;
  final String amountNegative;
}

const CommonStrings kCommonEs = CommonStrings(
  newItem: 'Nuevo',
  delete: 'Eliminar',
  saveChanges: 'Guardar cambios',
  total: 'Total',
  totalUpper: 'TOTAL',
  project: 'Proyecto',
  client: 'Cliente',
  supplier: 'Proveedor',
  start: 'Inicio',
  end: 'Fin',
  balance: 'Saldo',
  pending: 'Pendiente',
  paid: 'Pagado',
  active: 'Activo',
  inactive: 'Inactivo',
  location: 'Ubicación',
  budget: 'Presupuesto',
  phone: 'Teléfono',
  email: 'Correo electrónico',
  address: 'Dirección',
  amount: 'Monto',
  date: 'Fecha',
  quantity: 'Cantidad',
  description: 'Descripción',
  descriptionOptional: 'Descripción (opcional)',
  notesOptional: 'Notas (opcional)',
  you: 'Tú',
  validation: ValidationStrings(
    requiredField: 'Campo obligatorio',
    emailEmpty: 'Ingresa tu correo electrónico',
    emailInvalid: 'Correo electrónico inválido',
    passwordEmpty: 'Ingresa tu contraseña',
    passwordTooShort: 'Debe tener al menos {n} caracteres',
    amountEmpty: 'Ingresa un monto',
    amountInvalid: 'Monto inválido',
    amountNegative: 'El monto no puede ser negativo',
  ),
);

const CommonStrings kCommonPt = CommonStrings(
  newItem: 'Novo',
  delete: 'Excluir',
  saveChanges: 'Salvar alterações',
  total: 'Total',
  totalUpper: 'TOTAL',
  project: 'Obra',
  client: 'Cliente',
  supplier: 'Fornecedor',
  start: 'Início',
  end: 'Fim',
  balance: 'Saldo',
  pending: 'Pendente',
  paid: 'Pago',
  active: 'Ativo',
  inactive: 'Inativo',
  location: 'Localização',
  budget: 'Orçamento',
  phone: 'Telefone',
  email: 'E-mail',
  address: 'Endereço',
  amount: 'Valor',
  date: 'Data',
  quantity: 'Quantidade',
  description: 'Descrição',
  descriptionOptional: 'Descrição (opcional)',
  notesOptional: 'Observações (opcional)',
  you: 'Você',
  validation: ValidationStrings(
    requiredField: 'Campo obrigatório',
    emailEmpty: 'Digite o seu e-mail',
    emailInvalid: 'E-mail inválido',
    passwordEmpty: 'Digite a sua senha',
    passwordTooShort: 'Deve ter pelo menos {n} caracteres',
    amountEmpty: 'Digite um valor',
    amountInvalid: 'Valor inválido',
    amountNegative: 'O valor não pode ser negativo',
  ),
);

const CommonStrings kCommonEn = CommonStrings(
  newItem: 'New',
  delete: 'Delete',
  saveChanges: 'Save changes',
  total: 'Total',
  totalUpper: 'TOTAL',
  project: 'Project',
  client: 'Client',
  supplier: 'Supplier',
  start: 'Start',
  end: 'End',
  balance: 'Balance',
  pending: 'Pending',
  paid: 'Paid',
  active: 'Active',
  inactive: 'Inactive',
  location: 'Location',
  budget: 'Budget',
  phone: 'Phone',
  email: 'Email',
  address: 'Address',
  amount: 'Amount',
  date: 'Date',
  quantity: 'Quantity',
  description: 'Description',
  descriptionOptional: 'Description (optional)',
  notesOptional: 'Notes (optional)',
  you: 'You',
  validation: ValidationStrings(
    requiredField: 'Required field',
    emailEmpty: 'Enter your email',
    emailInvalid: 'Invalid email',
    passwordEmpty: 'Enter your password',
    passwordTooShort: 'Must be at least {n} characters',
    amountEmpty: 'Enter an amount',
    amountInvalid: 'Invalid amount',
    amountNegative: 'The amount cannot be negative',
  ),
);
