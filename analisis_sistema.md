# 🍔 Análisis Completo del Sistema de Pedidos (Shopping App Backend)

## ¿Qué es este sistema?

Es el **backend (servidor)** de una aplicación de delivery de comida, similar a Uber Eats, Rappi o Hugo. No tiene interfaz visual propia — su trabajo es recibir peticiones desde una **app móvil** (Flutter/React Native) y responder con datos en formato **JSON**.

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                    APP MÓVIL / FRONTEND                     │
│               (Flutter, React Native, etc.)                 │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP Requests (JSON)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   LARAVEL BACKEND (API)                     │
│                                                             │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐  │
│  │   RUTAS     │──▶│ CONTROLLERS  │──▶│    MODELOS      │  │
│  │  /api/v1/   │   │  (lógica)    │   │ (base de datos) │  │
│  └─────────────┘   └──────────────┘   └─────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              PANEL ADMIN (/admin)                   │   │
│  │         Laravel Admin — gestión visual               │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │   MySQL / Base   │
                    │   de Datos       │
                    └──────────────────┘
```

---

## 📦 Tablas en la Base de Datos

| Tabla | ¿Qué guarda? |
|-------|-------------|
| `users` | Clientes registrados (nombre, email, teléfono, contraseña) |
| `foods` | Productos/comidas (nombre, precio, imagen, tipo, popularidad) |
| `food_types` | Categorías (Pizzas, Hamburguesas, Bebidas, etc.) |
| `orders` | Pedidos realizados (monto, dirección, estado, OTP) |
| `order_details` | Detalle de cada pedido (qué producto, cantidad, precio) |
| `customer_addresses` | Direcciones guardadas de los clientes |
| `zones` | Zonas geográficas de cobertura |
| `admin_users` | Administradores del panel /admin |
| `personal_access_tokens` | Tokens de sesión (Passport OAuth2) |

---

## 🔐 ¿Cómo funciona el Login?

### Flujo completo:

```
App Móvil                          Backend Laravel
    │                                    │
    │── POST /api/v1/auth/login ────────▶│
    │   { email, password }              │
    │                                    │── Busca usuario en BD
    │                                    │── Verifica contraseña (bcrypt)
    │                                    │── Genera token OAuth2 (Passport)
    │◀─ { token: "eyJ0eXAi..." } ───────│
    │                                    │
    │── GET /api/v1/customer/info ──────▶│
    │   Authorization: Bearer eyJ0eXAi  │── Valida el token
    │                                    │── Retorna datos del usuario
    │◀─ { name, email, phone... } ───────│
```

**Laravel Passport** es el sistema que emite y valida los tokens. Funciona con el estándar **OAuth2**, que es el mismo que usan Google, Facebook, etc.

---

## 🛒 ¿Cómo funciona un Pedido?

### Flujo de colocar un pedido:

```
App Móvil                               Backend
    │                                      │
    │── POST /api/v1/order/place ─────────▶│
    │   {                                  │
    │     order_amount: 15.50,             │── Valida los datos
    │     address: "Calle 5...",           │── Busca cada producto en BD
    │     cart: [                          │── Calcula precio real
    │       { id: 3, quantity: 2 },        │── Genera número de orden
    │       { id: 7, quantity: 1 }         │── Genera OTP (código 4 dígitos)
    │     ]                                │── Guarda Order + OrderDetails
    │   }                                  │
    │◀─ { order_id: 100001,               │
    │     total_amount: 15.50,             │
    │     message: "Order placed!" } ──────│
```

El sistema genera IDs de pedido empezando en **100001** para que se vean como números de orden reales (no 1, 2, 3...).

---

## 🍕 ¿Cómo funcionan los Productos?

Los productos tienen:
- **Nombre, descripción, precio, imagen**
- **Tipo/categoría** (relación con `food_types`)
- **is_recommend** → si aparece en la sección "Recomendados"
- **type_id = 2** → los marca como "Populares"

La API expone 3 endpoints de productos:
```
GET /api/v1/products/popular      → los más populares
GET /api/v1/products/recommended  → los recomendados
GET /api/v1/products/test         → prueba
```

---

## 🖥️ Panel de Administración (/admin)

Usa la librería **Laravel Admin** que genera automáticamente un panel CRUD visual. Los administradores pueden:

| Sección | Qué pueden hacer |
|---------|-----------------|
| **Usuarios** | Ver, editar y eliminar clientes |
| **Foods** | Crear, editar, eliminar productos con imagen |
| **Food Types** | Gestionar categorías de comida |
| **Dashboard** | Vista general |

---

## 📁 Estructura de Carpetas Explicada

```
app/
├── Admin/                    ← Panel administrativo (/admin)
│   ├── Controllers/
│   │   ├── FoodsController   ← CRUD de comidas en el panel
│   │   ├── FoodTypeController← CRUD de categorías
│   │   ├── UserController    ← CRUD de usuarios
│   │   └── HomeController    ← Dashboard del admin
│   └── routes.php            ← Rutas del panel admin
│
├── Http/
│   └── Controllers/
│       └── Api/V1/           ← API REST para la app móvil
│           ├── Auth/
│           │   └── CustomerAuthController  ← Login/Register
│           ├── OrderController   ← Pedidos
│           ├── CustomerController← Perfil, direcciones
│           ├── ProductController ← Listado de productos
│           └── ConfigController  ← Config general de la app
│
├── Models/                   ← Representan las tablas de la BD
│   ├── User.php              ← Clientes
│   ├── Food.php              ← Productos
│   ├── FoodType.php          ← Categorías
│   ├── Order.php             ← Pedidos
│   ├── OrderDetail.php       ← Detalle de pedidos
│   └── Zone.php              ← Zonas de cobertura
│
└── CentralLogic/
    └── helpers.php           ← Funciones reutilizables

routes/
├── web.php                   ← Rutas web (solo la bienvenida)
└── api/v1/api.php            ← Todas las rutas de la API

database/
└── migrations/               ← Scripts que crean las tablas
```

---

## 🔄 Ciclo de vida de una petición

```
1. App móvil envía:  POST http://servidor/api/v1/auth/login
                     Body: { email, password }
                              │
2. Laravel recibe la petición en: public/index.php
                              │
3. El Router busca la ruta en: routes/api/v1/api.php
   Encuentra: Route::post('login', 'CustomerAuthController@login')
                              │
4. Llama al método login() en:
   app/Http/Controllers/Api/V1/Auth/CustomerAuthController.php
                              │
5. El Controller:
   - Valida los datos recibidos
   - Usa el Model User para buscar en la BD
   - Verifica la contraseña con bcrypt
   - Genera un token con Passport
   - Retorna JSON con el token
                              │
6. App móvil recibe: { "token": "eyJ0eXAiOiJKV1Q..." }
```

---

## 🚀 ¿Cómo crear uno igual o MEJOR?

### Tecnologías a usar:

| Componente | Opción Básica | Opción Mejor |
|-----------|--------------|-------------|
| **Framework** | Laravel 8 (como este) | Laravel 11 (más moderno) |
| **Autenticación** | Laravel Passport | Laravel Sanctum (más simple) |
| **Panel Admin** | Laravel Admin | Filament (más moderno y bonito) |
| **BD** | MySQL | MySQL + Redis (para cache) |
| **API** | REST | REST + documentación Swagger |
| **Notificaciones** | — | Firebase Push Notifications |
| **Pagos** | — | Stripe / PayPal / Wompi |

### Pasos para crear tu propio sistema:

#### 1️⃣ Planifica las tablas (lo más importante)
```sql
users          → clientes
products       → productos/comidas  
categories     → categorías
orders         → pedidos
order_items    → detalle de pedidos
addresses      → direcciones
deliverymen    → repartidores
```

#### 2️⃣ Crea el proyecto Laravel
```bash
composer create-project laravel/laravel mi-delivery
cd mi-delivery
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

#### 3️⃣ Instala Filament (panel admin moderno)
```bash
composer require filament/filament:"^3.2"
php artisan filament:install --panels
```

#### 4️⃣ Crea las migraciones
```bash
php artisan make:migration create_products_table
php artisan make:migration create_orders_table
php artisan make:migration create_order_items_table
```

#### 5️⃣ Crea los modelos y controladores
```bash
php artisan make:model Product -mc   # Model + Migration + Controller
php artisan make:model Order -mc
```

#### 6️⃣ Estructura tu API
```
POST   /api/auth/login
POST   /api/auth/register
GET    /api/products
GET    /api/products/{id}
GET    /api/categories
POST   /api/orders/place
GET    /api/orders/my-orders
GET    /api/orders/{id}
PUT    /api/orders/{id}/cancel

---

> **Resumen**: Este sistema es un backend API REST para delivery de comida. 
> La app móvil se comunica con él enviando y recibiendo JSON.
> El panel /admin permite gestionar productos y usuarios visualmente.
> Para crear uno mejor: usa Laravel 11 + Sanctum + Filament + Redis + Firebase.
