import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';

// login_screen.dart - Pantalla de inicio de sesión para clientes y demo multirol
// Permite iniciar sesión con usuarios demo y navega según el rol seleccionado.
// Incluye validación de formulario, feedback visual y navegación dinámica.
class LoginScreen extends StatefulWidget {
  // Pantalla de login principal para el usuario cliente (y demo para todos los roles)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Llave para el formulario de login
  final _formKey = GlobalKey<FormState>();
  // Variables para email y contraseña
  String email = '';
  String password = '';
  String? error; // Mensaje de error si el login falla
  bool loading = false; // Estado de carga para mostrar spinner

  // Usuarios demo por rol (Cliente, Repartidor, Dueño, Admin)
  final demoUsers = [
    {'email': 'cliente1@demo.com', 'password': '1234', 'rol': 'Cliente'},
    {'email': 'cliente2@demo.com', 'password': '1234', 'rol': 'Cliente'},
    {'email': 'repartidor@demo.com', 'password': '1234', 'rol': 'Repartidor'},
    {'email': 'duenio@demo.com', 'password': '1234', 'rol': 'Duenio'},
    {'email': 'admin@demo.com', 'password': '1234', 'rol': 'Admin'},
  ];

  // Lógica de login: consulta Firestore y navega según el rol
  void _login() async {
    setState(() { error = null; loading = true; });
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(email).get();
      if (!doc.exists) {
        setState(() { loading = false; error = 'Usuario no encontrado'; });
        return;
      }
      final data = doc.data()!;
      if (data['password'] != password) {
        setState(() { loading = false; error = 'Contraseña incorrecta'; });
        return;
      }
      // Configura el carrito global para este usuario
      context.read<CarritoProvider>().setUserEmail(email);
      // Navega según el rol
      final rol = (data['rol'] as String).toLowerCase();
      setState(() { loading = false; });
      switch (rol) {
        case 'cliente':
          Navigator.pushReplacementNamed(context, '/cliente');
          break;
        case 'repartidor':
          Navigator.pushReplacementNamed(context, '/repartidor');
          break;
        case 'duenio':
          Navigator.pushReplacementNamed(context, '/duenio');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        default:
          setState(() { error = 'Rol no soportado'; });
      }
    } catch (e) {
      setState(() { loading = false; error = 'Error de conexión: $e'; });
    }
  }

  // Navega a la pantalla de registro (placeholder)
  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    Text('Iniciar sesión', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    // Campo de email
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese su email' : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo de contraseña
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
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
                        onPressed: loading ? null : () {
                          if (_formKey.currentState!.validate()) _login();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón para crear cuenta
                    TextButton(
                      onPressed: loading ? null : _goToRegister,
                      child: const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Demo rápido para cada usuario demo real de Firestore
                    const Text('Demo rápido:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    ...demoUsers.map((u) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: OutlinedButton(
                        onPressed: loading ? null : () {
                          setState(() {
                            email = u['email']!;
                            password = u['password']!;
                          });
                          _login();
                        },
                        child: Text('${u['rol']}: ${u['email']} / ${u['password']}'),
                      ),
                    )),
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