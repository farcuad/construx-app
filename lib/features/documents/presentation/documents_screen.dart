import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/documents_providers.dart';
import '../domain/document_models.dart';

/// Documentos de la obra (`GET /documents/project/{project_id}`).
///
/// Cada documento se despliega para ver su historial de versiones, que llega
/// dentro de la misma respuesta.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  static const String routeName = 'documents';
  static const String routePath = '/documents';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Documentos',
    currentPath: routePath,
    onRefresh: () {
      ref.invalidate(projectDocumentsProvider);
      ref.invalidate(documentTypesProvider);
    },
    body: ProjectScope(
      emptyMessage: 'Los documentos se archivan por obra.',
      builder: (BuildContext context, Project project) =>
          _DocumentsList(project: project),
    ),
  );
}

class _DocumentsList extends ConsumerWidget {
  const _DocumentsList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectDocument>> documents = ref.watch(
      projectDocumentsProvider(project.id),
    );
    final Map<String, String> types = <String, String>{
      for (final DocumentType t
          in ref.watch(documentTypesProvider).valueOrNull ??
              const <DocumentType>[])
        t.id: t.name,
    };

    return AsyncSection<List<ProjectDocument>>(
      value: documents,
      errorMessage: 'No se pudieron cargar los documentos.',
      onRetry: () => ref.invalidate(projectDocumentsProvider(project.id)),
      builder: (List<ProjectDocument> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.folder_copy_rounded,
              title: 'Sin documentos',
              message: '«${project.name}» no tiene documentos archivados.',
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectDocumentsProvider(project.id)),
              itemBuilder: (BuildContext context, int index) => _DocumentCard(
                document: data[index],
                typeName: types[data[index].documentTypeId],
              ),
            ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, this.typeName});

  final ProjectDocument document;
  final String? typeName;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        iconColor: AppColors.orangeNeon,
        collapsedIconColor: AppColors.textSecondary,
        leading: const LeadingIcon(
          icon: Icons.description_rounded,
          color: AppColors.cyanNeon,
          size: 38,
        ),
        title: Text(
          document.title.isEmpty ? 'Documento' : document.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${typeName ?? 'Sin tipo'} · v${document.currentVersion}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        children: <Widget>[
          if (document.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                document.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          if (document.versions.isEmpty)
            const InfoLine(
              icon: Icons.history_rounded,
              text: 'Sin versiones registradas',
            )
          else
            for (final DocumentVersion v in document.versions)
              _VersionRow(version: v),
        ],
      ),
    ),
  );
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.version});

  final DocumentVersion version;

  /// Tamaño legible. La API lo da en bytes.
  String get _size {
    final int bytes = version.fileSize;
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: <Widget>[
        StatusChip(
          label: 'v${version.versionNumber}',
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                version.changeLog.isEmpty ? 'Sin notas' : version.changeLog,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                ),
              ),
              Text(
                <String>[
                  Fmt.date(version.createdAt),
                  if (version.fileExtension.isNotEmpty)
                    version.fileExtension.toUpperCase(),
                  if (_size.isNotEmpty) _size,
                ].join(' · '),
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
