# Documentación para Desarrolladores

## 1. Estructura de carpetas y propósito

```
lib/
  core/           # Utilidades, constantes, temas, logger, configuración global
  domain/         # Entidades y modelos de dominio puro (negocio, usuario, pedido, etc.)
  data/           # Repositorios, modelos de datos, datasources (acceso a Firestore, APIs, etc.)
  application/    # Casos de uso, lógica de negocio, servicios
  presentation/   # UI y lógica de presentación (pantallas, widgets, viewmodels)
    admin/        # Pantallas y lógica del administrador
    cliente/      # Pantallas y lógica del cliente
    duenio/       # Pantallas y lógica del dueño de negocio
    repartidor/   # Pantallas y lógica del repartidor
    common/       # Widgets y pantallas compartidas
  shared/         # Utilidades y widgets compartidos
```

---

## 2. Descripción de archivos y pantallas principales

### `main.dart`
- **Propósito:** Punto de entrada de la app. Inicializa Firebase, define rutas y temas.
- **Rutas:** Define la navegación principal por roles (`/cliente`, `/admin`, etc.).
- **Inicialización:** Usa `Firebase.initializeApp` y carga variables de entorno si es necesario.

### `presentation/cliente/screens/negocios_screen.dart`
- **NegociosScreen:** Pantalla principal del cliente. Muestra negocios desde Firestore.
  - **StreamBuilder:** Escucha cambios en la colección `negocios`.
  - **DestacadosSlider:** Slider horizontal con los 3 negocios destacados.
  - **Barra de categorías:** Permite filtrar negocios por tipo.
  - **Lista de negocios:** Muestra el resto de negocios con animaciones.
  - **Botón de carrito:** Acceso rápido al carrito de compras.
  - **Pull-to-refresh:** Permite refrescar la lista (aunque Firestore es reactivo).
- **Funciones clave:**
  - `getNegociosStream()`: Obtiene negocios desde Firestore, filtrando por categoría.
  - `getDestacados() / getRestantes()`: Divide negocios en destacados y el resto.
  - `_addToCart()`: Añade productos al carrito y muestra un SnackBar.
  - `_onScroll()`: Oculta/mostrar la barra de categorías según el scroll.

### `DestacadosSlider`
- **Widget propio para el slider de negocios destacados.**
- Usa `PageView.builder` para mostrar negocios destacados de forma horizontal.
- Recibe la lista de negocios y un callback para navegar al menú.

### `presentation/cliente/screens/menu_screen.dart`
- **MenuScreen:** Muestra el menú de un restaurante.
  - **StreamBuilder:** Lee la subcolección `menu` de Firestore para el restaurante seleccionado.
  - **Animaciones:** Cards animadas para cada producto.
  - **Agregar al carrito:** Permite seleccionar cantidad y añadir productos.

### `presentation/admin/screens/dashboard_screen.dart`
- **AdminDashboardScreen:** Dashboard del administrador.
  - Muestra métricas rápidas (usuarios, negocios, pedidos).
  - Botón temporal para poblar Firestore con negocios y menús de ejemplo.

---

## 3. Flujo de datos y navegación

- **Login:** Demo con usuarios por rol. Navega según el rol a la pantalla correspondiente.
- **Cliente:** Ve negocios, filtra por categoría, accede al menú, agrega productos al carrito, realiza pedidos.
- **Admin:** Ve dashboard, puede poblar la base de datos con datos de ejemplo.
- **Firestore:** Toda la información de negocios y menús se obtiene en tiempo real desde Firestore.

---

## 4. Explicación de métodos y widgets clave

- **StreamBuilder:** Se usa para escuchar datos en tiempo real de Firestore.
- **PageView.builder:** Slider horizontal de negocios destacados.
- **ListView.separated:** Lista de categorías y negocios.
- **SmartRefresher:** Pull-to-refresh para refrescar la lista de negocios.
- **SnackBar:** Feedback visual al usuario al agregar productos al carrito o realizar acciones.

---

## 5. Buenas prácticas y patrones

- **Clean Architecture:** Separación clara de capas (domain, data, application, presentation).
- **Riverpod:** (Si está implementado) para gestión de estado robusta y escalable.
- **Inyección de dependencias:** Facilita pruebas y escalabilidad.
- **Animaciones y UX:** Cards animadas, sliders, feedback visual.
- **Comentarios:** El código está comentado en las secciones clave para facilitar el onboarding de nuevos desarrolladores.
- **Internacionalización y accesibilidad:** (Si está implementado) soporte para varios idiomas y accesibilidad.

---

## 6. Ejemplo de cómo agregar una nueva pantalla o funcionalidad

1. Crea el widget en la carpeta correspondiente (`presentation/rol/screens/`).
2. Si requiere lógica de negocio, crea un viewmodel o provider.
3. Si accede a datos, crea un repositorio/datasource en `data/`.
4. Agrega la ruta en `main.dart` si es una pantalla principal.
5. Usa comentarios para explicar la lógica y el propósito de cada método.

---

## 7. Recursos útiles

- **Documentación oficial Flutter:** https://docs.flutter.dev/
- **Documentación Firebase:** https://firebase.google.com/docs/flutter/setup
- **Guía Clean Architecture:** https://medium.com/flutter-community/clean-architecture-fad3b6b4c5d0 