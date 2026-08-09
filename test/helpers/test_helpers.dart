import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Construye un JWT sin firmar válido para las pruebas (solo se decodifica el
/// payload; la app nunca verifica la firma, eso lo hace el backend).
String fakeJwt({
  DateTime? expiresAt,
  String companyId = 'company-1',
  String userId = 'user-1',
  List<String> permissions = const <String>['*'],
}) {
  String segment(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');

  final DateTime exp =
      expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 24));
  return '${segment(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'})}.'
      '${segment(<String, dynamic>{'user_id': userId, 'company_id': companyId, 'permissions': permissions, 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.'
      'firma-de-prueba';
}

/// Respuesta de login válida.
Map<String, dynamic> loginResponse({
  String? token,
  String name = 'Andrés Pérez',
  String email = 'andres@xyz.com',
  String role = 'Administrador',
  List<String> permissions = const <String>['*'],
}) => <String, dynamic>{
  'message': 'Inicio de sesion exitoso',
  'token': token ?? fakeJwt(permissions: permissions),
  'user': <String, dynamic>{
    'id': 'user-1',
    'name': name,
    'email': email,
    'role': role,
    'permissions': permissions,
  },
};

/// Proyecto tal y como lo devuelve `GET /projects`.
Map<String, dynamic> projectJson({
  String id = 'p1',
  String name = 'Torres del Parque',
  String location = 'Bogotá D.C.',
  double budget = 2500000,
}) => <String, dynamic>{
  'id': id,
  'company_id': 'company-1',
  'name': name,
  'location': location,
  'start_date': '2026-01-01T00:00:00Z',
  'end_date': '2026-12-31T00:00:00Z',
  'budget': budget,
};

/// Respuesta de `GET /dashboard/financial/{project_id}`, con los mismos
/// campos y el mismo orden que la documentación de la API.
Map<String, dynamic> kpisJson({
  String projectId = 'p1',
  double totalBudget = 2500000,
  double totalExpenses = 980000,
  double totalPurchased = 620000,
  double totalInvoiced = 1190000,
  double totalCollected = 700000,
  double totalPaidToProv = 400000,
  double financialVariance = 1520000,
}) => <String, dynamic>{
  'company_id': 'company-1',
  'project_id': projectId,
  'total_budget': totalBudget,
  'total_expenses': totalExpenses,
  'total_purchased': totalPurchased,
  'total_invoiced': totalInvoiced,
  'total_collected': totalCollected,
  'total_paid_to_prov': totalPaidToProv,
  'financial_variance': financialVariance,
};

/// Registro de una petición recibida por [recordingClient].
class RecordedRequest {
  RecordedRequest(this.method, this.url, this.headers, this.body);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  /// Cuerpo decodificado como objeto JSON.
  Map<String, dynamic> get json => jsonDecode(body) as Map<String, dynamic>;
}

/// Cliente HTTP falso que registra las peticiones y responde con [handler].
///
/// [requests] se rellena en orden de llegada, lo que permite afirmar sobre la
/// URL, las cabeceras y el cuerpo enviados.
MockClient recordingClient(
  List<RecordedRequest> requests,
  http.Response Function(RecordedRequest request) handler,
) => MockClient((http.Request request) async {
  final RecordedRequest recorded = RecordedRequest(
    request.method,
    request.url,
    request.headers,
    request.body,
  );
  requests.add(recorded);
  return handler(recorded);
});

/// Respuesta JSON con codificación UTF-8 explícita.
http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
);

/// Respuesta de texto plano codificada en UTF-8, como las que devuelve
/// `http.Error` en Go (sin `charset` en el `Content-Type`).
///
/// Se construye con bytes porque `http.Response(String, …)` codifica en
/// latin-1 cuando el `Content-Type` no declara charset, y eso corrompería las
/// tildes de los mensajes del backend.
http.Response textResponse(String body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(body),
      status,
      headers: <String, String>{'content-type': 'text/plain'},
    );
