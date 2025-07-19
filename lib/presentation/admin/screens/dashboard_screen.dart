import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

// dashboard_screen.dart - Pantalla principal del administrador
// Muestra métricas clave, permite gestionar usuarios, negocios y pedidos, y poblar Firestore con datos de ejemplo.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class AdminDashboardScreen extends StatelessWidget {
  // Pantalla principal del dashboard de administrador
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Variables simuladas para métricas
    final usuarios = 10;
    final negocios = 3;
    final pedidos = 25;
    // Scaffold principal con cards de métricas y acciones
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Administrador'), centerTitle: true),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card de usuarios registrados
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue, size: 36),
                  title: Text('Usuarios registrados: $usuarios', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de usuarios (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Card de negocios activos
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Colors.green, size: 36),
                  title: Text('Negocios activos: $negocios', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de negocios (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Card de pedidos totales
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.deepOrange, size: 36),
                  title: Text('Pedidos totales: $pedidos', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de pedidos (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón para poblar Firestore con negocios y menús de ejemplo
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Poblar negocios de ejemplo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () async {
                  // Lista de negocios y menús de ejemplo
                  final negocios = [
                    {
                      "nombre": "Pizzería Don Juan",
                      "direccion": "Calle 1 #123",
                      "img": "https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80",
                      "categoria": "Pizza",
                      "menu": [
                        {"nombre": "Pizza Margarita", "precio": 120, "img": "https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80", "descripcion": "Clásica con tomate y albahaca"},
                        {"nombre": "Pizza Pepperoni", "precio": 140, "img": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80", "descripcion": "Pepperoni y queso fundido"},
                        {"nombre": "Pizza Hawaiana", "precio": 135, "img": "https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80", "descripcion": "Piña y jamón"},
                      ]
                    },
                    {
                      "nombre": "Sushi Express",
                      "direccion": "Av. Central 45",
                      "img": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80",
                      "categoria": "Sushi",
                      "menu": [
                        {"nombre": "Sushi Roll", "precio": 90, "img": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80", "descripcion": "Roll clásico de salmón"},
                        {"nombre": "Nigiri", "precio": 80, "img": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80", "descripcion": "Bola de arroz y pescado"},
                        {"nombre": "Tempura", "precio": 100, "img": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80", "descripcion": "Verduras y camarón fritos"},
                      ]
                    },
                    {
                      "nombre": "Tacos El Güero",
                      "direccion": "Blvd. Norte 200",
                      "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80",
                      "categoria": "Tacos",
                      "menu": [
                        {"nombre": "Taco Pastor", "precio": 25, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Carne al pastor"},
                        {"nombre": "Taco Bistec", "precio": 28, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Bistec asado"},
                        {"nombre": "Taco Campechano", "precio": 30, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Mezcla de carnes"},
                      ]
                    },
                    {
                      "nombre": "Burger House",
                      "direccion": "Calle 2 #456",
                      "img": "https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80",
                      "categoria": "Hamburguesas",
                      "menu": [
                        {"nombre": "Hamburguesa Clásica", "precio": 100, "img": "https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80", "descripcion": "Medallón de carne, queso, lechuga y tomate"},
                        {"nombre": "Hamburguesa Vegana", "precio": 120, "img": "https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80", "descripcion": "Medallón de tofu, queso vegano, lechuga y tomate"},
                        {"nombre": "Hamburguesa BBQ", "precio": 110, "img": "https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80", "descripcion": "Medallón de carne, queso, lechuga, cebolla y BBQ"},
                      ]
                    },
                    {
                      "nombre": "Veggie Life",
                      "direccion": "Calle Verde 12",
                      "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80",
                      "categoria": "Vegano",
                      "menu": [
                        {"nombre": "Ensalada Vegana", "precio": 80, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Lechuga, tomate, cebolla roja, aceitunas, queso vegano y aderezo de limón"},
                        {"nombre": "Pasta Vegana", "precio": 120, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Pasta con salsa de tomate, ajo y albahaca"},
                        {"nombre": "Tofu a la Parrilla", "precio": 150, "img": "https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80", "descripcion": "Tofu a la parrilla con salsa BBQ y verduras"},
                      ]
                    },
                  ];
                  try {
                    for (final negocio in negocios) {
                      final docRef = await Supabase.instance.client.from('negocios').insert({
                        "nombre": negocio["nombre"],
                        "direccion": negocio["direccion"],
                        "img": negocio["img"],
                        "categoria": negocio["categoria"],
                      });
                      final menu = negocio["menu"] as List;
                      for (final producto in menu) {
                        await Supabase.instance.client.from('menu').insert(producto);
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Negocios y menús agregados correctamente')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar clientes demo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
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
                    for (final cliente in clientes) {
                      await Supabase.instance.client.from('usuarios').insert(cliente);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuarios demo agregados')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtiene métricas y datos de Supabase para el dashboard
  Future<int> contarUsuarios() async {
    final data = await Supabase.instance.client.from('usuarios').select();
    return data.length;
  }
  Future<int> contarNegocios() async {
    final data = await Supabase.instance.client.from('negocios').select();
    return data.length;
  }
  Future<int> contarPedidos() async {
    final data = await Supabase.instance.client.from('pedidos').select();
    return data.length;
  }
}
// Fin de dashboard_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 