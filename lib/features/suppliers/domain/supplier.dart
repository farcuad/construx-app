import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Proveedor de materiales o servicios (`/supplier`, en singular en la API).
@immutable
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.nit = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String nit;
  final String address;
  final String phone;
  final String email;
  final DateTime? createdAt;

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: J.str(json['id']),
    name: J.str(json['name']),
    nit: J.str(json['nit']),
    address: J.str(json['address']),
    phone: J.str(json['phone']),
    email: J.str(json['email']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    'nit': nit,
    'address': address,
    'phone': phone,
    'email': email,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Supplier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
