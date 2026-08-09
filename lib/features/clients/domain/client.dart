import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';

/// Cliente de la constructora (`/clients`).
@immutable
class Client {
  const Client({
    required this.id,
    required this.name,
    this.nit = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String nit;
  final String address;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime? createdAt;

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nit: json['nit'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: Fmt.parseDate(json['created_at']),
  );

  /// Cuerpo para `POST /clients` y `PUT /clients/{id}`.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    'nit': nit,
    'address': address,
    'phone': phone,
    'email': email,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Client && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
