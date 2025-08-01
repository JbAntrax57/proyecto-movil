class BackendConfig {
  // URL base del backend
  // Para Android emulator, usar 10.0.2.2 en lugar de localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Endpoints
  static const String authEndpoint = '/auth';
  static const String negociosEndpoint = '/negocios';
  static const String productosEndpoint = '/productos';
  static const String pedidosEndpoint = '/pedidos';
  static const String direccionesEndpoint = '/direcciones';
  static const String carritoEndpoint = '/carrito';
  
  // Estados de pedidos
  static const List<String> estadosPedido = [
    'pendiente',
    'preparando',
    'en camino',
    'entregado',
    'cancelado',
  ];
  
  // Categorías de productos
  static const List<String> categoriasProductos = [
    'entradas',
    'platos principales',
    'postres',
    'bebidas',
    'especialidades',
  ];
  
  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configuración de caché
  static const Duration cacheDuration = Duration(minutes: 5);
  
  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
} 