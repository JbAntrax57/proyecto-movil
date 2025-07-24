import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'package:crypto/crypto.dart'; // Para encriptar la contraseña
import 'dart:convert'; // Para utf8.encode
import 'package:go_router/go_router.dart'; // Importa context.go
import '../../../shared/widgets/custom_alert.dart';

// register_screen.dart (común) - Pantalla de registro genérica
// Muestra un formulario de registro simple para cualquier rol.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String nombre = '';
  String rol = 'cliente';
  String telefono = '';
  String direccion = '';
  String? error;
  bool loading = false;

  // Función para encriptar la contraseña con SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Lógica de registro: crea usuario en Supabase Auth y en la tabla 'usuarios'
  void _register() async {
    setState(() {
      error = null;
      loading = true;
    });
    try {
      // Crea el usuario en Supabase Auth
      // final response = await Supabase.instance.client.auth.signUp(
      //   email: email,
      //   password: password,
      // );
      // if (response.user == null) {
      //   setState(() {
      //     loading = false;
      //     error = 'No se pudo registrar el usuario';
      //   });
      //   return;
      // }
      // Inserta el perfil en la tabla 'usuarios'
      await Supabase.instance.client.from('usuarios').insert({
        'email': email,
        'rol': rol, // Debes definir cómo se selecciona el rol
        'name': nombre,
        'telephone': telefono,
        'direccion': direccion,
        'created_at': DateTime.now().toIso8601String(),
        'password': hashPassword(password), // Contraseña encriptada
      });
      setState(() {
        loading = false;
      });
      // Navega o muestra mensaje de éxito
      if (mounted) {
        showSuccessAlert(
          context,
          'Registro exitoso. Ahora puedes iniciar sesión.',
        );
        // Navega a login después de un frame
        Future.delayed(Duration.zero, () {
          context.go('/login');
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Error al registrar: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
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
                    const Icon(Icons.person_add, size: 60, color: Colors.blue),
                    const SizedBox(height: 18),
                    Text(
                      'Crear cuenta',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onChanged: (v) => nombre = v.trim(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese su nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => telefono = v.trim(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese su teléfono' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.home),
                      ),
                      onChanged: (v) => direccion = v.trim(),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Ingrese su dirección'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v.trim(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese su email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Ingrese su contraseña'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 'cliente',
                          child: Text('Cliente'),
                        ),
                        DropdownMenuItem(
                          value: 'repartidor',
                          child: Text('Repartidor'),
                        ),
                        DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() {
                        rol = v ?? 'cliente';
                      }),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate())
                                  _register();
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
                            : const Text('Registrarse'),
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
// Fin de register_screen.dart (común)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 