import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _agregarClientesDemo(BuildContext context) async {
    final clientes = [
      {
        'email': 'cliente1@demo.com',
        'password': '1234',
        'nombre': 'Cliente Demo 1',
        'rol': 'cliente',
        'carrito': [],
      },
      {
        'email': 'cliente2@demo.com',
        'password': '1234',
        'nombre': 'Cliente Demo 2',
        'rol': 'cliente',
        'carrito': [],
      },
    ];
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final cliente in clientes) {
        final doc = FirebaseFirestore.instance.collection('usuarios').doc(cliente['email']);
        batch.set(doc, cliente);
      }
      await batch.commit();
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
        children: [
          // Botón de poblar negocios (ejemplo, si no existe)
          ElevatedButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('Poblar negocios demo'),
            onPressed: () {
              // Aquí iría la lógica para poblar negocios
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Negocios demo poblados (ejemplo).')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(height: 16),
          // Botón de clientes demo debajo
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar clientes demo'),
            onPressed: () => _agregarClientesDemo(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          // ... el resto del contenido ...
        ],
      ),
    );
  }
} 