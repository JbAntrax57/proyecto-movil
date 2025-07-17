# Referencia de Código y Componentes (Español)

Este documento describe todas las variables, métodos, widgets y clases principales del proyecto Flutter, explicando su propósito, ubicación y uso.

---

## main.dart
- **main()**: Punto de entrada. Inicializa Firebase y ejecuta la app.
- **MyApp**: Widget raíz. Define rutas y tema global.
- **RegisterScreen, RepartidorHomeScreen, DuenioHomeScreen, AdminHomeScreen**: Pantallas placeholder para cada rol.

---

## presentation/cliente/screens/negocios_screen.dart
- **NegociosScreen**: Pantalla principal del cliente. Muestra negocios y permite navegar al menú.
- **_NegociosScreenState**: Lógica de estado, scroll, refresco y filtrado.
  - **Variables**:
    - `_pageController`, `_scrollController`, `_refreshController`: Controladores de UI.
    - `_currentPage`, `_categoriaSeleccionada`, `_carrito`, `_showCategorias`, `_lastOffset`: Estado de UI y lógica.
    - `categorias`: Lista de categorías de negocios.
  - **Métodos**:
    - `getNegociosStream()`: Stream de negocios desde Firestore, filtrando por categoría.
    - `getDestacados()`: Devuelve negocios con 'destacado' == true.
    - `getRestantes()`: Devuelve negocios no destacados.
    - `_addToCart()`: Añade productos al carrito.
    - `_onRefresh()`: Simula refresco (pull-to-refresh).
    - `_onScroll()`: Oculta/mostrar barra de categorías según scroll.
    - `build()`: Construye la UI principal.
- **DestacadosSlider**: Widget para el slider de negocios destacados.
  - **Variables**: `destacados`, `onTap`, `_pageController`, `_currentPage`, `_autoScrollTimer`.
  - **Funcionalidad**: Slider infinito, scroll automático, navegación al menú.

---

## presentation/cliente/screens/menu_screen.dart
- **MenuScreen**: Pantalla que muestra el menú de un restaurante.
  - **Variables**: `restauranteId`, `restaurante`, `onAddToCart`.
  - **Métodos**:
    - `getMenuStream()`: Stream de productos del menú desde Firestore.
    - `build()`: Construye la UI del menú, cards animadas, agrega productos al carrito.

---

## presentation/cliente/screens/login_screen.dart
- **LoginScreen**: Pantalla de login demo.
  - **Variables**: `email`, `password`, `error`, `loading`, `demoUsers`.
  - **Métodos**:
    - `_login()`: Valida usuario demo y navega según rol.
    - `_goToRegister()`: Navega a registro.

---

## presentation/cliente/screens/carrito_screen.dart
- **CarritoScreen**: Pantalla del carrito de compras.
  - **Variables**: `carrito`, `ubicacion`, `pedidoRealizado`.
  - **Métodos**:
    - `total`: Calcula el total del carrito.
    - `_realizarPedido()`: Muestra modal para ubicación y simula pedido.

---

## presentation/admin/screens/dashboard_screen.dart
- **AdminDashboardScreen**: Dashboard del admin.
  - **Variables**: `usuarios`, `negocios`, `pedidos` (simulados).
  - **Botón poblar negocios**: Agrega negocios y menús de ejemplo a Firestore.

---

## Otros widgets y utilidades
- **core/constants.dart**: Constantes globales (ej. nombre de la app).
- **core/env.dart**: Acceso a variables de entorno.
- **core/logger.dart**: Logger global para debug.
- **core/localization.dart**: Configuración de idiomas soportados.
- **core/theme.dart**: Temas claro y oscuro.
- **core/router.dart**: (Si se usa GoRouter) Definición de rutas avanzadas.

---

## Ejemplo de flujo de un cliente
1. Login como cliente demo.
2. Ve negocios destacados (slider) y el resto (lista).
3. Filtra por categoría si lo desea.
4. Toca un negocio para ver su menú (productos desde Firestore).
5. Agrega productos al carrito.
6. Realiza pedido, el carrito se limpia y se simula notificación.

---

## Notas
- Todos los métodos y widgets están documentados en el código fuente con comentarios.
- El flujo de datos es reactivo gracias a Firestore y StreamBuilder.
- El slider de negocios destacados es infinito y con scroll automático.
- El código sigue buenas prácticas de arquitectura limpia y separación de responsabilidades.

---

¿Dudas? Consulta este archivo o los comentarios en el código fuente para entender cada parte del sistema. 