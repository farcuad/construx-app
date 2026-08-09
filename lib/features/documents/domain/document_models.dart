import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Categoría de documento (`/documents/types`).
@immutable
class DocumentType {
  const DocumentType({
    required this.id,
    required this.name,
    this.description = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? createdAt;

  factory DocumentType.fromJson(Map<String, dynamic> json) => DocumentType(
    id: J.str(json['id']),
    name: J.str(json['name']),
    description: J.str(json['description']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DocumentType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Una versión concreta de un documento (`/documents/versions`).
@immutable
class DocumentVersion {
  const DocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.fileUrl,
    this.fileSize = 0,
    this.fileExtension = '',
    this.changeLog = '',
    this.createdAt,
  });

  final String id;
  final String documentId;
  final int versionNumber;
  final String fileUrl;

  /// Tamaño en bytes.
  final int fileSize;
  final String fileExtension;

  /// Qué cambió respecto de la versión anterior.
  final String changeLog;
  final DateTime? createdAt;

  factory DocumentVersion.fromJson(Map<String, dynamic> json) =>
      DocumentVersion(
        id: J.str(json['id']),
        documentId: J.str(json['document_id']),
        versionNumber: J.intOf(json['version_number'], 1),
        fileUrl: J.str(json['file_url']),
        fileSize: J.intOf(json['file_size']),
        fileExtension: J.str(json['file_extension']),
        changeLog: J.str(json['change_log']),
        createdAt: Fmt.parseDate(json['created_at']),
      );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'document_id': documentId,
    'version_number': versionNumber,
    'file_url': fileUrl,
    'file_size': fileSize,
    'file_extension': fileExtension,
    'change_log': changeLog,
  };
}

/// Documento del proyecto con su historial de versiones (`/documents`).
@immutable
class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.projectId,
    required this.title,
    this.documentTypeId,
    this.description = '',
    this.currentVersion = 1,
    this.status = '',
    this.versions = const <DocumentVersion>[],
  });

  final String id;
  final String projectId;
  final String title;
  final String? documentTypeId;
  final String description;
  final int currentVersion;
  final String status;
  final List<DocumentVersion> versions;

  /// Última versión subida, si el detalle trae el historial.
  DocumentVersion? get latestVersion => versions.isEmpty
      ? null
      : versions.reduce(
          (DocumentVersion a, DocumentVersion b) =>
              b.versionNumber >= a.versionNumber ? b : a,
        );

  factory ProjectDocument.fromJson(Map<String, dynamic> json) =>
      ProjectDocument(
        id: J.str(json['id']),
        projectId: J.str(json['project_id']),
        title: J.str(json['title']),
        documentTypeId: J.strOrNull(json['document_type_id']),
        description: J.str(json['description']),
        currentVersion: J.intOf(json['current_version'], 1),
        status: J.str(json['status']),
        versions: J.list(json['versions'], DocumentVersion.fromJson),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProjectDocument && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
