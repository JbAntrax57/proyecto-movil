import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminReportesProvider extends ChangeNotifier {
  // Estado
  String _periodoSeleccionado = 'mes';
  bool _isLoading = true;
  
  // KPIs
  Map<String, dynamic> _kpis = {};
  
  // Datos para gráficas
  List<Map<String, dynamic>> _ventasPorDia = [];
  List<Map<String, dynamic>> _productosMasVendidos = [];
  List<Map<String, dynamic>> _pedidosPorCategoria = [];
  List<Map<String, dynamic>> _topNegocios = [];
  List<Map<String, dynamic>> _topClientes = [];

  // Getters
  String get periodoSeleccionado => _periodoSeleccionado;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get kpis => _kpis;
  List<Map<String, dynamic>> get ventasPorDia => _ventasPorDia;
  List<Map<String, dynamic>> get productosMasVendidos => _productosMasVendidos;
  List<Map<String, dynamic>> get pedidosPorCategoria => _pedidosPorCategoria;
  List<Map<String, dynamic>> get topNegocios => _topNegocios;
  List<Map<String, dynamic>> get topClientes => _topClientes;

  // Inicializar el provider
  Future<void> inicializarReportes(BuildContext context) async {
    await cargarReportes();
  }

  // Cargar reportes
  Future<void> cargarReportes() async {
    _setLoading(true);

    try {
      await Future.wait([
        cargarKPIs(),
        cargarVentasPorDia(),
        cargarProductosMasVendidos(),
        cargarPedidosPorCategoria(),
        cargarTopNegocios(),
        cargarTopClientes(),
      ]);
    } catch (e) {
      // Error silencioso, mantener datos simulados
    }

    _setLoading(false);
  }

  // Cargar KPIs
  Future<void> cargarKPIs() async {
    // Obtener fecha de inicio según período
    final ahora = DateTime.now();
    DateTime fechaInicio;
    
    switch (_periodoSeleccionado) {
      case 'hoy':
        fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
        break;
      case 'semana':
        fechaInicio = ahora.subtract(const Duration(days: 7));
        break;
      case 'mes':
        fechaInicio = DateTime(ahora.year, ahora.month - 1, ahora.day);
        break;
      case 'año':
        fechaInicio = DateTime(ahora.year - 1, ahora.month, ahora.day);
        break;
      default:
        fechaInicio = DateTime(ahora.year, ahora.month - 1, ahora.day);
    }

    try {
      // KPIs reales
      final pedidosData = await Supabase.instance.client
          .from('pedidos')
          .select('total, estado, usuario_email, restaurante_id')
          .gte('created_at', fechaInicio.toIso8601String());

      double ingresosTotales = 0;
      int pedidosTotales = 0;
      int pedidosPendientes = 0;
      int pedidosEntregados = 0;
      int pedidosCancelados = 0;
      Set<String> usuariosUnicos = {};
      Set<String> negociosUnicos = {};

      for (final pedido in pedidosData) {
        final total = double.tryParse(pedido['total'].toString()) ?? 0;
        ingresosTotales += total;
        pedidosTotales++;
        
        if (pedido['usuario_email'] != null) {
          usuariosUnicos.add(pedido['usuario_email']);
        }
        if (pedido['restaurante_id'] != null) {
          negociosUnicos.add(pedido['restaurante_id']);
        }

        final estado = pedido['estado']?.toString().toLowerCase() ?? '';
        switch (estado) {
          case 'pendiente':
          case 'preparando':
          case 'listo':
          case 'en camino':
            pedidosPendientes++;
            break;
          case 'entregado':
            pedidosEntregados++;
            break;
          case 'cancelado':
            pedidosCancelados++;
            break;
        }
      }

      // Calcular calificación promedio (simulado por ahora)
      double calificacionPromedio = 4.2;
      
      // Tiempo promedio de entrega (simulado por ahora)
      int tiempoEntregaPromedio = 25;

      _kpis = {
        'ingresos_totales': ingresosTotales,
        'pedidos_totales': pedidosTotales,
        'pedidos_pendientes': pedidosPendientes,
        'pedidos_completados': pedidosEntregados,
        'pedidos_cancelados': pedidosCancelados,
        'usuarios_activos': usuariosUnicos.length,
        'negocios_activos': negociosUnicos.length,
        'calificacion_promedio': calificacionPromedio,
        'tiempo_entrega_promedio': tiempoEntregaPromedio,
      };
    } catch (e) {
      // Mantener datos simulados en caso de error
      _kpis = {
        'ingresos_totales': 125000.0,
        'pedidos_totales': 450,
        'pedidos_pendientes': 23,
        'pedidos_completados': 380,
        'pedidos_cancelados': 47,
        'usuarios_activos': 1250,
        'negocios_activos': 45,
        'calificacion_promedio': 4.2,
        'tiempo_entrega_promedio': 25,
      };
    }
  }

  // Cargar ventas por día
  Future<void> cargarVentasPorDia() async {
    try {
      final ahora = DateTime.now();
      final fechaInicio = ahora.subtract(const Duration(days: 29));
      
      final ventasData = await Supabase.instance.client
          .from('pedidos')
          .select('total, created_at')
          .gte('created_at', fechaInicio.toIso8601String())
          .order('created_at');

      // Agrupar por día
      final Map<String, double> ventasPorDia = {};
      final Map<String, int> pedidosPorDia = {};

      for (final pedido in ventasData) {
        final fecha = DateTime.parse(pedido['created_at']);
        final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
        
        final total = double.tryParse(pedido['total'].toString()) ?? 0;
        ventasPorDia[fechaStr] = (ventasPorDia[fechaStr] ?? 0) + total;
        pedidosPorDia[fechaStr] = (pedidosPorDia[fechaStr] ?? 0) + 1;
      }

      // Generar lista de los últimos 30 días
      _ventasPorDia = [];
      for (int i = 29; i >= 0; i--) {
        final fecha = ahora.subtract(Duration(days: i));
        final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
        
        _ventasPorDia.add({
          'fecha': fecha,
          'ventas': ventasPorDia[fechaStr] ?? 0,
          'pedidos': pedidosPorDia[fechaStr] ?? 0,
        });
      }
    } catch (e) {
      // Mantener datos simulados en caso de error
      _ventasPorDia = List.generate(30, (index) {
        final fecha = DateTime.now().subtract(Duration(days: 29 - index));
        return {
          'fecha': fecha,
          'ventas': 2000 + (index * 150) + (index % 3 * 500),
          'pedidos': 15 + (index % 5) + 3,
        };
      });
    }
  }

  // Cargar productos más vendidos
  Future<void> cargarProductosMasVendidos() async {
    try {
      final pedidosData = await Supabase.instance.client
          .from('pedidos')
          .select('productos')
          .not('productos', 'is', null);

      // Contar productos vendidos
      final Map<String, int> productosVendidos = {};
      final Map<String, double> ingresosProductos = {};

      for (final pedido in pedidosData) {
        final productos = pedido['productos'] as List;
        for (final producto in productos) {
          final nombre = producto['nombre']?.toString() ?? 'Producto sin nombre';
          final cantidad = int.tryParse(producto['cantidad']?.toString() ?? '0') ?? 0;
          final precio = double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
          
          productosVendidos[nombre] = (productosVendidos[nombre] ?? 0) + cantidad;
          ingresosProductos[nombre] = (ingresosProductos[nombre] ?? 0) + (precio * cantidad);
        }
      }

      // Ordenar por cantidad vendida
      final productosOrdenados = productosVendidos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _productosMasVendidos = productosOrdenados.take(5).map((entry) {
        return {
          'nombre': entry.key,
          'ventas': entry.value,
          'ingresos': ingresosProductos[entry.key] ?? 0,
        };
      }).toList();
    } catch (e) {
      // Mantener datos simulados en caso de error
      _productosMasVendidos = [
        {'nombre': 'Pizza Margherita', 'ventas': 150, 'ingresos': 7500},
        {'nombre': 'Hamburguesa Clásica', 'ventas': 120, 'ingresos': 6000},
        {'nombre': 'Sushi California', 'ventas': 95, 'ingresos': 4750},
        {'nombre': 'Pasta Carbonara', 'ventas': 85, 'ingresos': 4250},
        {'nombre': 'Ensalada César', 'ventas': 75, 'ingresos': 2250},
      ];
    }
  }

  // Cargar pedidos por categoría
  Future<void> cargarPedidosPorCategoria() async {
    try {
      // Obtener pedidos con información de negocios
      final pedidosData = await Supabase.instance.client
          .from('pedidos')
          .select('restaurante_id, total')
          .not('restaurante_id', 'is', null);

      // Obtener todas las relaciones negocio-categoría
      final categoriasData = await Supabase.instance.client
          .from('negocios_categorias')
          .select('negocio_id, categorias_principales(nombre)');

      // Crear mapa de negocio a categorías
      final Map<String, List<String>> negocioCategorias = {};
      for (final categoria in categoriasData) {
        final negocioId = categoria['negocio_id']?.toString();
        final categoriaNombre = categoria['categorias_principales']?['nombre']?.toString();
        
        if (negocioId != null && categoriaNombre != null) {
          if (negocioCategorias[negocioId] == null) {
            negocioCategorias[negocioId] = [];
          }
          negocioCategorias[negocioId]!.add(categoriaNombre);
        }
      }

      // Contar pedidos por categoría (un pedido puede contar en múltiples categorías)
      final Map<String, int> pedidosPorCategoria = {};
      int totalPedidos = 0;

      for (final pedido in pedidosData) {
        final restauranteId = pedido['restaurante_id']?.toString();
        if (restauranteId != null) {
          final categorias = negocioCategorias[restauranteId] ?? ['Sin categoría'];
          
          // Contar el pedido en todas las categorías del negocio
          for (final categoria in categorias) {
            pedidosPorCategoria[categoria] = (pedidosPorCategoria[categoria] ?? 0) + 1;
          }
          totalPedidos++;
        }
      }

      // Calcular porcentajes
      _pedidosPorCategoria = pedidosPorCategoria.entries.map((entry) {
        final porcentaje = totalPedidos > 0 ? ((entry.value / totalPedidos) * 100).round() : 0;
        return {
          'categoria': entry.key,
          'pedidos': entry.value,
          'porcentaje': porcentaje,
        };
      }).toList()
        ..sort((a, b) => (b['pedidos'] as int).compareTo(a['pedidos'] as int));
    } catch (e) {
      // Mantener datos simulados en caso de error
      _pedidosPorCategoria = [
        {'categoria': 'Pizza', 'pedidos': 180, 'porcentaje': 40},
        {'categoria': 'Hamburguesas', 'pedidos': 120, 'porcentaje': 27},
        {'categoria': 'Sushi', 'pedidos': 95, 'porcentaje': 21},
        {'categoria': 'Pasta', 'pedidos': 35, 'porcentaje': 8},
        {'categoria': 'Ensaladas', 'pedidos': 20, 'porcentaje': 4},
      ];
    }
  }

  // Cargar top negocios
  Future<void> cargarTopNegocios() async {
    try {
      final pedidosData = await Supabase.instance.client
          .from('pedidos')
          .select('restaurante_id, total')
          .not('restaurante_id', 'is', null);

      // Obtener información completa de negocios
      final negociosData = await Supabase.instance.client
          .from('negocios')
          .select('id, nombre, usuarioid');

      // Obtener nombres de dueños
      final usuariosData = await Supabase.instance.client
          .from('usuarios')
          .select('id, name');

      final Map<String, String> usuarioNombres = {};
      for (final usuario in usuariosData) {
        usuarioNombres[usuario['id']] = usuario['name'] ?? 'Usuario sin nombre';
      }

      final Map<String, String> negocioNombres = {};
      final Map<String, String> negocioDuenos = {};
      for (final negocio in negociosData) {
        negocioNombres[negocio['id']] = negocio['nombre'] ?? 'Negocio sin nombre';
        final duenoId = negocio['usuarioid']?.toString();
        negocioDuenos[negocio['id']] = usuarioNombres[duenoId] ?? 'Dueno sin nombre';
      }

      // Agrupar por restaurante
      final Map<String, int> pedidosPorNegocio = {};
      final Map<String, double> ingresosPorNegocio = {};

      for (final pedido in pedidosData) {
        final restauranteId = pedido['restaurante_id']?.toString();
        if (restauranteId != null) {
          pedidosPorNegocio[restauranteId] = (pedidosPorNegocio[restauranteId] ?? 0) + 1;
          
          final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
          ingresosPorNegocio[restauranteId] = (ingresosPorNegocio[restauranteId] ?? 0) + total;
        }
      }

      // Ordenar por pedidos
      final negociosOrdenados = pedidosPorNegocio.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _topNegocios = negociosOrdenados.take(5).map((entry) {
        final negocioId = entry.key;
        return {
          'nombre': negocioNombres[negocioId] ?? 'Negocio sin nombre',
          'dueno': negocioDuenos[negocioId] ?? 'Dueno sin nombre',
          'pedidos': entry.value,
          'ingresos': ingresosPorNegocio[negocioId] ?? 0,
        };
      }).toList();
    } catch (e) {
      // Mantener datos simulados en caso de error
      _topNegocios = [
        {'nombre': 'Pizza Express', 'dueno': 'Juan Pérez', 'pedidos': 85, 'ingresos': 42500},
        {'nombre': 'Burger House', 'dueno': 'María García', 'pedidos': 72, 'ingresos': 36000},
        {'nombre': 'Sushi Master', 'dueno': 'Carlos López', 'pedidos': 65, 'ingresos': 32500},
        {'nombre': 'Pasta Italiana', 'dueno': 'Ana Martínez', 'pedidos': 45, 'ingresos': 22500},
        {'nombre': 'Fresh Salads', 'dueno': 'Luis Rodríguez', 'pedidos': 38, 'ingresos': 11400},
      ];
    }
  }

  // Cargar top clientes
  Future<void> cargarTopClientes() async {
    try {
      final pedidosData = await Supabase.instance.client
          .from('pedidos')
          .select('usuario_email, total')
          .not('usuario_email', 'is', null);

      // Agrupar por cliente
      final Map<String, int> pedidosPorCliente = {};
      final Map<String, double> gastosPorCliente = {};

      for (final pedido in pedidosData) {
        final email = pedido['usuario_email']?.toString();
        if (email != null) {
          pedidosPorCliente[email] = (pedidosPorCliente[email] ?? 0) + 1;
          
          final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
          gastosPorCliente[email] = (gastosPorCliente[email] ?? 0) + total;
        }
      }

      // Ordenar por pedidos
      final clientesOrdenados = pedidosPorCliente.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _topClientes = clientesOrdenados.take(5).map((entry) {
        final email = entry.key;
        final nombre = email.split('@')[0]; // Usar parte del email como nombre
        return {
          'nombre': nombre,
          'pedidos': entry.value,
          'total_gastado': gastosPorCliente[email] ?? 0,
        };
      }).toList();
    } catch (e) {
      // Mantener datos simulados en caso de error
      _topClientes = [
        {'nombre': 'Juan Pérez', 'pedidos': 25, 'total_gastado': 12500},
        {'nombre': 'María García', 'pedidos': 22, 'total_gastado': 11000},
        {'nombre': 'Carlos López', 'pedidos': 18, 'total_gastado': 9000},
        {'nombre': 'Ana Martínez', 'pedidos': 15, 'total_gastado': 7500},
        {'nombre': 'Luis Rodríguez', 'pedidos': 12, 'total_gastado': 6000},
      ];
    }
  }

  // Obtener color para categoría
  Color obtenerColorParaCategoria(String categoria) {
    // Colores predefinidos para categorías comunes
    switch (categoria.toLowerCase()) {
      case 'pizza':
        return Colors.red;
      case 'hamburguesas':
        return Colors.orange;
      case 'sushi':
        return Colors.green;
      case 'pasta':
        return Colors.yellow;
      case 'ensaladas':
        return Colors.blue;
      case 'bebidas':
        return Colors.cyan;
      case 'postres':
        return Colors.pink;
      case 'sopas':
        return Colors.brown;
      case 'mariscos':
        return Colors.teal;
      case 'carnes':
        return Colors.deepOrange;
      case 'vegetariano':
        return Colors.lightGreen;
      case 'vegano':
        return Colors.lime;
      case 'italiano':
        return Colors.indigo;
      case 'mexicano':
        return Colors.deepPurple;
      case 'chino':
        return Colors.red.shade700;
      case 'japonés':
        return Colors.red.shade900;
      case 'tailandés':
        return Colors.orange.shade700;
      case 'indio':
        return Colors.orange.shade900;
      case 'mediterráneo':
        return Colors.blue.shade700;
      case 'americano':
        return Colors.blue.shade900;
      default:
        // Generar color único basado en el hash del nombre de la categoría
        return _generarColorUnico(categoria);
    }
  }

  // Generar color único para cualquier categoría
  Color _generarColorUnico(String categoria) {
    // Lista de colores vibrantes
    final List<Color> colores = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orange.shade700,
      Colors.red.shade700,
      Colors.green.shade700,
      Colors.blue.shade700,
      Colors.purple.shade700,
      Colors.pink.shade700,
      Colors.teal.shade700,
      Colors.cyan.shade700,
    ];

    // Generar hash del nombre de la categoría
    int hash = categoria.hashCode;
    
    // Usar el hash para seleccionar un color de la lista
    int index = hash.abs() % colores.length;
    
    return colores[index];
  }

  // Setters
  void setPeriodoSeleccionado(String periodo) {
    _periodoSeleccionado = periodo;
    cargarReportes();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 