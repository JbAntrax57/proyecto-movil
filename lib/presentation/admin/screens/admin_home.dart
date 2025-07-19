import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Obtiene los usuarios desde Supabase
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final data = await Supabase.instance.client.from('usuarios').select();
    return List<Map<String, dynamic>>.from(data);
  }
  // Actualiza un usuario en Supabase
  Future<void> actualizarUsuario(String email, Map<String, dynamic> datos) async {
    await Supabase.instance.client
        .from('usuarios')
        .update(datos)
        .eq('email', email);
  }

  Future<void> _agregarClientesDemo(BuildContext context) async {
    final clientes = [
      {
        'email': 'cliente1@demo.com',
        'password': '1234',
        'nombre': 'Juan Pérez',
        'rol': 'cliente',
        'telefono': '123456789',
        'direccion': 'Calle Principal 123',
        'fechaRegistro': DateTime.now().toIso8601String(),
      },
      {
        'email': 'cliente2@demo.com',
        'password': '1234',
        'nombre': 'María García',
        'rol': 'cliente',
        'telefono': '987654321',
        'direccion': 'Avenida Central 456',
        'fechaRegistro': DateTime.now().toIso8601String(),
      },
    ];
    try {
      for (final cliente in clientes) {
        await Supabase.instance.client.from('usuarios').insert(cliente);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clientes demo agregados')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('Poblar negocios demo'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Negocios demo poblados (ejemplo).')),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar clientes demo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _agregarClientesDemo(context),
          ),
        ],
      ),
    );
  }
} 