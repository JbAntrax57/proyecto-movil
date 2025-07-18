import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _agregarClientesDemo(BuildContext context) async {
    try {
      // Lógica para agregar clientes demo
      final clientes = [
        {
          'email': 'cliente1@demo.com',
          'password': '1234',
          'nombre': 'Cliente Demo 1',
          'rol': 'Cliente',
          'carrito': [],
        },
        {
          'email': 'cliente2@demo.com',
          'password': '1234',
          'nombre': 'Cliente Demo 2',
          'rol': 'Cliente',
          'carrito': [],
        },
      ];
      for (final cliente in clientes) {
        final doc = FirebaseFirestore.instance.collection('usuarios').doc(cliente['email'] as String);
        await doc.set(cliente);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clientes demo agregados correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar clientes: $e')),
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