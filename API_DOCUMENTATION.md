# Constructora ERP — Backend API Documentation
# Base url = https://dirs-api-erp-constructora.lunsoy.easypanel.host, no tiene prefijo de /api, apuntas a https://dirs-api-erp-constructora.lunsoy.easypanel.host/login por ejemplo
This document describes how the **Constructora ERP** backend works. It is the reference guide for frontend teams and for AI coding assistants working on this project.

- **Language:** Go (`net/http.ServeMux`, Go 1.22+ with path variables)
- **Database:** PostgreSQL
- **Auth:** JWT (`golang-jwt` v5), HS256
- **Architecture:** Handler → Service → Repository (in `internal/<module>/`)

---

## Table of Contents

1. [Authentication & Roles Flow](#1-authentication--roles-flow)
2. [Full Permission List](#2-full-permission-list)
3. [Protection Model (Middlewares)](#3-protection-model-middlewares)
4. [Conventions](#4-conventions)
   - [Headers](#headers)
   - [Error responses](#error-responses)
   - [Time formats](#time-formats)
5. [Endpoints](#5-endpoints)
   - [Public Routes](#public-routes)
   - [Users & Roles](#users--roles)
   - [Projects](#projects)
   - [Clients](#clients)
   - [Budgets](#budgets)
   - [Expenses](#expenses)
   - [Purchase Orders](#purchase-orders)
   - [Suppliers](#suppliers)
   - [Inventory](#inventory)
   - [Equipment](#equipment)
   - [Personnel](#personnel)
   - [Attendance](#attendance)
   - [Contractors](#contractors)
   - [Schedule](#schedule)
   - [Progress](#progress)
   - [Photos](#photos)
   - [Invoices / Payments](#invoices--payments)
   - [Financial Dashboard](#financial-dashboard)
   - [Documents](#documents)
   - [Notifications](#notifications)
   - [Audit Logs](#audit-logs)
   - [Subscriptions](#subscriptions)
6. [Glossary](#6-glossary)

---

## 1. Authentication & Roles Flow

The app uses **Role-Based Access Control (RBAC)**. The chain is:

```
users ──(user_roles)──▶ roles ──(role_permissions)──▶ permissions
```

- **Company** (tenant) → created at registration. All data is scoped by `company_id` from the JWT.
- **Roles** (per company): `Administrador`, `Gerente`, `Ingeniero`, `Compras`, `Contabilidad`, `Almacén`, `Supervisor`. These are created automatically when a company registers.
- **Permissions**: global catalog stored in the `permissions` table (see [Full Permission List](#2-full-permission-list)).
- Each role is linked to a set of permissions in `role_permissions`.
- Each user is linked to exactly one role via `user_roles`.

### Login (public)

```
POST /login
Content-Type: application/json

{
  "email": "andres@xyz.com",
  "password": "claveSegura123"
}
```

**Response `200 OK`:**
```json
{
  "message": "Inicio de sesion exitoso",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "a1b2...",
    "name": "Andrés Pérez",
    "email": "andres@xyz.com",
    "role": "Administrador",
    "permissions": ["*"]
  }
}
```

### What the token contains

The JWT is signed with `JWT_SECRET` (env var) and expires in **24 hours**. Its payload (claims):

```json
{
  "user_id": "a1b2...",
  "company_id": "6f3e...",
  "permissions": ["*"],
  "exp": 1786183200,
  "iat": 1786096800,
  "nbf": 1786096800
}
```

> **Key behavior — the wildcard `*`:** an **Administrador** user logs in with `permissions: ["*"]`, which grants access to **every** protected endpoint. Any other role receives its own explicit permission list (e.g. `["projects:read", "budgets:read"]`).

### How permissions drive the UI

1. The frontend stores the `token` and the `user.permissions` array after login.
2. Use `user.permissions` to show/hide menus, buttons and routes. If it contains `"*"`, show everything.
3. The backend **re-validates the permission on every request** via middleware — the frontend filtering is only cosmetic.

> ⚠️ **Important:** permissions are embedded in the JWT at login time. If a user's role/permissions change in the database, the change only takes effect after the user **logs in again** (or the token expires, 24h).

---

## 2. Full Permission List

Catalog stored in the `permissions` table (global, seeded once). `"*"` is a virtual wildcard only present in the JWT of admins — it is **not** a row in the table.

| Permission | Description |
|---|---|
| `users:read` | View users and roles |
| `users:create` | Create users |
| `users:update` | Update users |
| `users:delete` | Delete users |
| `projects:create` | Create projects |
| `projects:read` | View projects |
| `projects:update` | Update projects |
| `projects:delete` | Delete projects |
| `clients:create` | Create clients |
| `clients:read` | View clients |
| `clients:update` | Update clients |
| `clients:delete` | Delete clients |
| `budgets:create` | Create budgets |
| `budgets:read` | View budgets |
| `budgets:update` | Update budgets |
| `budgets:delete` | Delete budgets |
| `budgets:approve` | Approve budgets |
| `expenses:create` | Register expenses |
| `expenses:read` | View expenses |
| `expenses:update` | Update expenses |
| `expenses:delete` | Delete expenses |
| `purchases:create` | Create purchase orders |
| `purchases:read` | View purchase orders |
| `purchases:update` | Update purchase orders |
| `purchases:delete` | Delete purchase orders |
| `purchases:approve` | Approve purchase orders |
| `suppliers:create` | Create suppliers |
| `suppliers:read` | View suppliers |
| `suppliers:update` | Update suppliers |
| `suppliers:delete` | Delete suppliers |
| `inventory:read` | View inventory |
| `inventory:manage` | Manage inventory (materials, warehouses, movements) |
| `equipment:read` | View equipment |
| `equipment:manage` | Manage equipment & maintenance |
| `equipment:assign` | Assign equipment to projects |
| `personnel:read` | View personnel |
| `personnel:manage` | Manage personnel (positions, employees, contracts) |
| `attendance:read` | View attendance |
| `attendance:mark` | Mark attendance |
| `contractors:read` | View contractors |
| `contractors:manage` | Manage contractors & their contracts |
| `contractors:pay` | Record contractor payments |
| `schedule:read` | View schedule |
| `schedule:update` | Update schedule tasks |
| `progress:create` | Create daily reports |
| `progress:read` | View daily reports |
| `progress:update` | Update daily reports |
| `progress:delete` | Delete daily reports |
| `photos:upload` | Upload photo metadata |
| `photos:read` | View photo gallery |
| `photos:delete` | Delete photos |
| `invoices:create` | Create invoices |
| `invoices:read` | View invoices & payments |
| `invoices:update` | Update invoices |
| `invoices:delete` | Delete invoices |
| `invoices:cancel` | Cancel invoices |
| `invoices:pay` | Register invoice payments |
| `dashboard:read` | View financial dashboard |
| `documents:create` | Create documents & types |
| `documents:read` | View documents & types |
| `documents:update` | Update documents & types, upload versions |
| `documents:delete` | Delete documents & types |
| `notifications:read` | View notifications |
| `notifications:manage` | Manage notifications |
| `audits:read` | View audit logs |

### Default role → permission mapping (created on company registration)

| Role | Permissions |
|---|---|
| **Administrador** | `*` (wildcard — everything) |
| **Gerente** | `projects:read`, `projects:create`, `projects:update`, `budgets:read`, `budgets:approve`, `purchases:read`, `purchases:approve`, `inventory:read`, `users:read` |
| **Ingeniero** | `projects:read`, `projects:create`, `projects:update`, `budgets:read`, `purchases:create`, `purchases:read`, `inventory:read` |
| **Compras** | `purchases:read`, `purchases:create`, `purchases:approve`, `inventory:read`, `projects:read` |
| **Contabilidad** | `budgets:read`, `purchases:read`, `projects:read` |
| **Almacén** | `inventory:read`, `inventory:manage`, `purchases:read`, `projects:read` |
| **Supervisor** | `projects:read`, `inventory:read`, `budgets:read` |

---

## 3. Protection Model (Middlewares)

Every route belongs to one of these categories:

| Protection | Middleware chain | Requires |
|---|---|---|
| **Public** | — | Nothing |
| `protected(perm)` | `AuthMiddleware` → `RequireActiveSubscription` → `RequirePermission(perm)` | Valid JWT **+ active subscription** **+ permission** |
| `protectedBasic(perm)` | `AuthMiddleware` → `RequirePermission(perm)` | Valid JWT **+ permission** (no subscription check) |
| **Superadmin** | `RequireSuperAdmin` → `AuthMiddleware` | Valid JWT **with `is_super_admin: true`** |
| `auth` | `AuthMiddleware` | Valid JWT only |

A permission is granted if the JWT `permissions` array contains the exact permission **or** the wildcard `"*"`.

The `AuthMiddleware` validates the JWT and injects into the request context: `user_id`, `company_id`, `is_super_admin`, and `permissions`. Handlers read the `company_id`/`user_id` from this context — **values sent in the body for `company_id`/`user_id` are ignored/overwritten**.

### Sending the token

```
Authorization: Bearer <JWT>
```

or, alternatively:

```
GET /projects?token=<JWT>
```

### Middleware error responses

| Status | Content | Meaning |
|---|---|---|
| `401` | `Se requiere token de autenticación` / `Token inválido o expirado` | Missing/invalid/expired JWT |
| `402` | `Suscripción inactiva o expirada` | Company subscription not active |
| `403` | `{"message": "Acceso denegado: no tienes permisos para realizar esta acción"}` | Missing permission |
| `403` | `Acceso denegado: solo el administrador del sistema` | Route is superadmin-only |

---

## 4. Conventions

### Headers

- `Content-Type: application/json` for all request bodies.
- `Authorization: Bearer <token>` for all protected endpoints.

### Error responses

Most handlers respond with **plain text** via `http.Error`:

| Status | Meaning |
|---|---|
| `400` | Bad request / invalid JSON / validation error |
| `401` | Not authorized (missing/invalid token) |
| `403` | Forbidden (missing permission / superadmin only) |
| `404` | Not found |
| `405` | Method not allowed |
| `409` | Conflict (e.g. project cannot be deleted) |
| `500` | Internal server error |

A few endpoints respond with **JSON errors** `{"message": "<text>"}`: `POST /login`, `POST /admin/login`, `RequirePermission` middleware, and the `404` responses of `GET /attendance/{project_id}` and `GET /progress/{project_id}`.

### Time formats

- Timestamps (`created_at`, `updated_at`, `start_date`, `end_date`, `report_date`) → **RFC 3339** (`2026-08-08T10:00:00Z`).
- Date-only fields (`expense_date`, `delivery_date`, `payment_date`, `maintenance_date`, attendance `date`, contract `start_date`/`end_date`) → **`YYYY-MM-DD`** strings.

### Tenant isolation

Every query is filtered by `company_id` from the JWT. A user can only see/modify data belonging to their own company.

---

## 5. Endpoints

### Public Routes

#### `POST /register`
Creates a company + its admin user, default roles, and trial subscription.

**Body:**
```json
{
  "company_name": "Constructora XYZ",
  "company_nit": "901123456-7",
  "admin_name": "Andrés Pérez",
  "admin_email": "andres@xyz.com",
  "password": "claveSegura123"
}
```
**Response `201`:** `{ message, company, admin }` (see [Register a company](#register-a-company-public)).
**Errors:** `405`, `400` (missing fields / invalid JSON), `500`.

#### `POST /login`
Authenticates a company user. Returns the JWT + user info + permissions.

**Body:** `{ "email": string, "password": string }`
**Response `200`:** `{ message, token, user: { id, name, email, role, permissions[] } }`
**Errors:** `400`, `401` (JSON `{"message": ...}`).

#### `POST /admin/login`
Authenticates a **super admin** (system owner). Returns a token with `is_super_admin: true`.

**Body:** `{ "email": string, "password": string }`
**Response `200`:** `{ message, token }`
**Errors:** `400`, `401` (JSON).

---

### Users & Roles

All routes are **`protected`** (require active subscription + permission).

#### `GET /roles` — `users:read`
List assignable roles (excludes `Administrador`).
**Response `200`:** `[ { id, company_id, name, description } ]`

#### `GET /users` — `users:read`
List company users (excludes the admin user).
**Response `200`:** `[ { id, name, email, role, permissions[] } ]`

#### `POST /users` — `users:create`
Creates a user and assigns a role.
**Body:**
```json
{ "name": "María Gómez", "email": "maria@xyz.com", "password": "clave123", "role_id": "uuid" }
```
**Response `201`:** `{ id, name, email, role, permissions[] }`

#### `PUT /users/{id}` — `users:update`
**Body:**
```json
{ "name": "María Gómez", "email": "maria@xyz.com", "role_id": "uuid", "is_active": true, "password": "nuevaClave" }
```
(`password` is optional — omit to keep the current one.)
**Response `200`:** `{ "message": "Usuario actualizado exitosamente" }`

#### `DELETE /users/{id}` — `users:delete`
**Response `200`:** `{ "message": "Usuario eliminado exitosamente" }`

---

### Projects

All routes are **`protected`**.

#### `POST /projects` — `projects:create`
**Body:**
```json
{
  "name": "Edificio Torres del Parque",
  "client_id": "uuid",
  "location": "Bogotá D.C.",
  "start_date": "2026-09-01T00:00:00Z",
  "end_date": "2027-06-30T00:00:00Z",
  "budget": 2500000.00
}
```
**Response `201`:** full `Project` object (`id`, `company_id`, `name`, `client_id`, `location`, `start_date`, `end_date`, `budget`, `status_id`, `created_at`, `updated_at`).
**Errors:** `400` (name required), `402` (project limit reached for the subscription plan).

#### `GET /projects` — `projects:read`
**Response `200`:** `[ Project ]`

#### `PUT /projects/{id}` — `projects:update`
**Body (all optional):** `{ name?, client_id?, location?, start_date?, end_date?, budget? }`
**Response `200`:** `Project`

#### `DELETE /projects/{id}` — `projects:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`
**Errors:** `409` if the project has related data that prevents deletion.

---

### Clients

All routes are **`protected`**.

#### `POST /clients` — `clients:create`
**Body:** `{ "name": string, "nit": string, "address": string, "phone": string, "email": string }`
**Response `201`:** full `Client` object (`id`, `company_id`, `name`, `nit`, `address`, `phone`, `email`, `is_active`, `created_at`, `updated_at`).

#### `GET /clients` — `clients:read`
**Response `200`:** `[ Client ]`

#### `PUT /clients/{id}` — `clients:update`
**Body (all optional):** `{ name?, nit?, address?, phone?, email? }`
**Response `200`:** `Client`

#### `DELETE /clients/{id}` — `clients:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`

---

### Budgets

All routes are **`protected`**.

#### `POST /budgets` — `budgets:create`
Creates a budget with its line items.
**Body:**
```json
{
  "project_id": "uuid",
  "title": "Presupuesto obra gruesa",
  "description": "Aprobado por gerencia",
  "items": [
    { "category": "Materiales", "description": "Cemento gris", "unit": "saco", "quantity": 500, "unit_price": 22.5 }
  ]
}
```
**Response `201`:** `Budget` object (`id`, `company_id`, `project_id`, `title`, `description`, `total_amount`, `created_at`, `updated_at`).

#### `GET /budgets/{project_id}` — `budgets:read`
**Response `200`:** `[ Budget ]`

#### `PUT /budgets/{id}` — `budgets:update`
**Body (all optional):** `{ title?, description? }`
**Response `200`:** `Budget`

#### `DELETE /budgets/{id}` — `budgets:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`

---

### Expenses

All routes are **`protected`**. `company_id`/`user_id` in the body are ignored (taken from the JWT).

#### `POST /expenses` — `expenses:create`
**Body:**
```json
{
  "project_id": "uuid",
  "category_id": 1,
  "title": "Combustible volqueta",
  "amount": 350000.00,
  "expense_date": "2026-08-05",
  "description": "Recarga semana 32"
}
```
**Response `201`:** full `Expense` object.

#### `GET /expenses/{project_id}` — `expenses:read`
**Response `200`:** `[ Expense ]`

#### `PUT /expenses/{id}` — `expenses:update`
**Body (all optional):** `{ title?, amount?, expense_date?, description?, category_id? }`
**Response `200`:** `Expense`

#### `DELETE /expenses/{id}` — `expenses:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`

---

### Purchase Orders

> ⚠️ The routes use the path **`/purcharse`** (historical typo in the codebase — keep it). All routes are **`protected`**.

#### `POST /purcharse` — `purchases:create`
Creates a purchase order with optional line items.
**Body:**
```json
{
  "project_id": "uuid",
  "supplier_id": "uuid",
  "status": "PENDING",
  "total_amount": 1250000.00,
  "delivery_date": "2026-08-20",
  "notes": "Entrega en obra",
  "items": [
    { "description": "Acero corrugado", "unit": "varilla", "quantity": 200, "unit_price": 3500.00, "total_price": 700000.00 }
  ]
}
```
(`company_id`/`user_id` are taken from the JWT.)
**Response `201`:** full `PurchaseOrder` object (echoed with generated `id`/dates).

#### `GET /purcharse/{project_id}` — `purchases:read`
**Response `200`:** `[ PurchaseOrder ]`

#### `PUT /purcharse/{id}` — `purchases:update`
**Body (all optional):** `{ status?, delivery_date?, notes? }`
**Response `200`:** `PurchaseOrder`

#### `DELETE /purcharse/{id}` — `purchases:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`

---

### Suppliers

> ⚠️ The routes use the singular path **`/supplier`** (as registered). All routes are **`protected`**.

#### `POST /supplier` — `suppliers:create`
**Body:** `{ "name": string, "nit": string, "address": string, "phone": string, "email": string }`
(`company_id` taken from JWT.)
**Response `201`:** full `Supplier` object.

#### `GET /supplier` — `suppliers:read`
**Response `200`:** `[ Supplier ]`

#### `PUT /supplier/{id}` — `suppliers:update`
**Body (all optional):** `{ name?, nit?, address?, phone?, email? }`
**Response `200`:** `Supplier`

#### `DELETE /supplier/{id}` — `suppliers:delete`
**Response `200`:** `{ "message": "recurso eliminado" }`

---

### Inventory

All routes are **`protected`**. `company_id`/`user_id` come from the JWT.

#### `POST /materials` — `inventory:manage`
**Body:** `{ "name": string, "code": string, "unit": string, "category_id": string }`
**Response `201`:** full `Material` object.

#### `GET /materials` — `inventory:read`
**Response `200`:** `[ Material ]`

#### `PUT /materials/{id}` — `inventory:manage`
**Body (all optional):** `{ name?, code?, unit?, category_id? }`
**Response `200`:** `Material`

#### `DELETE /materials/{id}` — `inventory:manage`
**Response `200`:** `{ "message": "recurso eliminado" }`

#### `POST /warehouses` — `inventory:manage`
**Body:** `{ "project_id": string, "name": string, "location": string }`
**Response `201`:** full `Warehouse` object.

#### `GET /warehouses` — `inventory:read`
**Response `200`:** `[ Warehouse ]`

#### `PUT /warehouses/{id}` — `inventory:manage`
**Body (all optional):** `{ name?, location? }`
**Response `200`:** `Warehouse`

#### `DELETE /warehouses/{id}` — `inventory:manage`
**Response `200`:** `{ "message": "recurso eliminado" }`

#### `POST /inventory/movements` — `inventory:manage`
Registers a stock movement (input/output).
**Body:**
```json
{
  "warehouse_id": "uuid",
  "material_id": "uuid",
  "movement_type": "INPUT",
  "quantity": 50,
  "reference_id": "uuid",
  "description": "Entrada por compra PO-001"
}
```
(`movement_type`: `"INPUT"` or `"OUTPUT"`; `user_id` from JWT.)
**Response `201`:** full `StockMovement` object.

#### `GET /inventory/stock/{warehouse_id}` — `inventory:read`
Current stock per material in a warehouse.
**Response `200`:** `[ { material_id, material_name, code, unit, quantity } ]`

---

### Equipment

All routes are **`protected`**.

#### `POST /equipment/types` — `equipment:manage`
**Body:** `{ "name": string }` (`company_id` from JWT.)
**Response `201`:** full `EquipmentType` object.

#### `GET /equipment/types` — `equipment:read`
**Response `200`:** `[ EquipmentType ]`

#### `POST /equipment` — `equipment:manage`
**Body:**
```json
{
  "type_id": "uuid",
  "name": "Retroexcavadora 320",
  "plate_number": "ABC-123",
  "model": "320D",
  "brand": "CAT",
  "status": "Available",
  "ownership_type": "Owned"
}
```
(`status`: e.g. `Available` / `Assigned` / `In Maintenance`; `ownership_type`: `Owned` / `Rented`.)
**Response `201`:** full `Equipment` object.

#### `GET /equipment` — `equipment:read`
**Response `200`:** `[ Equipment ]`

#### `PUT /equipment/{id}` — `equipment:manage`
**Body (all optional):** `{ type_id?, name?, plate_number?, model?, brand?, status?, ownership_type? }`
**Response `200`:** `Equipment`

#### `DELETE /equipment/{id}` — `equipment:manage`
**Response `200`:** `{ "message": "recurso eliminado" }`

#### `POST /equipment/assignments` — `equipment:assign`
Assigns equipment to a project.
**Body:**
```json
{
  "equipment_id": "uuid",
  "project_id": "uuid",
  "start_date": "2026-08-10",
  "end_date": "2026-09-10",
  "notes": "Asignación obra Torres del Parque"
}
```
(`assigned_by` from JWT.)
**Response `201`:** full `EquipmentAssignment` object.

#### `GET /equipment/assignments/{equipment_id}` — `equipment:read`
**Response `200`:** `[ EquipmentAssignment ]`

#### `POST /equipment/maintenances` — `equipment:manage`
**Body:**
```json
{
  "equipment_id": "uuid",
  "maintenance_type": "Preventive",
  "description": "Cambio de aceite y filtros",
  "cost": 850000.00,
  "maintenance_date": "2026-08-12",
  "next_due_date": "2026-09-12"
}
```
(`maintenance_type`: `Preventive` / `Corrective`.)
**Response `201`:** full `MaintenanceRecord` object.

#### `GET /equipment/maintenances/{equipment_id}` — `equipment:read`
**Response `200`:** `[ MaintenanceRecord ]`

---

### Personnel

All routes are **`protected`**. Some DELETE endpoints return `204 No Content`.

#### `POST /positions` — `personnel:manage`
**Body:** `{ "name": string, "base_salary": number }`
**Response `201`:** full `Position` object.

#### `GET /positions` — `personnel:read`
**Response `200`:** `[ Position ]`

#### `PUT /positions/{id}` — `personnel:manage`
**Body:** `{ "name": string, "base_salary": number }`
**Response `200`:** `Position`

#### `DELETE /positions/{id}` — `personnel:manage`
**Response:** `204 No Content`

#### `POST /employees` — `personnel:manage`
**Body:**
```json
{
  "position_id": "uuid",
  "first_name": "Carlos",
  "last_name": "Ruiz",
  "dni": "1032556789",
  "phone": "3001234567",
  "email": "carlos@xyz.com",
  "status": "Active"
}
```
**Response `201`:** full `Employee` object.

#### `GET /employees` — `personnel:read`
**Response `200`:** `[ Employee ]`

#### `PUT /employees/{id}` — `personnel:manage`
**Body:** `{ position_id, first_name, last_name, dni, phone, email, status }`
**Response `200`:** `Employee`

#### `DELETE /employees/{id}` — `personnel:manage`
**Response:** `204 No Content`

#### `POST /contracts` — `personnel:manage`
Creates a labor contract for an employee.
**Body:**
```json
{
  "employee_id": "uuid",
  "project_id": "uuid",
  "contract_type": "Indefinite",
  "salary": 2500000.00,
  "start_date": "2026-08-01",
  "end_date": "2027-08-01",
  "status": "Active"
}
```
**Response `201`:** full `Contract` object.

#### `GET /contracts/{project_id}` — `personnel:read`
**Response `200`:** `[ Contract ]`

#### `PUT /contracts/{id}` — `personnel:manage`
**Body:** `{ contract_type, salary, start_date, end_date, status }`
**Response `200`:** `Contract`

#### `DELETE /contracts/{id}` — `personnel:manage`
**Response:** `204 No Content`

---

### Attendance

All routes are **`protected`**.

#### `POST /attendance` — `attendance:mark`
Saves the daily attendance with its employee logs.
**Body:**
```json
{
  "project_id": "uuid",
  "date": "2026-08-08",
  "logs": [
    { "employee_id": "uuid", "status": "Present", "hours_worked": 8, "notes": "Jornada completa" }
  ]
}
```
(`status`: `Present` / `Absent` / `Late` / `Justified Absence`; `company_id` from JWT.)
**Response `201`:** full `Attendance` object (with `logs`).

#### `GET /attendance/{project_id}` — `attendance:read`
**Query param (required):** `date=2026-08-08`
**Response `200`:** `Attendance` object (with `logs`).
**Errors:** `400` (missing params), `404` JSON when no record found.

#### `PUT /attendance/logs/{id}` — `attendance:mark`
**Body:** `{ "status": string, "hours_worked": number, "notes": string }`
**Response `200`:** `{ id, status, hours_worked, notes }`

#### `DELETE /attendance/{id}` — `attendance:mark`
**Response:** `204 No Content`

---

### Contractors

All routes are **`protected`**.

#### `POST /contractors` — `contractors:manage`
**Body:** `{ "name": string, "nit": string, "representative": string, "phone": string, "email": string }`
(`company_id` from JWT.)
**Response `201`:** full `Contractor` object.

#### `GET /contractors` — `contractors:read`
**Response `200`:** `[ Contractor ]`

#### `PUT /contractors/{id}` — `contractors:manage`
**Body:** `{ name, nit, representative?, phone?, email?, is_active? }`
**Response `200`:** `Contractor`

#### `DELETE /contractors/{id}` — `contractors:manage`
**Response:** `204 No Content`

#### `POST /contractors/contracts` — `contractors:manage`
Creates a contract with a contractor for a project. `balance` starts equal to `total_amount`.
**Body:**
```json
{
  "contractor_id": "uuid",
  "project_id": "uuid",
  "title": "Contrato cimentación",
  "total_amount": 50000000.00,
  "start_date": "2026-08-15",
  "end_date": "2026-11-15",
  "status": "Active"
}
```
**Response `201`:** full `ContractorContract` object.

#### `GET /contractors/contracts/{project_id}` — `contractors:read`
**Response `200`:** `[ ContractorContract ]`

#### `PUT /contractors/contracts/{id}` — `contractors:manage`
**Body:** `{ title, total_amount, balance, start_date, end_date?, status }`
**Response `200`:** `ContractorContract`

#### `DELETE /contractors/contracts/{id}` — `contractors:manage`
**Response:** `204 No Content`

#### `POST /contractors/payments` — `contractors:pay`
Records a payment against a contractor contract.
**Body:**
```json
{
  "contract_id": "uuid",
  "amount": 10000000.00,
  "payment_date": "2026-09-01",
  "reference_number": "RCP-001",
  "notes": "Abono 1"
}
```
(`user_id` from JWT.)
**Response `201`:** full `ContractorPayment` object.

#### `GET /contractors/payments` — `contractors:read`
**Response `200`:** `[ ContractorPayment ]`

---

### Schedule

All routes are **`protected`**.

#### `POST /schedule/tasks` — `schedule:update`
**Body:**
```json
{
  "project_id": "uuid",
  "name": "Excavación cimientos",
  "description": "Excavación zona A",
  "start_date": "2026-08-10",
  "end_date": "2026-08-20",
  "progress": 0,
  "status": "Pending"
}
```
**Response `201`:** full `Task` object.

#### `PUT /schedule/tasks/{id}` — `schedule:update`
**Body:** full `Task` object (the `id` is taken from the URL).
**Response `200`:** `Task`

#### `DELETE /schedule/tasks/{id}` — `schedule:update`
**Response:** `204 No Content`

#### `GET /schedule/{project_id}` — `schedule:read`
**Response `200`:** `[ Task ]`

---

### Progress

All routes are **`protected`**.

#### `POST /progress/daily` — `progress:create`
Creates a daily site report with optional task progress entries.
**Body:**
```json
{
  "project_id": "uuid",
  "report_date": "2026-08-08T00:00:00Z",
  "weather_condition": "Sunny",
  "observations": "Avance normal, sin novedades",
  "progress_entries": [
    { "task_id": "uuid", "progress_percentage": 25, "quantity_executed": 120.5, "notes": "Muros nivel 1" }
  ]
}
```
(`company_id`/`user_id` from JWT.)
**Response `201`:** full `DailyReport` object.

#### `PUT /progress/daily/{id}` — `progress:update`
**Body (all optional):** `{ weather_condition?, observations?, report_date? }`
**Response `200`:** `{ "message": "Reporte diario actualizado" }`

#### `DELETE /progress/daily/{id}` — `progress:delete`
**Response `200`:** `{ "message": "Reporte diario eliminado" }`

#### `GET /progress/{project_id}` — `progress:read`
**Query param (required):** `date=2026-08-08`
**Response `200`:** `DailyReport`.
**Errors:** `404` JSON when no report found.

---

### Photos

All routes are **`protected`**. Stores **metadata only** (the actual file goes to storage such as Supabase; you send the public URL).

#### `POST /photos` — `photos:upload`
**Body:**
```json
{
  "project_id": "uuid",
  "task_id": "uuid",
  "daily_report_id": "uuid",
  "photo_url": "https://supabase-storage/project/foto1.jpg",
  "description": "Vaciado losa nivel 2",
  "latitude": 4.6543,
  "longitude": -74.0930
}
```
(`company_id`/`user_id` from JWT; `task_id`, `daily_report_id`, `latitude`, `longitude` optional.)
**Response `201`:** full `ProjectPhoto` object.

#### `PUT /photos/{id}` — `photos:upload`
**Body (all optional):** `{ description?, latitude?, longitude? }`
**Response `200`:** `{ "message": "Foto actualizada" }`

#### `DELETE /photos/{id}` — `photos:delete`
**Response `200`:** `{ "message": "Foto eliminada" }`

#### `GET /photos/{project_id}` — `photos:read`
**Response `200`:** `[ ProjectPhoto ]`

---

### Invoices / Payments

All routes are **`protected`**. `company_id` comes from the JWT.

#### `GET /invoices/{id}` — `invoices:read`
Gets an invoice with its items and payments.
**Response `200`:** `Invoice` (`id`, `company_id`, `project_id`, `invoice_number`, `type` (`EMITTED`/`RECEIVED`), `status`, `client_id`, `supplier_id`, `contractor_id`, `issue_date`, `due_date`, `subtotal`, `tax_amount`, `total_amount`, `remaining_amount`, `notes`, `items[]`, `payments[]`).
**Errors:** `404` if not found.

#### `GET /invoices/project/{project_id}` — `invoices:read`
**Response `200`:** `[ Invoice ]`

#### `POST /invoices` — `invoices:create`
Creates an invoice with line items.
**Body:**
```json
{
  "project_id": "uuid",
  "invoice_number": "FAC-0001",
  "type": "EMITTED",
  "status": "Draft",
  "client_id": "uuid",
  "issue_date": "2026-08-08",
  "due_date": "2026-09-08",
  "subtotal": 1000000.00,
  "tax_amount": 190000.00,
  "total_amount": 1190000.00,
  "notes": "Factura avance obra",
  "items": [
    { "description": "Avance obra gruesa", "quantity": 1, "unit_price": 1000000.00, "total": 1000000.00 }
  ]
}
```
**Response `201`:** full `Invoice` object.

#### `PUT /invoices/{id}` — `invoices:update`
**Body (all optional):** `{ status?, notes?, due_date? }`
**Response `200`:** `{ "message": "Factura actualizada" }`

#### `DELETE /invoices/{id}` — `invoices:delete`
**Response `200`:** `{ "message": "Factura eliminada" }`

#### `PATCH /invoices/{id}/cancel` — `invoices:cancel`
**Response `200`:** `{ "message": "Factura cancelada" }`

#### `GET /invoices/payments/{invoice_id}` — `invoices:read`
**Response `200`:** `[ Payment ]`

#### `POST /invoices/payments` — `invoices:pay`
Registers a payment for an invoice.
**Body:**
```json
{
  "invoice_id": "uuid",
  "project_id": "uuid",
  "payment_date": "2026-08-10",
  "amount": 1190000.00,
  "payment_method": "Bank Transfer",
  "reference": "TRF-2026-001",
  "notes": "Pago total"
}
```
**Response `201`:** full `Payment` object.

---

### Financial Dashboard

#### `GET /dashboard/financial/{project_id}` — `dashboard:read`
Consolidated financial KPIs for a project.
**Response `200`:** `ProjectKPIs`:
```json
{
  "company_id": "uuid",
  "project_id": "uuid",
  "total_budget": 2500000.00,
  "total_expenses": 980000.00,
  "total_purchased": 620000.00,
  "total_invoiced": 1190000.00,
  "total_collected": 700000.00,
  "total_paid_to_prov": 400000.00,
  "financial_variance": 1520000.00
}
```

---

### Documents

All routes are **`protected`**. `company_id`/`user_id` come from the JWT.

#### `GET /documents/types` — `documents:read`
**Response `200`:** `[ { id, company_id, name, description, created_at } ]`

#### `POST /documents/types` — `documents:create`
**Body:** `{ "name": string, "description": string }`
**Response `201`:** `DocumentType`

#### `PUT /documents/types/{id}` — `documents:update`
**Body (all optional):** `{ name?, description? }`
**Response `200`:** `{ "message": "Tipo de documento actualizado" }`

#### `DELETE /documents/types/{id}` — `documents:delete`
**Response `200`:** `{ "message": "Tipo de documento eliminado" }`

#### `GET /documents/{id}` — `documents:read`
Gets a document with its version history.
**Response `200`:** `Document` (`id`, `company_id`, `project_id`, `document_type_id`, `title`, `description`, `current_version`, `status`, `versions[]`).
**Errors:** `404` if not found.

#### `GET /documents/project/{project_id}` — `documents:read`
**Response `200`:** `[ Document ]`

#### `POST /documents` — `documents:create`
Creates a document + its first version.
**Body:**
```json
{
  "project_id": "uuid",
  "document_type_id": "uuid",
  "title": "Acta de inicio",
  "description": "Acta firmada",
  "file_url": "https://storage/acta-inicio.pdf",
  "file_size": 245000,
  "file_extension": "pdf",
  "change_log": "Versión inicial"
}
```
**Response `201`:** `Document` (with `versions`).

#### `PUT /documents/{id}` — `documents:update`
**Body (all optional):** `{ title?, description?, document_type_id? }`
**Response `200`:** `{ "message": "Documento actualizado" }`

#### `DELETE /documents/{id}` — `documents:delete`
**Response `200`:** `{ "message": "Documento eliminado" }`

#### `GET /documents/versions/{document_id}` — `documents:read`
**Response `200`:** `[ DocumentVersion ]`

#### `POST /documents/versions` — `documents:update`
Uploads a new version of a document.
**Body:**
```json
{
  "document_id": "uuid",
  "version_number": 2,
  "file_url": "https://storage/acta-inicio-v2.pdf",
  "file_size": 248000,
  "file_extension": "pdf",
  "change_log": "Corrección fecha inicio"
}
```
(`company_id`/`user_id` from JWT.)
**Response `201`:** `DocumentVersion`

---

### Notifications

All routes are **`protectedBasic`** (JWT + permission, **no subscription check**).

#### `GET /notifications/ws` — `notifications:read`
WebSocket endpoint (Gorilla). Upgrades the connection and registers it in the hub for real-time push. Requires `company_id`/`user_id` in the JWT. No JSON body.

#### `POST /notifications` — `notifications:manage`
Creates a notification for one or more target users.
**Body:**
```json
{
  "project_id": "uuid",
  "entity_type": "project",
  "entity_id": "uuid",
  "type": "info",
  "priority": "high",
  "title": "Presupuesto aprobado",
  "message": "El presupuesto fue aprobado por gerencia",
  "link_to_ui": "/budgets/123",
  "metadata": { "budget_id": "123" },
  "target_users": ["uuid1", "uuid2"]
}
```
(`priority`: `low`/`medium`/`high`/`critical`.)
**Response `201`:** full `Notification` object.

#### `GET /notifications` — `notifications:read`
Gets the current user's inbox.
**Response `200`:** `[ Notification ]`

#### `PATCH /notifications/{notification_id}/read` — `notifications:read`
Marks a notification as read.
**Response `200`:** `{ "message": "Notificación marcada como leída" }`

#### `DELETE /notifications/{notification_id}` — `notifications:manage`
**Response `200`:** `{ "message": "Notificación eliminada" }`

---

### Audit Logs

Both routes are **`protectedBasic`** (no subscription check). The required permission for the POST is also `audits:read`.

#### `POST /audits-logs` — `audits:read`
Writes an audit log entry. `company_id`/`user_id` come from the JWT; `ip_address` is derived from `X-Forwarded-For` or `RemoteAddr`.
**Body:**
```json
{
  "action": "UPDATE",
  "table_name": "budgets",
  "row_id": "uuid",
  "old_values": { "status": "Draft" },
  "new_values": { "status": "Approved" }
}
```
**Response `201`:** full `AuditLog` object.

#### `GET /audits-logs` — `audits:read`
Gets the company's audit logs.
**Response `200`:** `[ AuditLog ]`

---

### Subscriptions

- `GET /subscriptions/me` → **JWT only** (`auth`).
- Other routes → **superadmin only**.

#### `GET /subscriptions/me` — auth
Gets the calling company's subscription.
**Response `200`:** `CompanySubscription` (`id`, `company_id`, `status`, `start_date`, `end_date`, `trial_end_date`, `price`, `billing_cycle`, `max_projects`, `max_users`, `max_storage_mb`, `features`, `payment_provider`, `payment_provider_subscription_id`, `payment_provider_customer_id`, `last_payment_date`, `next_billing_date`, `cancelled_at`, `created_at`, `updated_at`).
**Errors:** `404` if no subscription.

#### `GET /subscriptions` — superadmin
Lists all subscriptions with company info.
**Response `200`:** `[ CompanySubscription + company_name, company_nit, company_email, user_count, project_count ]`

#### `GET /subscriptions/{id}` — superadmin
**Response `200`:** `{ subscription: CompanySubscription, payments: [ { id, invoice_id, invoice_number, payment_date, amount, payment_method, reference } ] }`

#### `POST /subscriptions` — superadmin
Creates a subscription.
**Body:** `{ "status": string, "price": number, "billing_cycle": string, "max_projects": int, "max_users": int, "max_storage_mb": int }`
**Response `201`:** `CompanySubscription`

#### `PATCH /subscriptions/{id}` — superadmin
**Body (all optional):** `{ status?, price?, billing_cycle?, max_projects?, max_users?, max_storage_mb?, end_date? }`
**Response `200`:** `CompanySubscription`

---

## 6. Glossary

| Term | Meaning |
|---|---|
| **JWT** | JSON Web Token. Sent as `Authorization: Bearer <token>` or `?token=<token>`. Valid 24h. |
| **Permission** | String action identifier (e.g. `projects:create`). Stored in the `permissions` table. |
| **Role** | Named set of permissions assigned per company (e.g. `Ingeniero`). |
| **Wildcard `*`** | Virtual permission granting access to everything. Only present in the JWT of `Administrador` users. |
| **Tenant / Company** | A construction company; its `company_id` scopes all its data. |
| **`protected(perm)`** | Middleware combo requiring valid JWT + active subscription + permission. |
| **`protectedBasic(perm)`** | Middleware combo requiring valid JWT + permission (no subscription check). |
| **Superadmin** | System-level administrator (`is_super_admin: true` in JWT). Manages subscriptions and all companies. |
