// localization.dart - Configuración de localización e idiomas soportados
// Define los idiomas disponibles y los delegados de localización para la app.
// Para agregar un nuevo idioma, edita 'supportedLocales' y 'localizationsDelegates'.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const AppLocalizationsDelegate delegate = AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // Navegación
      'inicio': 'Inicio',
      'negocios': 'Negocios',
      'carrito': 'Carrito',
      'pedidos': 'Pedidos',
      'perfil': 'Perfil',
      'dashboard': 'Dashboard',
      'configuracion': 'Configuración',
      'reportes': 'Reportes',
      'usuarios': 'Usuarios',
      'menu': 'Menú',
      'notificaciones': 'Notificaciones',
      'mapa': 'Mapa',

      // Estados de pedidos
      'estado_pendiente': 'Pendiente',
      'estado_preparando': 'Preparando',
      'estado_en_camino': 'En camino',
      'estado_entregado': 'Entregado',
      'estado_cancelado': 'Cancelado',

      // Cliente - Pantallas principales
      'descubre': 'Descubre',
      'buscar_negocios': 'Buscar negocios...',
      'ver_menu': 'Ver menú',
      'agregar_carrito': 'Agregar al carrito',
      'total': 'Total',
      'realizar_pedido': 'Realizar pedido',
      'folio': 'Folio',
      'fecha': 'Fecha',
      'estado': 'Estado',
      'detalles': 'Detalles',
      'hoy': 'Hoy',
      'featured_title': 'Destacados',
      'featured_badge': 'Destacado',
      'categories_title': 'Categorías',
      'sin_nombre': 'Sin nombre',
      'sin_direccion': 'Sin dirección',

      // Cliente - Carrito
      'mi_carrito': 'Mi Carrito',
      'eliminar_producto': 'Eliminar producto',
      'confirmar_eliminar_producto': '¿Estás seguro de que deseas eliminar este producto del carrito?',
      'eliminar': 'Eliminar',
      'vaciar_carrito': 'Vaciar carrito',
      'confirmar_vaciar_carrito': '¿Estás seguro de que deseas vaciar todo el carrito?',
      'vaciar': 'Vaciar',
      'carrito_vacio': 'El carrito está vacío',
      'producto_eliminado': 'Producto eliminado del carrito',
      'carrito_vaciado': 'Carrito vaciado',
      'carrito_refrescado': 'Carrito refrescado y duplicados limpiados',
      'error_refrescar_carrito': 'Error al refrescar carrito',

      // Cliente - Historial de Pedidos
      'historial_pedidos': 'Historial de Pedidos',
      'reintentar': 'Reintentar',
      'sin_pedidos': 'No tienes pedidos aún',
      'realizar_primer_pedido': 'Realiza tu primer pedido para verlo aquí',

      // Cliente - Historial de Pedidos (Detalles)
      'ordenamiento_pedidos': 'Los pedidos están ordenados por estado: Pendiente → Preparando → En camino → Entregado → Cancelado',
      'detalles_pedido': 'Detalles del Pedido',
      'productos': 'Productos',
      'ubicacion_entrega': 'Ubicación de entrega',
      'referencias': 'Referencias',

      // Cliente - Perfil
      'mi_perfil': 'Mi Perfil',
      'confirmar_cerrar_sesion': '¿Estás seguro de que deseas cerrar sesión?',
      'ver_mis_pedidos': 'Ver todos mis pedidos',
      'salir_aplicacion': 'Salir de la aplicación',
      'quiero_ser_repartidor': 'Quiero ser repartidor',
      'notificar_disponibilidad': 'Notificar a los restaurantes que estoy disponible',

      // Cliente - Login
      'iniciar_sesion': 'Iniciar sesión',
      'email': 'Email',
      'ingrese_email': 'Ingrese su email',
      'contraseña': 'Contraseña',
      'ingrese_contraseña': 'Ingrese su contraseña',
      'entrar': 'Entrar',
      'crear_cuenta': 'Crear cuenta',
      'demo_rapido': 'Demo rápido:',

      // Cliente - Menú
      'buscar_productos': 'Buscar productos...',
      'sin_productos': 'No hay productos disponibles',
      'cantidad': 'Cantidad',
      'precio': 'Precio',
      'agregar': 'Agregar',
      'producto_agregado': 'Producto agregado al carrito',
      'error_agregar': 'Error al agregar producto',

      // Dueño - Dashboard
      'ventas_hoy': 'Ventas de hoy',
      'pedidos_pendientes': 'Pedidos pendientes',
      'pedidos_proceso': 'Pedidos en proceso',
      'pedidos_listos': 'Pedidos listos',
      'ingresos_mes': 'Ingresos del mes',
      'ver_todos': 'Ver todos',

      // Dueño - Pedidos
      'gestionar_pedidos': 'Gestionar pedidos',
      'asignar_repartidor': 'Asignar repartidor',
      'sin_repartidores': 'No hay repartidores disponibles',
      'repartidor_asignado': 'Repartidor asignado',
      'error_asignar': 'Error al asignar repartidor',

      // Repartidor
      'pedidos_disponibles': 'Pedidos disponibles',
      'mis_pedidos': 'Mis pedidos',
      'sin_pedidos_disponibles': 'No hay pedidos disponibles',
      'tomar_pedido': 'Tomar pedido',
      'entregar_pedido': 'Entregar pedido',
      'actualizar_estado': 'Actualizar estado',
      'pedido_entregado': 'Pedido entregado exitosamente',

      // Común
      'cargando': 'Cargando...',
      'error': 'Error',
      'aceptar': 'Aceptar',
      'cancelar': 'Cancelar',
      'confirmar': 'Confirmar',
      'volver': 'Volver',
      'guardar': 'Guardar',
      'editar': 'Editar',
      'eliminar_general': 'Eliminar',
      'cerrar': 'Cerrar',
      'buscar': 'Buscar',
      'filtrar': 'Filtrar',
      'limpiar': 'Limpiar',
      'actualizar': 'Actualizar',
      'refrescar': 'Refrescar',

      // Mensajes
      'error_conexion': 'Error de conexión',
      'error_servidor': 'Error del servidor',
      'intentar_nuevamente': 'Intentar nuevamente',
      'operacion_exitosa': 'Operación exitosa',
      'datos_guardados': 'Datos guardados correctamente',

      // Formularios
      'correo_electronico': 'Correo electrónico',
      'password': 'Contraseña',
      'nombre': 'Nombre',
      'apellido': 'Apellido',
      'telefono': 'Teléfono',
      'direccion': 'Dirección',
      'ciudad': 'Ciudad',
      'pais': 'País',
      'registrarse': 'Registrarse',
      'cerrar_sesion': 'Cerrar sesión',

      // Configuración
      'idioma': 'Idioma',
      'espanol': 'Español',
      'ingles': 'Inglés',
      'tema': 'Tema',
      'claro': 'Claro',
      'oscuro': 'Oscuro',
      'activar_notificaciones': 'Activar notificaciones',
      'sonido': 'Sonido',
      'vibracion': 'Vibración',

      // Notificaciones
      'nuevo_pedido_disponible': '¡Nuevo pedido disponible!',
      'pedidos_listos_para_tomar': 'Hay {count} pedidos listos para tomar.',

      // Profile
      'error_cargar_perfil': 'Error al cargar perfil',
      'informacion_personal': 'Información Personal',
      'cliente': 'Cliente',

      // Cart
      'explorar': 'Explorar',
      'agregar_productos_carrito': 'Agrega algunos productos deliciosos\nde los restaurantes disponibles',
      'explorar_restaurantes': 'Explorar restaurantes',

      // Profile - Form fields
      'nombre_completo': 'Nombre completo',
      'ingrese_nombre': 'Por favor ingresa tu nombre',
      'ingrese_telefono': 'Por favor ingresa tu teléfono',
      'ingrese_direccion': 'Por favor ingresa tu dirección',
      'guardar_cambios': 'Guardar cambios',
      'acciones': 'Acciones',
      'completar_datos_repartidor': 'Por favor, completa todos tus datos (nombre, correo, dirección y teléfono) antes de solicitar ser repartidor.',
      'notificacion_enviada': '¡Se notificó a los restaurantes que quieres ser repartidor!',
      'error_notificar': 'Error al notificar: ',
      'no_identificar_usuario': 'No se pudo identificar al usuario',
      'error_cargar_perfil_detalle': 'Error al cargar perfil: ',
      'perfil_actualizado': 'Perfil actualizado correctamente',
      'error_actualizar_perfil': 'Error al actualizar perfil: ',
      'mensaje_repartidor_disponible': 'El cliente {nombre} ({correo}) quiere ser repartidor. Dirección: {direccion}, Teléfono: {telefono}',
      // Confirmación notificar repartidor
      'confirmar_notificar_repartidor_titulo': '¿Notificar restaurantes?',
      'confirmar_notificar_repartidor_mensaje': '¿Estás seguro de que quieres notificar a los restaurantes que deseas ser repartidor? Esta acción enviará una notificación a todos los dueños de restaurantes.',

      // Cart - Additional strings
      'refrescar_carrito': 'Refrescar carrito',
      'vaciar_carrito_tooltip': 'Vaciar carrito',
      'productos_incompletos': 'Productos incompletos',
      'productos_informacion_incompleta': 'Algunos productos no tienen la información completa del negocio y no se pueden procesar.',
      'carrito_vaciado_success': 'Carrito vaciado',
      'necesitamos_ubicacion': 'Necesitamos tu ubicación para entregar tu pedido',
      'obteniendo_ubicacion': 'Obteniendo ubicación...',
      'usar_ubicacion_actual': 'Usar ubicación actual',
      'referencias_placeholder': 'Color de casa, puntos de referencia, instrucciones especiales, etc.',
      'referencias_ejemplo': 'Ej: Casa azul, frente al parque, tocar timbre 2 veces...',
      'ubicacion_no_seleccionada': 'Ubicación no seleccionada',
      'debes_obtener_ubicacion': 'Debes obtener tu ubicación actual e ingresar referencias adicionales.',
      'referencias_requeridas': 'Referencias requeridas',
      'debes_ingresar_referencias': 'Debes ingresar referencias adicionales para la entrega.',
      'error_realizar_pedido': 'Error al realizar el pedido',
      'error_realizar_pedido_detalle': 'Error al realizar el pedido: ',
    },
    'en': {
      // Navigation
      'inicio': 'Home',
      'negocios': 'Businesses',
      'carrito': 'Cart',
      'pedidos': 'Orders',
      'perfil': 'Profile',
      'dashboard': 'Dashboard',
      'configuracion': 'Settings',
      'reportes': 'Reports',
      'usuarios': 'Users',
      'menu': 'Menu',
      'notificaciones': 'Notifications',
      'mapa': 'Map',

      // Order statuses
      'estado_pendiente': 'Pending',
      'estado_preparando': 'Preparing',
      'estado_en_camino': 'On the way',
      'estado_entregado': 'Delivered',
      'estado_cancelado': 'Cancelled',

      // Client - Main screens
      'descubre': 'Discover',
      'buscar_negocios': 'Search businesses...',
      'ver_menu': 'View menu',
      'agregar_carrito': 'Add to cart',
      'total': 'Total',
      'realizar_pedido': 'Place order',
      'folio': 'Folio',
      'fecha': 'Date',
      'estado': 'Status',
      'detalles': 'Details',
      'hoy': 'Today',
      'featured_title': 'Featured',
      'featured_badge': 'Featured',
      'categories_title': 'Categories',
      'sin_nombre': 'No name',
      'sin_direccion': 'No address',

      // Client - Cart
      'mi_carrito': 'My Cart',
      'eliminar_producto': 'Remove product',
      'confirmar_eliminar_producto': 'Are you sure you want to remove this product from the cart?',
      'eliminar': 'Remove',
      'vaciar_carrito': 'Empty cart',
      'confirmar_vaciar_carrito': 'Are you sure you want to empty the entire cart?',
      'vaciar': 'Empty',
      'carrito_vacio': 'The cart is empty',
      'producto_eliminado': 'Product removed from cart',
      'carrito_vaciado': 'Cart emptied',
      'carrito_refrescado': 'Cart refreshed and duplicates cleaned',
      'error_refrescar_carrito': 'Error refreshing cart',

      // Client - Order History
      'historial_pedidos': 'Order History',
      'reintentar': 'Retry',
      'sin_pedidos': 'You have no orders yet',
      'realizar_primer_pedido': 'Make your first order to see it here',

      // Client - Order History (Details)
      'ordenamiento_pedidos': 'Orders are sorted by status: Pending → Preparing → On the way → Delivered → Cancelled',
      'detalles_pedido': 'Order Details',
      'productos': 'Products',
      'ubicacion_entrega': 'Delivery location',
      'referencias': 'References',

      // Client - Profile
      'mi_perfil': 'My Profile',
      'confirmar_cerrar_sesion': 'Are you sure you want to sign out?',
      'ver_mis_pedidos': 'View all my orders',
      'salir_aplicacion': 'Exit the application',
      'quiero_ser_repartidor': 'I want to be a delivery person',
      'notificar_disponibilidad': 'Notify restaurants that I am available',

      // Client - Login
      'iniciar_sesion': 'Sign in',
      'email': 'Email',
      'ingrese_email': 'Enter your email',
      'contraseña': 'Password',
      'ingrese_contraseña': 'Enter your password',
      'entrar': 'Sign in',
      'crear_cuenta': 'Sign up',
      'demo_rapido': 'Quick demo:',

      // Client - Menu
      'buscar_productos': 'Search products...',
      'sin_productos': 'No products available',
      'cantidad': 'Quantity',
      'precio': 'Price',
      'agregar': 'Add',
      'producto_agregado': 'Product added to cart',
      'error_agregar': 'Error adding product',

      // Owner - Dashboard
      'ventas_hoy': 'Today\'s sales',
      'pedidos_pendientes': 'Pending orders',
      'pedidos_proceso': 'Orders in process',
      'pedidos_listos': 'Ready orders',
      'ingresos_mes': 'Monthly income',
      'ver_todos': 'View all',

      // Owner - Orders
      'gestionar_pedidos': 'Manage orders',
      'asignar_repartidor': 'Assign delivery person',
      'sin_repartidores': 'No delivery people available',
      'repartidor_asignado': 'Delivery person assigned',
      'error_asignar': 'Error assigning delivery person',

      // Delivery person
      'pedidos_disponibles': 'Available orders',
      'mis_pedidos': 'My orders',
      'sin_pedidos_disponibles': 'No orders available',
      'tomar_pedido': 'Take order',
      'entregar_pedido': 'Deliver order',
      'actualizar_estado': 'Update status',
      'pedido_entregado': 'Order delivered successfully',

      // Common
      'cargando': 'Loading...',
      'error': 'Error',
      'aceptar': 'Accept',
      'cancelar': 'Cancel',
      'confirmar': 'Confirm',
      'volver': 'Back',
      'guardar': 'Save',
      'editar': 'Edit',
      'eliminar_general': 'Delete',
      'cerrar': 'Close',
      'buscar': 'Search',
      'filtrar': 'Filter',
      'limpiar': 'Clear',
      'actualizar': 'Update',
      'refrescar': 'Refresh',

      // Messages
      'error_conexion': 'Connection error',
      'error_servidor': 'Server error',
      'intentar_nuevamente': 'Try again',
      'operacion_exitosa': 'Operation successful',
      'datos_guardados': 'Data saved successfully',

      // Forms
      'correo_electronico': 'Email',
      'password': 'Password',
      'nombre': 'Name',
      'apellido': 'Last name',
      'telefono': 'Phone',
      'direccion': 'Address',
      'ciudad': 'City',
      'pais': 'Country',
      'registrarse': 'Sign up',
      'cerrar_sesion': 'Sign out',

      // Settings
      'idioma': 'Language',
      'espanol': 'Spanish',
      'ingles': 'English',
      'tema': 'Theme',
      'claro': 'Light',
      'oscuro': 'Dark',
      'activar_notificaciones': 'Enable notifications',
      'sonido': 'Sound',
      'vibracion': 'Vibration',

      // Notifications
      'nuevo_pedido_disponible': 'New order available!',
      'pedidos_listos_para_tomar': 'There are {count} orders ready to take.',

      // Profile
      'error_cargar_perfil': 'Error loading profile',
      'informacion_personal': 'Personal Information',
      'cliente': 'Client',

      // Cart
      'explorar': 'Explore',
      'agregar_productos_carrito': 'Add some delicious products\nfrom available restaurants',
      'explorar_restaurantes': 'Explore restaurants',

      // Profile - Form fields
      'nombre_completo': 'Full name',
      'ingrese_nombre': 'Please enter your name',
      'ingrese_telefono': 'Please enter your phone number',
      'ingrese_direccion': 'Please enter your address',
      'guardar_cambios': 'Save changes',
      'acciones': 'Actions',
      'completar_datos_repartidor': 'Please complete all your data (name, email, address and phone) before requesting to be a delivery person.',
      'notificacion_enviada': 'Restaurants have been notified that you want to be a delivery person!',
      'error_notificar': 'Error notifying: ',
      'no_identificar_usuario': 'Could not identify user',
      'error_cargar_perfil_detalle': 'Error loading profile: ',
      'perfil_actualizado': 'Profile updated successfully',
      'error_actualizar_perfil': 'Error updating profile: ',
      'mensaje_repartidor_disponible': 'Client {nombre} ({correo}) wants to be a delivery person. Address: {direccion}, Phone: {telefono}',
      // Confirm notify delivery
      'confirmar_notificar_repartidor_titulo': 'Notify restaurants?',
      'confirmar_notificar_repartidor_mensaje': 'Are you sure you want to notify restaurants that you want to be a delivery person? This will send a notification to all restaurant owners.',

      // Cart - Additional strings
      'refrescar_carrito': 'Refresh cart',
      'vaciar_carrito_tooltip': 'Empty cart',
      'productos_incompletos': 'Incomplete products',
      'productos_informacion_incompleta': 'Some products do not have complete business information and cannot be processed.',
      'carrito_vaciado_success': 'Cart emptied',
      'necesitamos_ubicacion': 'We need your location to deliver your order',
      'obteniendo_ubicacion': 'Getting location...',
      'usar_ubicacion_actual': 'Use current location',
      'referencias_placeholder': 'House color, landmarks, special instructions, etc.',
      'referencias_ejemplo': 'Ex: Blue house, in front of the park, ring doorbell 2 times...',
      'ubicacion_no_seleccionada': 'Location not selected',
      'debes_obtener_ubicacion': 'You must get your current location and enter additional references.',
      'referencias_requeridas': 'References required',
      'debes_ingresar_referencias': 'You must enter additional references for delivery.',
      'error_realizar_pedido': 'Error placing order',
      'error_realizar_pedido_detalle': 'Error placing order: ',
    },
  };

  String get(String key) {
    final languageCode = locale.languageCode;
    final translations = _localizedValues[languageCode] ?? _localizedValues['es']!;
    return translations[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 