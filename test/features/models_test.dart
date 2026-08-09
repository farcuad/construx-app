import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/features/attendance/domain/attendance_models.dart';
import 'package:mi_app_constructora/features/budgets/domain/budget.dart';
import 'package:mi_app_constructora/features/contractors/domain/contractor_models.dart';
import 'package:mi_app_constructora/features/expenses/domain/expense.dart';
import 'package:mi_app_constructora/features/inventory/domain/inventory_models.dart';
import 'package:mi_app_constructora/features/invoices/domain/invoice_models.dart';
import 'package:mi_app_constructora/features/personnel/domain/personnel_models.dart';
import 'package:mi_app_constructora/features/purchases/domain/purchase_order.dart';
import 'package:mi_app_constructora/features/subscriptions/domain/subscription.dart';

void main() {
  group('Presupuestos', () {
    test('parsea el ejemplo de la documentación con sus partidas', () {
      final Budget budget = Budget.fromJson(<String, dynamic>{
        'id': 'b1',
        'project_id': 'p1',
        'title': 'Presupuesto obra gruesa',
        'description': 'Aprobado por gerencia',
        'total_amount': 11250,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'category': 'Materiales',
            'description': 'Cemento gris',
            'unit': 'saco',
            'quantity': 500,
            'unit_price': 22.5,
          },
        ],
      });

      expect(budget.title, 'Presupuesto obra gruesa');
      expect(budget.totalAmount, 11250);
      expect(budget.items.single.total, 11250);
    });

    test('el cuerpo de creación manda las partidas anidadas', () {
      const Budget budget = Budget(
        id: '',
        projectId: 'p1',
        title: 'Obra gruesa',
        items: <BudgetItem>[
          BudgetItem(description: 'Cemento', quantity: 2, unitPrice: 10),
        ],
      );

      final Map<String, dynamic> body = budget.toRequestBody();
      expect(body['project_id'], 'p1');
      expect((body['items'] as List<dynamic>).single, <String, dynamic>{
        'category': '',
        'description': 'Cemento',
        'unit': '',
        'quantity': 2.0,
        'unit_price': 10.0,
      });
    });
  });

  group('Gastos', () {
    test('expense_date se manda como YYYY-MM-DD, no en RFC 3339', () {
      final Expense expense = Expense(
        id: '',
        projectId: 'p1',
        title: 'Combustible',
        amount: 350000,
        expenseDate: DateTime(2026, 8, 5),
      );

      expect(expense.toRequestBody()['expense_date'], '2026-08-05');
    });

    test('tolera un importe que llegue como cadena', () {
      final Expense expense = Expense.fromJson(<String, dynamic>{
        'id': 'e1',
        'project_id': 'p1',
        'title': 'Gasto',
        'amount': '350000.50',
      });

      expect(expense.amount, 350000.50);
    });
  });

  group('Órdenes de compra', () {
    test('calcula el importe de línea si el backend no lo manda', () {
      final PurchaseItem item = PurchaseItem.fromJson(<String, dynamic>{
        'description': 'Acero corrugado',
        'quantity': 200,
        'unit_price': 3500,
      });

      expect(item.totalPrice, 700000);
    });

    test('respeta el importe de línea que manda el backend', () {
      final PurchaseItem item = PurchaseItem.fromJson(<String, dynamic>{
        'description': 'Acero corrugado',
        'quantity': 200,
        'unit_price': 3500,
        'total_price': 690000,
      });

      expect(item.totalPrice, 690000, reason: 'puede llevar descuento');
    });

    test('delivery_date viaja como fecha simple', () {
      const PurchaseOrder order = PurchaseOrder(id: '', projectId: 'p1');
      final PurchaseOrder withDate = PurchaseOrder(
        id: order.id,
        projectId: order.projectId,
        deliveryDate: DateTime(2026, 8, 20),
      );

      expect(withDate.toRequestBody()['delivery_date'], '2026-08-20');
    });
  });

  group('Inventario', () {
    test('mapea el tipo de movimiento', () {
      expect(MovementType.fromApi('OUTPUT'), MovementType.output);
      expect(MovementType.fromApi('INPUT'), MovementType.input);
      expect(
        MovementType.fromApi(null),
        MovementType.input,
        reason: 'entrada por defecto si el campo falta',
      );
    });

    test('el movimiento manda movement_type con el valor exacto del API', () {
      const StockMovement movement = StockMovement(
        id: '',
        warehouseId: 'w1',
        materialId: 'm1',
        type: MovementType.output,
        quantity: 50,
      );

      expect(movement.toRequestBody()['movement_type'], 'OUTPUT');
    });
  });

  group('Asistencia', () {
    test('cuenta presentes y horas de la jornada', () {
      final Attendance attendance = Attendance.fromJson(<String, dynamic>{
        'id': 'at1',
        'project_id': 'p1',
        'date': '2026-08-08',
        'logs': <Map<String, dynamic>>[
          <String, dynamic>{
            'employee_id': 'e1',
            'status': 'Present',
            'hours_worked': 8,
          },
          <String, dynamic>{
            'employee_id': 'e2',
            'status': 'Late',
            'hours_worked': 6,
          },
          <String, dynamic>{
            'employee_id': 'e3',
            'status': 'Absent',
            'hours_worked': 0,
          },
        ],
      });

      expect(attendance.date, DateTime(2026, 8, 8));
      expect(attendance.presentCount, 2, reason: 'los tardíos también asisten');
      expect(attendance.totalHours, 14);
    });

    test('«Justified Absence» conserva su valor exacto al reenviarse', () {
      const AttendanceLog log = AttendanceLog(
        employeeId: 'e1',
        status: AttendanceStatus.justifiedAbsence,
      );

      expect(log.toRequestBody()['status'], 'Justified Absence');
    });
  });

  group('Facturas', () {
    Invoice invoice({
      double total = 1190000,
      double? remaining,
      List<Map<String, dynamic>> payments = const <Map<String, dynamic>>[],
      String? dueDate,
      String status = 'Issued',
    }) => Invoice.fromJson(<String, dynamic>{
      'id': 'i1',
      'project_id': 'p1',
      'invoice_number': 'FAC-0001',
      'type': 'EMITTED',
      'status': status,
      'total_amount': total,
      'remaining_amount': remaining,
      'due_date': dueDate,
      'payments': payments,
    });

    test('usa el saldo que manda el backend', () {
      expect(invoice(remaining: 500000).remainingAmount, 500000);
    });

    test('si no viene el saldo, lo deduce de los pagos', () {
      final Invoice i = invoice(
        payments: <Map<String, dynamic>>[
          <String, dynamic>{'id': 'p1', 'invoice_id': 'i1', 'amount': 190000},
        ],
      );

      expect(i.remainingAmount, 1000000);
      expect(i.isPaid, isFalse);
    });

    test('una factura vencida con saldo se marca como tal', () {
      expect(invoice(dueDate: '2020-01-01').isOverdue, isTrue);
    });

    test('una factura pagada no está vencida aunque pasara la fecha', () {
      expect(invoice(remaining: 0, dueDate: '2020-01-01').isOverdue, isFalse);
    });

    test('una factura anulada no está vencida', () {
      final Invoice i = invoice(dueDate: '2020-01-01', status: 'Cancelled');
      expect(i.isCancelled, isTrue);
      expect(i.isOverdue, isFalse);
    });
  });

  group('Contratistas', () {
    test('la proporción pagada sale del saldo restante', () {
      final ContractorContract contract =
          ContractorContract.fromJson(<String, dynamic>{
            'id': 'cc1',
            'contractor_id': 'ct1',
            'project_id': 'p1',
            'title': 'Cimentación',
            'total_amount': 50000000,
            'balance': 40000000,
          });

      expect(contract.paidRatio, 0.2);
    });

    test('sin importe total no hay proporción que calcular', () {
      const ContractorContract contract = ContractorContract(
        id: 'cc1',
        contractorId: 'ct1',
        projectId: 'p1',
        title: 'x',
      );

      expect(contract.paidRatio, isNull);
    });
  });

  group('Personal', () {
    test('el PUT de contrato no reenvía empleado ni proyecto', () {
      const LaborContract contract = LaborContract(
        id: 'lc1',
        employeeId: 'emp1',
        projectId: 'p1',
        salary: 2500000,
      );

      expect(contract.toUpdateBody().containsKey('employee_id'), isFalse);
      expect(contract.toUpdateBody().containsKey('project_id'), isFalse);
      expect(contract.toRequestBody()['employee_id'], 'emp1');
    });

    test('el nombre completo junta nombre y apellidos', () {
      const Employee employee = Employee(
        id: 'e1',
        firstName: 'Carlos',
        lastName: 'Ruiz',
      );

      expect(employee.fullName, 'Carlos Ruiz');
    });
  });

  group('Suscripción', () {
    test('reconoce el estado activo sin importar mayúsculas', () {
      final CompanySubscription sub = CompanySubscription.fromJson(
        <String, dynamic>{'id': 's1', 'status': 'ACTIVE'},
      );

      expect(sub.isActive, isTrue);
    });

    test(
      'los días restantes salen del fin de prueba si no hay fin de plan',
      () {
        final CompanySubscription sub =
            CompanySubscription.fromJson(<String, dynamic>{
              'id': 's1',
              'status': 'trial',
              'trial_end_date': DateTime.now()
                  .add(const Duration(days: 10, hours: 1))
                  .toIso8601String(),
            });

        expect(sub.daysRemaining, 10);
      },
    );
  });
}
