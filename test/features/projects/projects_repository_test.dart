import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/api_exception.dart';
import 'package:mi_app_constructora/features/projects/data/projects_repository.dart';
import 'package:mi_app_constructora/features/projects/domain/project.dart';
import 'package:mi_app_constructora/features/projects/domain/project_dashboard_model.dart';

import '../../helpers/test_helpers.dart';

void main() {
  ProjectsRepository buildRepository(http.Client client) => ProjectsRepository(
    ApiClient(baseUrl: 'https://api.test', httpClient: client),
  );

  Map<String, dynamic> projectJson({String id = 'p1'}) => <String, dynamic>{
    'id': id,
    'company_id': 'c1',
    'name': 'Edificio Torres del Parque',
    'client_id': 'cli-1',
    'location': 'Bogotá D.C.',
    'start_date': '2026-09-01T00:00:00Z',
    'end_date': '2027-06-30T00:00:00Z',
    'budget': 2500000.00,
    'status_id': 1,
    'created_at': '2026-08-01T10:00:00Z',
  };

  group('fetchAll', () {
    test('mapea la lista de /projects', () async {
      final ProjectsRepository repository = buildRepository(
        MockClient(
          (_) async => jsonResponse(<Map<String, dynamic>>[projectJson()]),
        ),
      );

      final List<Project> projects = await repository.fetchAll();

      expect(projects, hasLength(1));
      final Project project = projects.single;
      expect(project.name, 'Edificio Torres del Parque');
      expect(project.location, 'Bogotá D.C.');
      expect(project.budget, 2500000.0);
      expect(project.startDate, DateTime.utc(2026, 9, 1));
    });

    test('devuelve lista vacía cuando el backend responde null', () async {
      final ProjectsRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );

      expect(await repository.fetchAll(), isEmpty);
    });

    test('propaga el 402 de suscripción inactiva', () async {
      final ProjectsRepository repository = buildRepository(
        MockClient(
          (_) async =>
              textResponse('Suscripción inactiva o expirada', status: 402),
        ),
      );

      await expectLater(
        repository.fetchAll(),
        throwsA(isA<SubscriptionRequiredException>()),
      );
    });
  });

  group('create', () {
    test('envía el cuerpo con las fechas en RFC 3339', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ProjectsRepository repository = buildRepository(
        recordingClient(
          requests,
          (_) => jsonResponse(projectJson(), status: 201),
        ),
      );

      await repository.create(
        Project(
          id: '',
          name: 'Obra nueva',
          clientId: 'cli-1',
          location: 'Medellín',
          startDate: DateTime.utc(2026, 9, 1),
          endDate: DateTime.utc(2027, 6, 30),
          budget: 2500000,
        ),
      );

      final RecordedRequest request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/projects');
      expect(request.json['name'], 'Obra nueva');
      expect(request.json['start_date'], '2026-09-01T00:00:00Z');
      expect(request.json['end_date'], '2027-06-30T00:00:00Z');
      expect(request.json['budget'], 2500000);
    });

    test('omite client_id cuando no hay cliente asignado', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ProjectsRepository repository = buildRepository(
        recordingClient(
          requests,
          (_) => jsonResponse(projectJson(), status: 201),
        ),
      );

      await repository.create(const Project(id: '', name: 'Sin cliente'));

      expect(requests.single.json.containsKey('client_id'), isFalse);
    });

    test('propaga el 402 de límite de proyectos del plan', () async {
      final ProjectsRepository repository = buildRepository(
        MockClient(
          (_) async =>
              textResponse('Límite de proyectos alcanzado', status: 402),
        ),
      );

      await expectLater(
        repository.create(const Project(id: '', name: 'Obra')),
        throwsA(
          isA<SubscriptionRequiredException>().having(
            (SubscriptionRequiredException e) => e.message,
            'message',
            'Límite de proyectos alcanzado',
          ),
        ),
      );
    });
  });

  group('update y delete', () {
    test('update apunta a /projects/{id} con PUT', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ProjectsRepository repository = buildRepository(
        recordingClient(requests, (_) => jsonResponse(projectJson())),
      );

      await repository.update(const Project(id: 'p1', name: 'Renombrada'));

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/projects/p1');
    });

    test('delete apunta a /projects/{id} con DELETE', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ProjectsRepository repository = buildRepository(
        recordingClient(
          requests,
          (_) => jsonResponse(<String, String>{'message': 'recurso eliminado'}),
        ),
      );

      await repository.delete('p1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/projects/p1');
    });

    test('delete propaga el 409 cuando hay datos relacionados', () async {
      final ProjectsRepository repository = buildRepository(
        MockClient(
          (_) async => http.Response('el proyecto tiene datos asociados', 409),
        ),
      );

      await expectLater(
        repository.delete('p1'),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  group('fetchKpis', () {
    test('mapea el dashboard financiero', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ProjectsRepository repository = buildRepository(
        recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{
            'company_id': 'c1',
            'project_id': 'p1',
            'total_budget': 2500000.00,
            'total_expenses': 980000.00,
            'total_purchased': 620000.00,
            'total_invoiced': 1190000.00,
            'total_collected': 700000.00,
            'total_paid_to_prov': 400000.00,
            'financial_variance': 1520000.00,
            'monthly_trends': <Map<String, dynamic>>[
              <String, dynamic>{'month': 'Mar', 'invoiced': 0, 'collected': 0, 'expenses': 0},
              <String, dynamic>{'month': 'Ago', 'invoiced': 1190000, 'collected': 700000, 'expenses': 980000},
            ],
            'expenses_by_category': <Map<String, dynamic>>[
              <String, dynamic>{'category': 'Materiales', 'spent': 520000},
            ],
          }),
        ),
      );

      final ProjectDashboardModel kpis = await repository.fetchKpis('p1');

      expect(requests.single.url.path, '/dashboard/financial/p1');
      expect(kpis.totalBudget, 2500000);
      expect(kpis.totalPaidToProviders, 400000);
      expect(kpis.budgetUsedPercent, closeTo(64, 0.01));
      expect(kpis.isOverBudget, isFalse);
      expect(kpis.monthlyTrends, hasLength(2));
      expect(kpis.monthlyTrends.first.month, 'Mar');
      expect(kpis.expensesByCategory.single.category, 'Materiales');
      expect(kpis.expensesByCategory.single.spent, 520000);
    });

    test(
      'detecta sobrecosto cuando gastos + compras superan el presupuesto',
      () {
        final ProjectDashboardModel kpis = ProjectDashboardModel.fromJson(
          <String, dynamic>{
            'project_id': 'p1',
            'total_budget': 1000,
            'total_expenses': 800,
            'total_purchased': 400,
          },
        );

        expect(kpis.isOverBudget, isTrue);
        expect(kpis.budgetUsedPercent, 120);
      },
    );

    test('sin presupuesto no calcula el porcentaje consumido', () {
      final ProjectDashboardModel kpis = ProjectDashboardModel.fromJson(
        <String, dynamic>{
          'project_id': 'p1',
          'total_budget': 0,
          'total_expenses': 500,
        },
      );

      expect(kpis.budgetUsedPercent, isNull);
      expect(kpis.isOverBudget, isFalse);
    });

    test('sin categorías reparte lo gastado entre rubros por defecto', () {
      final ProjectDashboardModel kpis = ProjectDashboardModel.fromJson(
        <String, dynamic>{
          'project_id': 'p1',
          'total_budget': 1000,
          'total_expenses': 800,
          'total_purchased': 200,
        },
      );

      final List<CategoryExpense> breakdown = kpis.categoryBreakdown;
      expect(breakdown, hasLength(3));
      expect(breakdown.map((CategoryExpense e) => e.category), contains('Materiales'));
      expect(
        breakdown.fold(0.0, (double sum, CategoryExpense e) => sum + e.spent),
        closeTo(kpis.totalSpent, 0.001),
      );
    });
  });

  group('Project · modelo', () {
    test('tolera campos ausentes', () {
      final Project project = Project.fromJson(<String, dynamic>{'id': 'p1'});
      expect(project.name, '');
      expect(project.budget, isNull);
      expect(project.timeProgress, isNull);
    });

    test('acepta el presupuesto como cadena', () {
      final Project project = Project.fromJson(<String, dynamic>{
        'id': 'p1',
        'budget': '2500000.50',
      });
      expect(project.budget, 2500000.50);
    });

    test('timeProgress es 1 cuando el plazo ya terminó', () {
      final Project project = Project(
        id: 'p1',
        name: 'Obra',
        startDate: DateTime.now().subtract(const Duration(days: 20)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(project.timeProgress, 1.0);
    });

    test('timeProgress ronda 0.5 a mitad de plazo', () {
      final Project project = Project(
        id: 'p1',
        name: 'Obra',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(project.timeProgress, closeTo(0.5, 0.01));
    });

    test('copyWith conserva el id y cambia solo lo indicado', () {
      const Project project = Project(
        id: 'p1',
        name: 'Antigua',
        location: 'Cali',
      );
      final Project updated = project.copyWith(name: 'Nueva');

      expect(updated.id, 'p1');
      expect(updated.name, 'Nueva');
      expect(updated.location, 'Cali');
    });
  });

  group('Dashboard · modelo', () {
    test('mapea la tendencia mensual y el desglose por categoría', () {
      final ProjectDashboardModel dashboard = ProjectDashboardModel.fromJson(
        <String, dynamic>{
          'company_id': 'c1',
          'project_id': 'p1',
          'total_budget': 900,
          'total_expenses': 30000,
          'total_purchased': 1199.2,
          'total_invoiced': 11634.81,
          'total_collected': 65000,
          'total_paid_to_prov': 0,
          'financial_variance': -30299.2,
          'monthly_trends': <Map<String, dynamic>>[
            <String, dynamic>{'month': 'Jun', 'invoiced': 0, 'collected': 0, 'expenses': 0},
            <String, dynamic>{'month': 'Aug', 'invoiced': 11669.62, 'collected': 65000, 'expenses': 90000},
          ],
          'expenses_by_category': <Map<String, dynamic>>[
            <String, dynamic>{'category': 'Materiales', 'spent': 18000},
            <String, dynamic>{'category': 'Personal', 'spent': 8000},
            <String, dynamic>{'category': 'Equipos', 'spent': 4000},
          ],
        },
      );

      expect(dashboard.financialVariance, -30299.2);
      expect(dashboard.totalSpent, closeTo(31199.2, 0.001));
      expect(dashboard.monthlyTrends, hasLength(2));
      expect(dashboard.monthlyTrends.last.collected, 65000);
      expect(dashboard.categoryBreakdown, hasLength(3));
      expect(dashboard.categoryBreakdown.first.spent, 18000);
    });

    test('tolera tendencia y categorías ausentes', () {
      final ProjectDashboardModel dashboard = ProjectDashboardModel.fromJson(
        <String, dynamic>{'project_id': 'p1', 'total_expenses': 500},
      );

      expect(dashboard.monthlyTrends, isEmpty);
      expect(dashboard.expensesByCategory, isEmpty);
      expect(dashboard.categoryBreakdown, hasLength(3));
    });

    test('categoryBreakdown respeta el desglose de la API aunque haya datos', () {
      final ProjectDashboardModel dashboard = ProjectDashboardModel.fromJson(
        <String, dynamic>{
          'project_id': 'p1',
          'expenses_by_category': <Map<String, dynamic>>[
            <String, dynamic>{'category': 'Otro', 'spent': 10},
          ],
        },
      );

      expect(dashboard.categoryBreakdown, hasLength(1));
      expect(dashboard.categoryBreakdown.single.category, 'Otro');
    });
  });
}
