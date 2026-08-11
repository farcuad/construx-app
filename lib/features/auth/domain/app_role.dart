import 'permissions.dart';

/// Los cargos que existen en la constructora.
///
/// Desde que `POST /login` dejó de mandar la lista de permisos, el cargo es lo
/// único que trae la sesión, así que aquí se traduce a lo que cada quien puede
/// ver. El reparto sigue la organización real de una obra: quien compra no
/// aprueba sus propias órdenes, quien está en el almacén no ve la facturación,
/// y el dinero solo lo miran gerencia y contabilidad.
///
/// **Esto no es seguridad, es aseo.** Ocultar un módulo evita que alguien entre
/// a una pantalla que no le sirve; quien de verdad manda es el backend, que
/// revalida el cargo en cada petición y responde 403 si no toca.
enum AppRole {
  /// Manda en la empresa. Ve absolutamente todo.
  administrador(<String>{'administrador', 'admin'}, _administrador),

  /// Dirección: ve toda la operación y el dinero, pero no administra usuarios.
  gerente(<String>{'gerente', 'gerencia', 'director'}, _gerente),

  /// Responsable técnico de la obra: planifica, mide y documenta.
  ingeniero(<String>{'ingeniero', 'ingeniera', 'ingenieria'}, _ingeniero),

  /// Jefe de cuadrilla: asistencia, avance y fotos del día a día.
  supervisor(<String>{'supervisor', 'supervisora', 'capataz'}, _supervisor),

  /// Almacén: existencias y maquinaria.
  almacen(<String>{'almacen', 'almacenista', 'bodega'}, _almacen),

  /// Compras: órdenes y proveedores.
  compras(<String>{'compras', 'comprador', 'abastecimiento'}, _compras),

  /// Contabilidad: gastos, facturas y pagos a contratistas.
  contabilidad(<String>{
    'contabilidad',
    'contador',
    'contadora',
  }, _contabilidad);

  const AppRole(this.aliases, this.permissions);

  /// Cómo puede llamarse este cargo en el backend, ya normalizado.
  final Set<String> aliases;

  /// Lo que puede hacer. Es `const`, así que iniciar sesión no reserva memoria.
  final Set<String> permissions;

  /// Busca el cargo que corresponde a [raw], o `null` si no se reconoce.
  ///
  /// Compara sin tildes ni mayúsculas porque el backend escribe «Almacén» y
  /// aquí no conviene depender de cómo esté acentuado ese día.
  static AppRole? fromName(String raw) {
    final String key = _normalize(raw);
    if (key.isEmpty) return null;
    for (final AppRole role in values) {
      if (role.aliases.contains(key)) return role;
    }
    return null;
  }

  /// Minúsculas y sin tildes.
  static String _normalize(String raw) {
    const Map<int, String> accents = <int, String>{
      0xE1: 'a', // á
      0xE9: 'e', // é
      0xED: 'i', // í
      0xF3: 'o', // ó
      0xFA: 'u', // ú
      0xFC: 'u', // ü
      0xF1: 'n', // ñ
    };
    final StringBuffer buffer = StringBuffer();
    for (final int rune in raw.trim().toLowerCase().runes) {
      buffer.write(accents[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }
}

/// Todo el mundo recibe los avisos dirigidos a él.
const String _notices = Perm.notificationsRead;

/// El comodín: el administrador no necesita lista.
const Set<String> _administrador = <String>{Perm.wildcard};

/// Gerencia ve la operación entera y las cifras, y consulta la plantilla y la
/// auditoría. Crear y borrar usuarios se queda en administración.
const Set<String> _gerente = <String>{
  _notices,
  Perm.dashboardRead,
  Perm.usersRead,
  Perm.auditsRead,
  Perm.projectsCreate,
  Perm.projectsRead,
  Perm.projectsUpdate,
  Perm.clientsCreate,
  Perm.clientsRead,
  Perm.clientsUpdate,
  Perm.budgetsCreate,
  Perm.budgetsRead,
  Perm.budgetsUpdate,
  Perm.budgetsApprove,
  Perm.expensesCreate,
  Perm.expensesRead,
  Perm.expensesUpdate,
  Perm.purchasesCreate,
  Perm.purchasesRead,
  Perm.purchasesUpdate,
  Perm.purchasesApprove,
  Perm.suppliersCreate,
  Perm.suppliersRead,
  Perm.suppliersUpdate,
  Perm.inventoryRead,
  Perm.inventoryManage,
  Perm.equipmentRead,
  Perm.equipmentManage,
  Perm.equipmentAssign,
  Perm.personnelRead,
  Perm.personnelManage,
  Perm.attendanceRead,
  Perm.contractorsRead,
  Perm.contractorsManage,
  Perm.contractorsPay,
  Perm.scheduleRead,
  Perm.scheduleUpdate,
  Perm.progressRead,
  Perm.progressUpdate,
  Perm.photosRead,
  Perm.invoicesCreate,
  Perm.invoicesRead,
  Perm.invoicesUpdate,
  Perm.invoicesCancel,
  Perm.invoicesPay,
  Perm.documentsCreate,
  Perm.documentsRead,
  Perm.documentsUpdate,
};

/// El ingeniero lleva la obra: presupuesta, programa, mide avance y pide
/// material. No factura ni toca clientes: eso es de gerencia y contabilidad.
const Set<String> _ingeniero = <String>{
  _notices,
  Perm.dashboardRead,
  Perm.projectsRead,
  Perm.projectsUpdate,
  Perm.budgetsCreate,
  Perm.budgetsRead,
  Perm.budgetsUpdate,
  Perm.expensesCreate,
  Perm.expensesRead,
  Perm.purchasesCreate,
  Perm.purchasesRead,
  Perm.suppliersRead,
  Perm.inventoryRead,
  Perm.equipmentRead,
  Perm.equipmentAssign,
  Perm.personnelRead,
  Perm.attendanceRead,
  Perm.contractorsRead,
  Perm.scheduleRead,
  Perm.scheduleUpdate,
  Perm.progressCreate,
  Perm.progressRead,
  Perm.progressUpdate,
  Perm.photosUpload,
  Perm.photosRead,
  Perm.photosDelete,
  Perm.documentsCreate,
  Perm.documentsRead,
  Perm.documentsUpdate,
};

/// El supervisor vive en el terreno: pasa lista, reporta avance y hace fotos.
/// Nada de dinero, ni siquiera el panel de cifras.
const Set<String> _supervisor = <String>{
  _notices,
  Perm.projectsRead,
  Perm.personnelRead,
  Perm.attendanceRead,
  Perm.attendanceMark,
  Perm.equipmentRead,
  Perm.inventoryRead,
  Perm.scheduleRead,
  Perm.progressCreate,
  Perm.progressRead,
  Perm.progressUpdate,
  Perm.photosUpload,
  Perm.photosRead,
  Perm.documentsRead,
};

/// Almacén mueve existencias y maquinaria, y consulta qué órdenes vienen en
/// camino para recibirlas.
const Set<String> _almacen = <String>{
  _notices,
  Perm.projectsRead,
  Perm.inventoryRead,
  Perm.inventoryManage,
  Perm.equipmentRead,
  Perm.equipmentManage,
  Perm.equipmentAssign,
  Perm.purchasesRead,
  Perm.suppliersRead,
  Perm.documentsRead,
};

/// Compras levanta órdenes y gestiona proveedores. **No aprueba las suyas**:
/// esa firma es de gerencia, que es lo que separa pedir de autorizar.
const Set<String> _compras = <String>{
  _notices,
  Perm.dashboardRead,
  Perm.projectsRead,
  Perm.purchasesCreate,
  Perm.purchasesRead,
  Perm.purchasesUpdate,
  Perm.suppliersCreate,
  Perm.suppliersRead,
  Perm.suppliersUpdate,
  Perm.suppliersDelete,
  Perm.inventoryRead,
  Perm.budgetsRead,
  Perm.expensesRead,
  Perm.documentsRead,
};

/// Contabilidad lleva gastos, facturas y pagos a contratistas. Ve la obra para
/// saber a qué imputar, pero no la dirige.
const Set<String> _contabilidad = <String>{
  _notices,
  Perm.dashboardRead,
  Perm.projectsRead,
  Perm.clientsRead,
  Perm.clientsUpdate,
  Perm.budgetsRead,
  Perm.expensesCreate,
  Perm.expensesRead,
  Perm.expensesUpdate,
  Perm.expensesDelete,
  Perm.purchasesRead,
  Perm.suppliersRead,
  Perm.suppliersUpdate,
  Perm.contractorsRead,
  Perm.contractorsManage,
  Perm.contractorsPay,
  Perm.invoicesCreate,
  Perm.invoicesRead,
  Perm.invoicesUpdate,
  Perm.invoicesCancel,
  Perm.invoicesPay,
  Perm.documentsCreate,
  Perm.documentsRead,
};
