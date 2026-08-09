# Construx — App móvil

App Flutter del ERP de constructoras **Construx**. Consume la API documentada en
[`API_DOCUMENTATION.md`](API_DOCUMENTATION.md).

- **Backend:** el de `API_URL` en el [`.env`](#configuración-el-env) (sin prefijo `/api`)
- **Archivos:** Supabase Storage, para las fotos de obra
- **Tema:** negro + naranja con acentos neón
- **Estado:** Riverpod · **Navegación:** go_router · **HTTP:** package:http

> **Es la app de los trabajadores.** El alta de empresas y el panel del
> superadministrador se hacen desde la web y **no** están aquí: ver
> [Lo que la app no hace](#lo-que-la-app-no-hace-a-propósito).

> El identificador del paquete Dart sigue siendo `mi_app_constructora` (el
> nombre con el que se creó el proyecto). Cambiarlo obligaría a reescribir
> todos los `import` y el `applicationId` de Android, así que solo se renombró
> lo que ve el usuario: `AppConfig.appName`, `android:label` y
> `CFBundleDisplayName`.

---

## Puesta en marcha

```bash
cp .env.example .env        # y rellena los valores
flutter pub get
flutter run                 # depuración en el dispositivo conectado
flutter test                # 300 pruebas
flutter analyze             # análisis estático
```

### Configuración: el `.env`

Toda la configuración de entorno sale del `.env` de la raíz, que se declara
como asset en `pubspec.yaml` y se carga en `main()` con `AppConfig.load()`.

| Variable | Para qué |
|---|---|
| `API_URL` | host del ERP. Todos los endpoints cuelgan de aquí, sin `/api`. |
| `SUPABASE_URL` | proyecto de Supabase donde se suben las fotos. |
| `SUPABASE_ANON_KEY` | clave **publicable** de ese proyecto. |
| `SUPABASE_BUCKET` | bucket de Storage. Opcional: por defecto `photos`. |

Orden de precedencia: `--dart-define` → `.env` → valor por defecto en
`AppConfig`. El `--dart-define` sigue existiendo para builds de CI que apunten
a otro entorno sin tocar el archivo:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://staging.example
```

⚠️ **El `.env` viaja dentro del APK** (es un asset, y un APK se descomprime con
`unzip`). Solo puede contener claves publicables — la `anon key` de Supabase lo
es, porque el acceso real lo deciden las políticas RLS del bucket. **Nunca**
metas ahí una `service_role` ni secretos de servidor.

⚠️ `.env` está en `.gitignore`, así que un clon nuevo **no compila** hasta que
alguien lo cree. Por eso está versionado `.env.example`: cópialo y rellénalo.
Si el archivo falta en tiempo de ejecución, `AppConfig.load()` no revienta —
se cae a los valores por defecto.

### Iconos de la app

El logotipo vive en `public/`. Si lo cambias, regenera los iconos de lanzador:

```bash
dart run flutter_launcher_icons
```

| Archivo | Para qué sirve |
|---|---|
| `public/icono-contrux.png` | logotipo que la app dibuja (splash, login, menú lateral). Es el único que se empaqueta en el APK. |
| `public/launcher_icon.png` | icono de lanzador clásico: logo sobre el negro de la app. |
| `public/launcher_foreground.png` | primer plano del icono adaptativo de Android (fondo `#08080A`). |

Los tres se generan a partir del PNG original recortando el margen transparente
y reescalando; no hace falta ninguna librería para *mostrar* imágenes locales en
Flutter (basta declararlas en `pubspec.yaml` y usar `Image`).
`flutter_launcher_icons` es solo una herramienta de build y no viaja en la app.

### Compilar

```bash
flutter build apk --release                    # APK único (todas las ABIs)
flutter build apk --release --split-per-abi    # un APK por arquitectura (recomendado)
flutter build appbundle --release              # AAB para Google Play
```

Los artefactos quedan en `build/app/outputs/flutter-apk/`.

---

## Arquitectura

```
.env                          configuración de entorno (asset, ver arriba)
public/                       logotipo y fuentes de los iconos de lanzador
lib/
├─ main.dart                  arranque: .env, locale es, orientación, overlays
├─ app.dart                   MaterialApp.router + restauración de sesión
├─ core/
│  ├─ config/                 URL base y timeouts
│  ├─ network/                ApiClient + jerarquía de ApiException
│  ├─ storage/                SecureStore (Keystore/Keychain) + fake en memoria
│  ├─ router/                 go_router con redirect por estado de sesión
│  ├─ theme/                  paleta, ThemeData y rutas de recursos
│  ├─ utils/                  validadores, formateadores y parseo de JSON
│  ├─ widgets/                widgets compartidos (logo, botón neón, tarjetas)
│  └─ providers.dart          providers raíz (http, storage, token)
└─ features/<módulo>/
   ├─ domain/                 modelos inmutables + reglas de negocio
   ├─ data/                   repositorio (habla con ApiClient)
   ├─ application/            controladores Riverpod (estado de la UI)
   └─ presentation/           pantallas y widgets
```

Cada capa depende solo de la de abajo: la UI nunca llama a `ApiClient`
directamente y los modelos no conocen Flutter.

Los módulos con varias entidades pequeñas (inventario, maquinaria, personal,
contratistas, facturación, documentos) agrupan sus modelos en un único
`domain/<módulo>_models.dart` en lugar de un archivo por clase: son tipos de
20-40 líneas que siempre se leen juntos.

`core/utils/json.dart` (`J.str`, `J.dbl`, `J.intOf`, `J.list`…) centraliza el
parseo defensivo. El backend omite campos opcionales, manda `null` en columnas
vacías y a veces números como cadena; con estos ayudantes un campo inesperado
nunca tira la pantalla abajo.

---

## El panel: tablero financiero

La pantalla de inicio ya no es una rejilla de módulos, sino el **tablero
financiero del proyecto seleccionado**. Funciona así:

1. `GET /projects` trae las obras de la empresa.
2. El selector de arriba elige una; por defecto, la primera de la lista.
3. `GET /dashboard/financial/{project_id}` devuelve las siete cifras que se
   pintan en tarjetas: presupuesto total, gastos, compras, facturado, cobrado,
   pagado a proveedores y variación financiera.
4. Encima de las tarjetas, una barra muestra el **presupuesto consumido**
   (`gastos + compras` ÷ `presupuesto`) y avisa en rojo si se pasa.

El proyecto activo lo resuelve `activeProjectProvider`, que se **deriva** de la
lista y de la selección en lugar de guardarse aparte. Así el panel nunca queda
apuntando a un proyecto recién borrado y no hace falta un
`addPostFrameCallback` para elegir el primero al cargar.

Si el rol no tiene `dashboard:read`, la pantalla lo dice y **no lanza la
petición**: sería un `403` seguro.

---

## Navegación: el menú lateral

`AppDrawer` (`lib/features/home/presentation/widgets/app_drawer.dart`) lista
**todos los módulos del ERP**, filtrados por los permisos del usuario, y marca
en naranja el que está abierto. Los módulos que aún no tienen pantalla salen
atenuados con la etiqueta «Pronto» y avisan al tocarlos en lugar de navegar
(su capa de datos sí está lista, ver más abajo).

Se monta como `Scaffold.drawer` en cada pantalla de primer nivel (panel,
proyectos, clientes). Esas pantallas ya no llevan flecha de volver: desde el
panel se navega con `go`, así que no hay pila que desapilar y el cajón es el
único camino de vuelta. Las subpantallas (p. ej. el detalle de un proyecto) sí
conservan la flecha.

La lista sale de `visibleModulesProvider`, que Riverpod recalcula solo al
cambiar de usuario, de modo que el panel y el menú comparten el mismo cálculo.

---

## Autenticación y «Recordar datos»

El equivalente en Flutter a `SecureStore` de React Native es
[`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage), que
guarda en el **Android Keystore** (`EncryptedSharedPreferences`) y en el
**Keychain** de iOS. Está detrás de la interfaz `SecureStore`
(`lib/core/storage/secure_store.dart`) para poder inyectar una implementación en
memoria en las pruebas.

Qué se guarda cifrado:

| Clave | Contenido | Se borra al… |
|---|---|---|
| `auth.token` | JWT de la sesión | cerrar sesión o expirar |
| `auth.user` | usuario + permisos | cerrar sesión o expirar |
| `auth.remember_me` | `'1'` si la casilla está marcada | desmarcar la casilla |
| `auth.remembered_email` | email recordado | desmarcar la casilla |
| `auth.remembered_password` | contraseña recordada | desmarcar la casilla |

Comportamiento:

1. Al abrir el login se leen las credenciales recordadas y se prerrellenan los
   campos con la casilla ya marcada.
2. Al iniciar sesión con la casilla marcada se guardan; sin ella se borran las
   que hubiera.
3. **Cerrar sesión conserva lo recordado** (solo borra token y usuario), que es
   lo que espera el usuario al marcar «Recordar datos».
4. Al arrancar, si hay un token guardado y **no ha expirado** (se lee el claim
   `exp` del JWT), se entra directo al panel sin pasar por el login.
5. Si cualquier petición responde `401`, la sesión se cierra sola y la app
   vuelve al login.

### Permisos

El JWT trae el array `permissions`; `"*"` es el comodín de `Administrador`.
`AuthUser.can()` y `canAny()` resuelven en O(1) y el panel principal solo pinta
los módulos permitidos. **Es solo cosmético**: el backend revalida cada petición.

---

## Lo que la app no hace (a propósito)

Construx móvil es la herramienta de los **trabajadores de la constructora**.
Estas partes de la API existen pero pertenecen a la web y no se implementan:

| Fuera del alcance | Por qué |
|---|---|
| `POST /register` — alta de empresa | Registrar una constructora es un trámite de oficina, no algo que hace un obrero desde la obra. |
| `POST /admin/login` — acceso del superadministrador | El dueño del sistema gestiona todas las empresas desde su propio panel. |
| `GET/POST/PATCH /subscriptions` (salvo `me`) | Exigen un token con `is_super_admin`. |

La única puerta de entrada es `POST /login`, y por eso el login no tiene enlace
de «crear cuenta»: los usuarios los crea el administrador de cada empresa con
`POST /users`.

Sí se conserva **`GET /subscriptions/me`**: solo pide un JWT normal y sirve para
explicarle al trabajador por qué el backend devuelve `402` cuando el plan de su
empresa ha caducado.

Hay una prueba que lo vigila: si alguien reintroduce `/register` o
`/admin/login` en un repositorio, `endpoints_test.dart` falla.

---

## Fotos: Supabase Storage

El ERP guarda **solo metadatos** de las fotos; el archivo vive en Supabase.
`PhotosRepository.upload()` encadena los dos pasos:

1. Sube los bytes a `POST {SUPABASE_URL}/storage/v1/object/{bucket}/{ruta}`
   con la `anon key` en `apikey` y en `Authorization`.
2. Registra la URL pública resultante con `POST /photos`.

La ruta del objeto es `{project_id}/{fecha-iso}-{aleatorio}.{ext}`: la fecha
delante deja el bucket ordenado cronológicamente y el sufijo aleatorio evita
que dos fotos del mismo milisegundo se pisen.

**Si el ERP rechaza el registro, se borra el archivo recién subido** para no
dejar huérfanos ocupando el bucket. Al revés, `deleteWithFile()` borra primero
el registro y después el archivo: si fallara el segundo paso queda un huérfano
invisible, que es mucho menos molesto que una foto listada que no se puede
abrir.

Se habla con la API REST de Storage en vez de traer el SDK `supabase_flutter`:
aquí solo hacen falta subir, borrar y componer la URL pública, y el SDK
arrastraría auth, realtime y código nativo que la app no usa.

> Falta la parte de UI: elegir o tomar la foto. `upload()` recibe los bytes ya
> leídos, así que conectar un `image_picker` es lo único pendiente cuando se
> construya la pantalla del módulo.

---

## Cobertura de la API

**Todos los endpoints de `API_DOCUMENTATION.md` que le corresponden a esta app
están implementados** en la capa de datos: cada uno tiene su modelo inmutable,
su método de repositorio y su provider de Riverpod.
`test/features/endpoints_test.dart` comprueba, uno a uno, que la llamada sale
con el verbo y la URL documentados.

| Módulo | Endpoints | Datos | Pantalla |
|---|---|---|---|
| Autenticación | `/login` | ✅ | login ✅ |
| Usuarios y roles | `/users`, `/roles` | ✅ | 🔜 |
| Proyectos | `/projects` | ✅ | ✅ |
| Clientes | `/clients` | ✅ | ✅ |
| Dashboard financiero | `/dashboard/financial/{project_id}` | ✅ | ✅ (el panel) |
| Presupuestos | `/budgets` | ✅ | 🔜 |
| Gastos | `/expenses` | ✅ | 🔜 |
| Órdenes de compra | `/purcharse` | ✅ | 🔜 |
| Proveedores | `/supplier` | ✅ | 🔜 |
| Inventario | `/materials`, `/warehouses`, `/inventory/*` | ✅ | 🔜 |
| Maquinaria | `/equipment/*` | ✅ | 🔜 |
| Personal | `/positions`, `/employees`, `/contracts` | ✅ | 🔜 |
| Asistencia | `/attendance/*` | ✅ | 🔜 |
| Contratistas | `/contractors/*` | ✅ | 🔜 |
| Cronograma | `/schedule/*` | ✅ | 🔜 |
| Avance de obra | `/progress/*` | ✅ | 🔜 |
| Fotos | `/photos` + Supabase Storage | ✅ | 🔜 |
| Facturación y pagos | `/invoices/*` | ✅ | 🔜 |
| Documentos y versiones | `/documents/*` | ✅ | 🔜 |
| Notificaciones (REST + WebSocket) | `/notifications`, `/notifications/ws` | ✅ | 🔜 |
| Auditoría | `/audits-logs` | ✅ | 🔜 |
| Suscripción | `/subscriptions/me` | ✅ | 🔜 |

Los módulos sin pantalla ya salen en el menú lateral como «Pronto». Añadir una
es escribir la carpeta `presentation/` y registrar su `routePath` en
`lib/features/home/domain/app_module.dart`; el repositorio y los providers ya
están hechos. `ProjectsScreen` + `ProjectsController` sirven de plantilla.

### Detalles de la API que conviene no «corregir»

- **`/purcharse`** (órdenes de compra) y **`/supplier`** (proveedores, en
  singular) son las rutas reales del backend. Están documentadas como erratas
  históricas y hay pruebas que las fijan para que nadie las «arregle».
- **Fechas:** `start_date`, `end_date` y `report_date` van en RFC 3339; el
  resto (`expense_date`, `delivery_date`, `payment_date`, `date`…) en
  `YYYY-MM-DD`. Cada modelo usa `Fmt.apiDateTime` o `Fmt.apiDate` según toque.
- **`404` que no son errores:** asistencia sin pasar lista, día sin reporte de
  avance y empresa sin suscripción devuelven `null` en vez de lanzar.
- **Rutas `protectedBasic`** (notificaciones y auditoría) no comprueban la
  suscripción: siguen respondiendo aunque el plan haya caducado.
- **Superadministrador:** de `/subscriptions` solo se implementa `me`. El resto
  exige un token con `is_super_admin` y pertenece al panel del dueño del
  sistema, no a esta app.

### Sobre el WebSocket de notificaciones

`/notifications/ws` se implementa con `web_socket_channel` (paquete Dart puro,
sin código nativo). El token viaja como `?token=`, la alternativa que el propio
backend acepta, porque el handshake de un WebSocket no admite cabeceras propias
en todas las plataformas. `notificationsStreamProvider` es `autoDispose`: al
salir de la pantalla se cierra el socket.

---

## Pruebas

```bash
flutter test                      # todo
flutter test test/core            # capa de red, storage, validadores
flutter test test/features/auth   # login, sesión, permisos
```

| Archivo | Cubre |
|---|---|
| `test/core/api_client_test.dart` | URLs, cabeceras, token, mapeo de errores 400/401/402/403/404/409/500, timeouts, UTF-8 |
| `test/core/secure_store_test.dart` | lectura, escritura, borrado selectivo y total |
| `test/core/validators_test.dart` | email, contraseña, montos, campos obligatorios |
| `test/features/auth/auth_repository_test.dart` | login, persistencia cifrada, restauración, credenciales recordadas |
| `test/features/auth/auth_controller_test.dart` | estados de login, logout, cierre automático por 401 |
| `test/features/auth/auth_user_test.dart` | permisos, comodín, decodificación del JWT |
| `test/features/auth/login_screen_test.dart` | UI del login, casilla «Recordar datos», validaciones, errores |
| `test/core/app_config_test.dart` | lectura del `.env`, valores por defecto sin archivo, URL base del `ApiClient` |
| `test/features/endpoints_test.dart` | **los 112 endpoints**: verbo, URL y cabecera de autorización de cada repositorio; y que no reaparezcan las rutas de la web |
| `test/features/photos/photo_upload_test.dart` | subida a Supabase, URL pública, borrado compensatorio, borrado en ambos sitios |
| `test/features/models_test.dart` | parseo de los payloads de ejemplo de la documentación y formato de fechas |
| `test/features/projects/…` · `test/features/clients/…` | repositorios y modelos |
| `test/features/app_module_test.dart` | filtrado de módulos por rol |
| `test/features/home/app_drawer_test.dart` | menú lateral: listado, permisos, navegación, módulos «Pronto» |
| `test/features/home/dashboard_test.dart` | panel: las 7 cifras, selector de proyecto, consumo de presupuesto, sobrecoste, permisos |
| `test/app_test.dart` | arranque completo: splash → login → panel |

Ninguna prueba toca la red ni el almacenamiento real: se inyectan `MockClient` e
`InMemorySecureStore`. Tampoco se sube nada a Supabase: `SupabaseStorage` acepta
su propio `http.Client`.

---

## Notas de optimización

- Widgets `const` y `RepaintBoundary` en el fondo neón y en el logotipo, para
  que el degradado no se repinte al hacer scroll.
- El logotipo es una única `const AssetImage` compartida y se precarga al
  arrancar: `ImageCache` guarda una sola copia decodificada para el splash, el
  login y el menú lateral, sin parpadeo al entrar en cada pantalla.
- El halo del logotipo es un `RadialGradient` (una capa de pintura) y no un
  `BoxShadow` difuminado, que obligaría a la GPU a desenfocar en cada frame.
- El PNG del logotipo se recorta y reescala a 384 px de alto en `public/`: es
  el tamaño máximo al que se dibuja, así que no se decodifica de más.
- `Scaffold` no construye el contenido del cajón hasta que se abre; como
  `AppDrawer` es `const`, tenerlo en cada pantalla no cuesta nada.
- El menú usa `ListView.builder` con `itemExtent`: al ser todas las filas del
  mismo alto, el scroll se resuelve con una multiplicación en vez de midiendo.
- `visibleModulesProvider` cachea la lista filtrada por permisos, en vez de
  recalcularla en cada `build` del panel y del menú.
- Los providers de lectura son `autoDispose.family`: cachean por proyecto y
  liberan la memoria al salir de la pantalla. `ProjectDateQuery` es un `record`,
  así que dos consultas del mismo día comparten entrada de caché.
- Las tarjetas del panel usan `mainAxisExtent` en vez de `childAspectRatio`: su
  alto no depende del ancho, así que girar el móvil no rehace el layout.
- Los importes van dentro de un `FittedBox`: se muestra la cifra exacta y una
  cantidad larga se encoge en vez de desbordar la tarjeta.
- El panel no pide los KPIs si el rol carece de `dashboard:read`: se ahorra una
  petición que devolvería `403`.
- La conexión con Supabase se abre al primer uso: las pantallas que solo listan
  fotos no la necesitan, y `canUpload` responde sin instanciarla.
- Las subidas usan un timeout propio (2 min) en vez de los 30 s de una llamada
  JSON: una foto por datos móviles tarda más que un `GET`.
- `ref.watch(provider.select(...))` en las pantallas: un cambio de
  `isSubmitting` no reconstruye toda la vista.
- Listas con `ListView.builder`/`SliverGrid.builder`: solo se construye lo visible.
- `AuthUser.permissions` es un `Set`, no una `List`: las comprobaciones de
  permisos ocurren en cada `build`.
- Una sola `http.Client` compartida (keep-alive) creada por `apiClientProvider`.
- Las altas y bajas actualizan la lista en memoria en vez de recargarla entera.
- `projectKpisProvider` es `autoDispose.family`: cachea por proyecto y libera al
  salir del detalle.
- Los iconos se hacen *tree-shaking* en release (−99 %).

### Nota sobre `flutter_secure_storage`

Está fijado en `^10.3.1`. La versión 11 exige `compileSdk = 37`, que el Android
Gradle Plugin 9.0.1 todavía no soporta (máximo recomendado: 36). Cuando AGP
suba de versión se puede volver a la 11.
