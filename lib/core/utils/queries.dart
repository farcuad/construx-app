import 'formatters.dart';

/// Clave «proyecto + día» que comparten los endpoints con parámetro `date`
/// (`/attendance/{project_id}` y `/progress/{project_id}`).
///
/// Es un `record` porque su `==` es estructural: dos consultas iguales
/// comparten entrada en la caché de Riverpod sin escribir una clase a mano.
typedef ProjectDateQuery = ({String projectId, DateTime date});

/// Construye la clave normalizando la fecha a medianoche, de modo que dos
/// consultas del mismo día no generen dos peticiones por diferir en la hora.
ProjectDateQuery projectDateQuery(String projectId, DateTime date) =>
    (projectId: projectId, date: DateTime(date.year, date.month, date.day));

/// La fecha de la clave en el formato `YYYY-MM-DD` que espera la API.
String queryDate(ProjectDateQuery query) => Fmt.apiDate(query.date);
