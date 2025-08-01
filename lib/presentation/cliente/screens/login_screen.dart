import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:go_router/go_router.dart';
import '../../duenio/providers/notificaciones_pedidos_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cliente/screens/home_screen.dart';
import '../../repartidor/screens/pedidos_screen.dart';
import '../../duenio/screens/dashboard_screen.dart';
import '../../admin/screens/admin_home.dart';
import '../../common/screens/register_screen.dart';
import '../../../core/localization.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/http_service.dart';

// login_screen.dart - Pantalla de inicio de sesión para clientes y demo multirol
// Permite iniciar sesión con usuarios demo y navega según el rol seleccionado.
// Incluye validación de formulario, feedback visual y navegación dinámica.

// Login funcional para cliente y multirol
class ClienteLoginScreen extends StatefulWidget {
  // Pantalla de login principal para el usuario cliente (y demo para todos los roles)
  const ClienteLoginScreen({super.key});

  @override
  State<ClienteLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<ClienteLoginScreen> {
  // Llave para el formulario de login
  final _formKey = GlobalKey<FormState>();
  // Variables para email y contraseña
  String email = '';
  String password = '';
  String? error; // Mensaje de error si el login falla
  bool loading = false; // Estado de carga para mostrar spinner
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña

  // Usuarios demo por rol (Cliente, Repartidor, Dueño, Admin)
  final demoUsers = [
    {'email': 'cliente@wasp.mx', 'password': 'cliente123', 'rol': 'Cliente'},
    {'email': 'repartidor@wasp.mx', 'password': 'res123', 'rol': 'Repartidor'},
    {'email': 'res@wasp.mx', 'password': 'res123', 'rol': 'Duenio'},
    {'email': 'admin@wasp.mx', 'password': 'res123', 'rol': 'Admin'},
  ];

  // Lógica de login: usa el backend para autenticación
  void _login() async {
    setState(() {
      error = null;
      loading = true;
    });
    
    try {
      print('🔐 Login: Intentando login para: $email');
      
      // Usar el servicio de autenticación del backend
      final authData = await AuthService.login(email, password);
      
      if (authData == null) {
        setState(() {
          loading = false;
          error = 'Usuario o contraseña incorrectos';
        });
        return;
      }

      // Guardar token en el HttpService
      await HttpService.saveToken(authData['token']);
      
      final user = authData['user'];
      final userId = user['id'].toString();
      final rol = user['rol'].toLowerCase();
      
      print('🔐 Login: Login exitoso para: $email, ID: $userId, Rol: $rol');
      
      // Configura el carrito global para este usuario
      context.read<CarritoProvider>().setUserEmail(email);
      context.read<CarritoProvider>().setUserId(userId);
      
      // Guarda el estado de login, el rol y el id en shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRol', rol);
      await prefs.setString('userId', userId);
      await prefs.setString('userEmail', email);
      
      // Si es dueño, configura el restauranteId en el provider y activa notificaciones globales
      if (rol == 'duenio' && user['restaurante_id'] != null) {
        context.read<CarritoProvider>().setRestauranteId(user['restaurante_id'] as String);
        context.read<NotificacionesPedidosProvider>().configurarRestaurante(
          user['restaurante_id'] as String,
          context,
        );
      }
      
      setState(() {
        loading = false;
      });
      
      // Navega según el rol
      switch (rol) {
        case 'cliente':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
          break;
        case 'repartidor':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RepartidorPedidosScreen()),
            (route) => false,
          );
          break;
        case 'duenio':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DuenioDashboardScreen()),
            (route) => false,
          );
          break;
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            (route) => false,
          );
          break;
        default:
          setState(() {
            error = 'Rol no soportado';
          });
      }
    } catch (e) {
      print('❌ Error en login: $e');
      setState(() {
        loading = false;
        error = 'Usuario o contraseña incorrectos';
      });
    }
  }

  // Navega a la pantalla de registro
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con formulario de login y botones demo
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono de login
                    const Icon(Icons.lock, size: 60, color: Colors.blue),
                    const SizedBox(height: 18),
                    // Título
                    Text(
                      AppLocalizations.of(context).get('iniciar_sesion'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Campo de email
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v.trim(),
                      validator: (v) =>
                          v == null || v.isEmpty ? AppLocalizations.of(context).get('ingrese_email') : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo de contraseña
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('contraseña'),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v == null || v.isEmpty
                          ? AppLocalizations.of(context).get('ingrese_contraseña')
                          : null,
                    ),
                    // Mensaje de error
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    // Botón de login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) _login();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(AppLocalizations.of(context).get('entrar')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón para crear cuenta
                    TextButton(
                      onPressed: loading ? null : _goToRegister,
                      child: Text(AppLocalizations.of(context).get('crear_cuenta')),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Demo rápido para cada usuario demo real de Firestore
                    Text(
                      AppLocalizations.of(context).get('demo_rapido'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ...demoUsers.map(
                      (u) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    email = u['email']!;
                                    password = u['password']!;
                                  });
                                  _login();
                                },
                          child: Text(
                            '${u['rol']}: ${u['email']} / ${u['password']}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Fin de login_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 