// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Rediseñada con el mismo estilo visual que el historial de pedidos del cliente
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedidos_duenio_provider.dart';
import 'package:flutter/services.dart'; // Para personalizar la status bar
import '../../../shared/widgets/top_info_message.dart';

class DuenioPedidosScreen extends StatefulWidget {
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PedidosDuenioProvider>().inicializarPedidos(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidosDuenioProvider>(
      builder: (context, pedidosProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.blue[50], // Fondo azul claro para la status bar
            statusBarIconBrightness: Brightness.dark, // Iconos oscuros
          ),
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Colors.blue[50],
              appBar: AppBar(
                backgroundColor: Colors.blue[50],
                title: const Text('Pedidos del negocio'),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => pedidosProvider.cargarPedidos(context),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              body: pedidosProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : pedidosProvider.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar pedidos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pedidosProvider.error!,
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => pedidosProvider.cargarPedidos(context),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : pedidosProvider.pedidos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay pedidos aún',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuando recibas pedidos aparecerán aquí',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Fila de badges para filtrar por estado
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: pedidosProvider.estados.map((estado) {
                              final selected = pedidosProvider.filtroEstado == estado['label'];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: ChoiceChip(
                                  label: Text(estado['label']),
                                  selected: selected,
                                  selectedColor: (estado['color'] as Color)
                                      .withValues(alpha: 0.18),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? estado['color'] as Color
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (_) {
                                    pedidosProvider.setFiltroEstado(
                                      selected ? null : estado['label'] as String,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Lista filtrada de pedidos
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: pedidosProvider.getPedidosOrdenados().length,
                            itemBuilder: (context, index) {
                              final pedidosOrdenados = pedidosProvider.getPedidosOrdenados();
                              final pedido = pedidosOrdenados[index];
                              final productos = List<Map<String, dynamic>>.from(
                                pedido['productos'] ?? [],
                              );
                              final total = pedidosProvider.calcularTotalPedido(pedido);

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header con estado y fecha
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: pedidosProvider.getEstadoColor(
                                                pedido['estado']?.toString() ??
                                                    'pendiente',
                                              ).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: pedidosProvider.getEstadoColor(
                                                  pedido['estado']?.toString() ??
                                                      'pendiente',
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  pedidosProvider.getEstadoIcon(
                                                    pedido['estado']?.toString() ??
                                                        'pendiente',
                                                  ),
                                                  size: 16,
                                                  color: pedidosProvider.getEstadoColor(
                                                    pedido['estado']?.toString() ??
                                                        'pendiente',
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  pedido['estado']
                                                          ?.toString()
                                                          .toUpperCase() ??
                                                      'PENDIENTE',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: pedidosProvider.getEstadoColor(
                                                      pedido['estado']
                                                              ?.toString() ??
                                                          'pendiente',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            pedidosProvider.formatearFecha(
                                              pedido['created_at']?.toString() ??
                                                  '',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Productos
                                      Text(
                                        'Productos:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...productos
                                          .take(3)
                                          .map(
                                            (producto) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '• ${producto['nombre']?.toString() ?? 'Sin nombre'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    'x${producto['cantidad']?.toString() ?? '1'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      if (productos.length > 3)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '... y ${productos.length - 3} más',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 12),
                                      const Divider(),

                                      // Total y ubicación
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total: \$${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              if (pedido['direccion_entrega'] != null)
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    '📍 ${pedido['direccion_entrega']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.info_outline),
                                            onPressed: () {
                                              pedidosProvider.mostrarDetallesPedido(context, pedido);
                                            },
                                            tooltip: 'Ver detalles',
                                          ),
                                        ],
                                      ),

                                      // Botón para cambiar estado debajo de la card
                                      const SizedBox(height: 16),
                                      Center(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Cambiar estado'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final nuevoEstado = await pedidosProvider.mostrarModalCambiarEstado(
                                              context,
                                              pedido['estado']?.toString() ?? 'pendiente',
                                            );
                                            if (nuevoEstado != null &&
                                                nuevoEstado != pedido['estado'] &&
                                                context.mounted) {
                                              try {
                                                await pedidosProvider.actualizarEstadoPedido(
                                                  pedido['id'].toString(),
                                                  nuevoEstado,
                                                  context,
                                                );
                                                if (context.mounted) {
                                                  showTopInfoMessage(
                                                    context,
                                                    'Estado actualizado a $nuevoEstado',
                                                    icon: Icons.check_circle,
                                                    backgroundColor: Colors.green[50],
                                                    textColor: Colors.green[700],
                                                    iconColor: Colors.green[700],
                                                    showDuration: const Duration(seconds: 2),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  showTopInfoMessage(
                                                    context,
                                                    'Error al actualizar estado: $e',
                                                    icon: Icons.error,
                                                    backgroundColor: Colors.red[50],
                                                    textColor: Colors.red[700],
                                                    iconColor: Colors.red[700],
                                                    showDuration: const Duration(seconds: 2),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
