import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String? error;
  bool loading = false;

  // Usuarios demo por rol
  final demoUsers = [
    {'email': 'cliente@demo.com', 'password': '1234', 'rol': 'Cliente'},
    {'email': 'repartidor@demo.com', 'password': '1234', 'rol': 'Repartidor'},
    {'email': 'duenio@demo.com', 'password': '1234', 'rol': 'Duenio'},
    {'email': 'admin@demo.com', 'password': '1234', 'rol': 'Admin'},
  ];

  void _login() async {
    setState(() { error = null; loading = true; });
    await Future.delayed(const Duration(milliseconds: 600));
    final user = demoUsers.cast<Map<String, String>>().firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => <String, String>{},
    );
    if (user.isEmpty) {
      setState(() { loading = false; error = 'Usuario o contraseña incorrectos'; });
      return;
    }
    // Navegar según rol
    switch (user['rol']) {
      case 'Cliente':
        Navigator.pushReplacementNamed(context, '/cliente');
        break;
      case 'Repartidor':
        Navigator.pushReplacementNamed(context, '/repartidor');
        break;
      case 'Duenio':
        Navigator.pushReplacementNamed(context, '/duenio');
        break;
      case 'Admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
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
                    const Icon(Icons.lock, size: 60, color: Colors.blue),
                    const SizedBox(height: 18),
                    Text('Iniciar sesión', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese su email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                      onChanged: (v) => password = v.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
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
                    TextButton(
                      onPressed: loading ? null : _goToRegister,
                      child: const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
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