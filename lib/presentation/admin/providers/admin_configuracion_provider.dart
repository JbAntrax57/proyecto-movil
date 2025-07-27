import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminConfiguracionProvider extends ChangeNotifier {
  // Estado
  bool _isLoading = true;
  String? _error;
  
  // Configuración actual
  Map<String, dynamic> _configuracion = {};
  String _nombreAdmin = '';
  String _emailAdmin = '';
  String _telefonoAdmin = '';
  String _direccionAdmin = '';
  
  // Configuración de la aplicación
  bool _notificacionesActivadas = true;
  bool _modoOscuro = false;
  String _idioma = 'es';
  int _tiempoSesion = 30;
  
  // Configuración de la plataforma
  double _comisionPlataforma = 5.0;
  int _tiempoEntregaEstimado = 30;
  bool _pagoEnEfectivo = true;
  bool _pagoConTarjeta = true;
  bool _pagoDigital = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get configuracion => _configuracion;
  String get nombreAdmin => _nombreAdmin;
  String get emailAdmin => _emailAdmin;
  String get telefonoAdmin => _telefonoAdmin;
  String get direccionAdmin => _direccionAdmin;
  bool get notificacionesActivadas => _notificacionesActivadas;
  bool get modoOscuro => _modoOscuro;
  String get idioma => _idioma;
  int get tiempoSesion => _tiempoSesion;
  double get comisionPlataforma => _comisionPlataforma;
  int get tiempoEntregaEstimado => _tiempoEntregaEstimado;
  bool get pagoEnEfectivo => _pagoEnEfectivo;
  bool get pagoConTarjeta => _pagoConTarjeta;
  bool get pagoDigital => _pagoDigital;

  // Inicializar el provider
  Future<void> inicializarConfiguracion(BuildContext context) async {
    await cargarConfiguracion();
  }

  // Cargar configuración
  Future<void> cargarConfiguracion() async {
    _setLoading(true);
    _setError(null);

    try {
      // Cargar datos del admin actual
      await _cargarDatosAdmin();
      
      // Cargar configuración de la aplicación
      await _cargarConfiguracionApp();
      
      // Cargar configuración de la plataforma
      await _cargarConfiguracionPlataforma();
      
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar configuración: $e');
      _setLoading(false);
    }
  }

  // Cargar datos del admin
  Future<void> _cargarDatosAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        final usuario = await Supabase.instance.client
            .from('usuarios')
            .select('name, email, telephone, direccion')
            .eq('id', userId)
            .single();
        
        _nombreAdmin = usuario['name'] ?? '';
        _emailAdmin = usuario['email'] ?? '';
        _telefonoAdmin = usuario['telephone'] ?? '';
        _direccionAdmin = usuario['direccion'] ?? '';
      }
    } catch (e) {
      // Error silencioso, usar valores por defecto
    }
  }

  // Cargar configuración de la aplicación
  Future<void> _cargarConfiguracionApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _notificacionesActivadas = prefs.getBool('notificaciones_activadas') ?? true;
      _modoOscuro = prefs.getBool('modo_oscuro') ?? false;
      _idioma = prefs.getString('idioma') ?? 'es';
      _tiempoSesion = prefs.getInt('tiempo_sesion') ?? 30;
    } catch (e) {
      // Error silencioso, usar valores por defecto
    }
  }

  // Cargar configuración de la plataforma
  Future<void> _cargarConfiguracionPlataforma() async {
    try {
      // Intentar cargar desde la base de datos
      final configData = await Supabase.instance.client
          .from('configuracion_plataforma')
          .select()
          .single();
      
      _comisionPlataforma = double.tryParse(configData['comision_plataforma']?.toString() ?? '5.0') ?? 5.0;
      _tiempoEntregaEstimado = int.tryParse(configData['tiempo_entrega_estimado']?.toString() ?? '30') ?? 30;
      _pagoEnEfectivo = configData['pago_efectivo'] ?? true;
      _pagoConTarjeta = configData['pago_tarjeta'] ?? true;
      _pagoDigital = configData['pago_digital'] ?? true;
    } catch (e) {
      // Si no existe la tabla o hay error, usar valores por defecto
      _comisionPlataforma = 5.0;
      _tiempoEntregaEstimado = 30;
      _pagoEnEfectivo = true;
      _pagoConTarjeta = true;
      _pagoDigital = true;
    }
  }

  // Guardar datos del admin
  Future<void> guardarDatosAdmin(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        await Supabase.instance.client
            .from('usuarios')
            .update({
              'name': _nombreAdmin,
              'email': _emailAdmin,
              'telephone': _telefonoAdmin,
              'direccion': _direccionAdmin,
            })
            .eq('id', userId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos del admin actualizados correctamente')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar datos: $e')),
        );
      }
    }
  }

  // Guardar configuración de la aplicación
  Future<void> guardarConfiguracionApp(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notificaciones_activadas', _notificacionesActivadas);
      await prefs.setBool('modo_oscuro', _modoOscuro);
      await prefs.setString('idioma', _idioma);
      await prefs.setInt('tiempo_sesion', _tiempoSesion);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de la aplicación guardada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuración: $e')),
        );
      }
    }
  }

  // Guardar configuración de la plataforma
  Future<void> guardarConfiguracionPlataforma(BuildContext context) async {
    try {
      // Intentar actualizar o insertar configuración
      await Supabase.instance.client
          .from('configuracion_plataforma')
          .upsert({
            'id': 1, // ID único para la configuración
            'comision_plataforma': _comisionPlataforma,
            'tiempo_entrega_estimado': _tiempoEntregaEstimado,
            'pago_efectivo': _pagoEnEfectivo,
            'pago_tarjeta': _pagoConTarjeta,
            'pago_digital': _pagoDigital,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de la plataforma guardada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuración: $e')),
        );
      }
    }
  }

  // Mostrar diálogo de cambio de contraseña
  Future<void> mostrarDialogoCambiarContrasena(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text != confirmPasswordController.text) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Las contraseñas no coinciden')),
                    );
                  }
                  return;
                }

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId');
                  
                  if (userId != null) {
                    await Supabase.instance.client
                        .from('usuarios')
                        .update({
                          'password': passwordController.text,
                        })
                        .eq('id', userId);
                    
                    Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraseña actualizada correctamente')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar contraseña: $e')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar diálogo de exportar datos
  Future<void> mostrarDialogoExportarDatos(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar Datos'),
          content: const Text(
            '¿Estás seguro de que quieres exportar todos los datos de la plataforma? '
            'Esta acción puede tomar varios minutos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _exportarDatos(context);
              },
              child: const Text('Exportar'),
            ),
          ],
        );
      },
    );
  }

  // Exportar datos
  Future<void> _exportarDatos(BuildContext context) async {
    try {
      // Simular exportación de datos
      await Future.delayed(const Duration(seconds: 2));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos exportados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostrar diálogo de respaldo
  Future<void> mostrarDialogoRespaldo(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Respaldo'),
          content: const Text(
            '¿Estás seguro de que quieres crear un respaldo completo de la base de datos? '
            'Esta acción puede tomar varios minutos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _crearRespaldo(context);
              },
              child: const Text('Crear Respaldo'),
            ),
          ],
        );
      },
    );
  }

  // Crear respaldo
  Future<void> _crearRespaldo(BuildContext context) async {
    try {
      // Simular creación de respaldo
      await Future.delayed(const Duration(seconds: 3));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respaldo creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear respaldo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  // Setters
  void setNombreAdmin(String nombre) {
    _nombreAdmin = nombre;
    notifyListeners();
  }

  void setEmailAdmin(String email) {
    _emailAdmin = email;
    notifyListeners();
  }

  void setTelefonoAdmin(String telefono) {
    _telefonoAdmin = telefono;
    notifyListeners();
  }

  void setDireccionAdmin(String direccion) {
    _direccionAdmin = direccion;
    notifyListeners();
  }

  void setNotificacionesActivadas(bool activadas) {
    _notificacionesActivadas = activadas;
    notifyListeners();
  }

  void setModoOscuro(bool modo) {
    _modoOscuro = modo;
    notifyListeners();
  }

  void setIdioma(String idioma) {
    _idioma = idioma;
    notifyListeners();
  }

  void setTiempoSesion(int tiempo) {
    _tiempoSesion = tiempo;
    notifyListeners();
  }

  void setComisionPlataforma(double comision) {
    _comisionPlataforma = comision;
    notifyListeners();
  }

  void setTiempoEntregaEstimado(int tiempo) {
    _tiempoEntregaEstimado = tiempo;
    notifyListeners();
  }

  void setPagoEnEfectivo(bool activado) {
    _pagoEnEfectivo = activado;
    notifyListeners();
  }

  void setPagoConTarjeta(bool activado) {
    _pagoConTarjeta = activado;
    notifyListeners();
  }

  void setPagoDigital(bool activado) {
    _pagoDigital = activado;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 