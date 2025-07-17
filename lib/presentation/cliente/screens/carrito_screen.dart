import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  const CarritoScreen({super.key, required this.carrito});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> carrito;
  String? ubicacion;
  bool pedidoRealizado = false;

  int get total => carrito.fold(0, (int sum, item) => sum + (item['precio'] as int) * (item['cantidad'] as int));

  void _realizarPedido() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => UbicacionModal(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        ubicacion = result;
        pedidoRealizado = true;
        carrito.clear();
      });
      // Simular notificación al negocio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pedido realizado! El negocio ha sido notificado.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    carrito = List<Map<String, dynamic>>.from(widget.carrito);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de compras'), centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, carrito);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: carrito.isEmpty
                ? Center(
                    child: pedidoRealizado
                        ? const Text('¡Pedido realizado! Espera la confirmación del negocio.')
                        : const Text('El carrito está vacío'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + index * 100),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(item['nombre'].toString()[0]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: item['cantidad'] > 1
                                                ? () {
                                                    setState(() {
                                                      item['cantidad']--;
                                                    });
                                                  }
                                                : null,
                                          ),
                                          Text('Cantidad: ${item['cantidad']}', style: const TextStyle(fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              setState(() {
                                                item['cantidad']++;
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                carrito.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text('\$${(item['precio'] as int) * (item['cantidad'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                Text('\$$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                ElevatedButton.icon(
                  onPressed: carrito.isEmpty ? null : _realizarPedido,
                  icon: const Icon(Icons.send),
                  label: const Text('Realizar pedido'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          ),
          if (ubicacion != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Ubicación: $ubicacion', style: const TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }
}

class UbicacionModal extends StatefulWidget {
  @override
  State<UbicacionModal> createState() => _UbicacionModalState();
}

class _UbicacionModalState extends State<UbicacionModal> {
  String? direccionManual;
  String? ubicacionActual;
  bool buscando = false;

  Future<void> _obtenerUbicacion() async {
    setState(() => buscando = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        ubicacionActual = 'Lat: ${pos.latitude}, Lng: ${pos.longitude}';
        buscando = false;
      });
    } catch (e) {
      setState(() => buscando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona tu ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: buscando ? null : _obtenerUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Usar ubicación actual'),
              ),
              if (ubicacionActual != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Ubicación actual: $ubicacionActual', style: const TextStyle(color: Colors.green)),
                ),
              const Divider(height: 32),
              TextField(
                decoration: const InputDecoration(labelText: 'Dirección manual'),
                onChanged: (v) => setState(() => direccionManual = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final ubic = ubicacionActual ?? direccionManual;
                  if (ubic == null || ubic.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debes ingresar o seleccionar una ubicación.')),
                    );
                  } else {
                    Navigator.pop(context, ubic);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirmar ubicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 