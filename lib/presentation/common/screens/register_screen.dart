import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Importa context.go
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../data/services/twilio_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/localization.dart';
import 'phone_verification_screen.dart';

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
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña

  // Lógica de registro: valida datos y navega a verificación de teléfono
  void _register() async {
    setState(() {
      error = null;
      loading = true;
    });

    try {
      // Validar número de teléfono
      if (!TwilioService.isValidPhoneNumber(telefono)) {
        setState(() {
          loading = false;
          error = 'Número de teléfono inválido';
        });
        return;
      }

      // Validar que el email no esté registrado usando el backend
      try {
        final existingUser = await AuthService.checkEmailExists(email);
        
        if (existingUser) {
          setState(() {
            loading = false;
            error = 'Este email ya está registrado';
          });
          return;
        }
      } catch (e) {
        print('❌ Error validando email: $e');
        // Si hay error en la validación, continuamos con el registro
      }

      setState(() {
        loading = false;
      });

      // Navegar a la pantalla de verificación de teléfono
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: telefono,
              email: email,
              password: password,
              nombre: nombre,
              rol: rol,
              direccion: direccion,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Error al validar datos: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).get('registro'))),
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
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
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
                          ? 'Ingrese su contraseña'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: [
                        DropdownMenuItem(
                          value: 'cliente',
                          child: Text(AppLocalizations.of(context).get('cliente')),
                        ),
                        DropdownMenuItem(
                          value: 'repartidor',
                          child: Text(AppLocalizations.of(context).get('repartidor')),
                        ),
                        DropdownMenuItem(
                          value: 'duenio', 
                          child: Text(AppLocalizations.of(context).get('duenio'))
                        ),
                        DropdownMenuItem(
                          value: 'admin', 
                          child: Text(AppLocalizations.of(context).get('admin'))
                        ),
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
                            : Text(AppLocalizations.of(context).get('registrarse')),
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