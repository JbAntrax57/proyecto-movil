import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/carrito_screen_provider.dart';
import '../providers/direcciones_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';
import 'direcciones_screen.dart';
import '../../../data/models/direccion_model.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _mostrarAlerta = false;
  String _mensajeAlerta = '';
  Color _colorAlerta = Colors.green;
  IconData _iconoAlerta = Icons.check_circle;

  void _mostrarAlertaPersonalizada(String mensaje, Color color, IconData icono) {
    setState(() {
      _mensajeAlerta = mensaje;
      _colorAlerta = color;
      _iconoAlerta = icono;
      _mostrarAlerta = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mostrarAlerta = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    final carritoProvider = context.watch<CarritoScreenProvider>();
    
    final tieneProductosSinNegocio = carritoProvider.tieneProductosSinNegocio(carrito);
    final total = carritoProvider.calcularTotal(carrito);

    return Container(
      color: Colors.blue[50],
      child: SafeArea(
        top: false,
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(carrito),
          body: _buildBody(carrito, tieneProductosSinNegocio),
          floatingActionButton: _buildFloatingAlert(),
          bottomNavigationBar: carrito.isNotEmpty ? _buildBottomBar(total, tieneProductosSinNegocio) : null,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(List<Map<String, dynamic>> carrito) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_cart,
              color: Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).get('mi_carrito'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      centerTitle: false,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context, carrito),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.blue[700],
              size: 18,
            ),
          ),
          onPressed: _refrescarCarrito,
          tooltip: AppLocalizations.of(context).get('refrescar_carrito'),
        ),
        if (carrito.isNotEmpty)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red[700],
                size: 18,
              ),
            ),
            onPressed: _limpiarCarrito,
            tooltip: AppLocalizations.of(context).get('vaciar_carrito_tooltip'),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> carrito, bool tieneProductosSinNegocio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          if (tieneProductosSinNegocio) _buildAdvertenciaProductos(),
          Expanded(
            child: carrito.isEmpty ? _buildCarritoVacio() : _buildListaProductos(carrito),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertenciaProductos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).get('productos_incompletos'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).get('productos_informacion_incompleta'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<CarritoProvider>().limpiarCarrito();
                    _mostrarAlertaPersonalizada(
                      AppLocalizations.of(context).get('carrito_vaciado_success'),
                      Colors.blue,
                      Icons.clear_all,
                    );
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(AppLocalizations.of(context).get('vaciar_carrito')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.store, size: 18),
                  label: Text(AppLocalizations.of(context).get('explorar')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).get('carrito_vacio'),
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).get('agregar_productos_carrito'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.store),
              label: Text(AppLocalizations.of(context).get('explorar_restaurantes')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaProductos(List<Map<String, dynamic>> carrito) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: carrito.length,
            itemBuilder: (context, index) => _buildProductoItem(carrito[index], index),
          ),
        ),
        const SizedBox(height: 190),
      ],
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> item, int index) {
    final precio = _parsePrecio(item['precio']);
    final cantidad = _parseCantidad(item['cantidad']);
    final subtotal = precio * cantidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductoHeader(item, index),
                const SizedBox(height: 16),
                _buildControlesCantidad(index, cantidad, subtotal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductoHeader(Map<String, dynamic> item, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductoImagen(item),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['nombre']?.toString() ?? 'Sin nombre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (item['descripcion'] != null && item['descripcion'].toString().isNotEmpty)
                Text(
                  item['descripcion'].toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              _buildPrecioUnitario(_parsePrecio(item['precio'])),
            ],
          ),
        ),
        _buildBotonEliminar(index),
      ],
    );
  }

  Widget _buildProductoImagen(Map<String, dynamic> item) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item['img']?.toString() ?? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fastfood,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrecioUnitario(double precio) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Text(
        '\$$precio c/u',
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBotonEliminar(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Colors.red[600],
          size: 20,
        ),
        onPressed: () => _eliminarProducto(index),
        tooltip: AppLocalizations.of(context).get('eliminar_producto'),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  Widget _buildControlesCantidad(int index, int cantidad, double subtotal) {
    return Row(
      children: [
        _buildControlesCantidadWidget(index, cantidad),
        const Spacer(),
        _buildSubtotal(subtotal),
      ],
    );
  }

  Widget _buildControlesCantidadWidget(int index, int cantidad) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBotonCantidad(
            icon: Icons.remove_rounded,
            color: cantidad > 1 ? Colors.grey[700] : Colors.grey[400],
            onTap: cantidad > 1 ? () => _modificarCantidad(index, -1) : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Text(
              '$cantidad',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildBotonCantidad(
            icon: Icons.add_rounded,
            color: Colors.green[700],
            onTap: () => _modificarCantidad(index, 1),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonCantidad({
    required IconData icon,
    required Color? color,
    required VoidCallback? onTap,
    required BorderRadius borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildSubtotal(double subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppLocalizations.of(context).get('subtotal'),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '\$$subtotal',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildFloatingAlert() {
    if (!_mostrarAlerta) return null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      height: _mostrarAlerta ? 60 : 0,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: _mostrarAlerta ? 120 : 0,
      ),
      child: AnimatedOpacity(
        opacity: _mostrarAlerta ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _colorAlerta.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _colorAlerta),
            boxShadow: [
              BoxShadow(
                color: _colorAlerta.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _iconoAlerta,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  child: Text(_mensajeAlerta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(double total, bool tieneProductosSinNegocio) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoTotal(total),
            const SizedBox(height: 20),
            _buildBotonRealizarPedido(tieneProductosSinNegocio),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTotal(double total) {
    final carrito = context.watch<CarritoProvider>().carrito;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '\$$total',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 16,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                '${carrito.length} ${carrito.length == 1 ? 'producto' : 'productos'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonRealizarPedido(bool tieneProductosSinNegocio) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: tieneProductosSinNegocio ? null : _realizarPedido,
        style: ElevatedButton.styleFrom(
          backgroundColor: tieneProductosSinNegocio ? Colors.grey[300] : Colors.green,
          foregroundColor: tieneProductosSinNegocio ? Colors.grey[600] : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: tieneProductosSinNegocio ? 0 : 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!tieneProductosSinNegocio) ...[
              const Icon(Icons.shopping_cart_checkout, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              tieneProductosSinNegocio ? 'Productos incompletos' : 'Realizar Pedido',
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de utilidad
  double _parsePrecio(dynamic precio) {
    if (precio is int) return precio.toDouble();
    if (precio is String) return double.tryParse(precio) ?? 0.0;
    if (precio is double) return precio;
    return 0.0;
  }

  int _parseCantidad(dynamic cantidad) {
    if (cantidad is int) return cantidad;
    if (cantidad is String) return int.tryParse(cantidad) ?? 1;
    if (cantidad is double) return cantidad.toInt();
    return 1;
  }

  void _modificarCantidad(int index, int cambio) {
    context.read<CarritoProvider>().modificarCantidad(index, cambio);
  }

  void _refrescarCarrito() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await context.read<CarritoProvider>().limpiarCarritosDuplicados();
      await context.read<CarritoProvider>().cargarCarrito();

      Navigator.pop(context);

      _mostrarAlertaPersonalizada(
        'Carrito refrescado y duplicados limpiados',
        Colors.green,
        Icons.check_circle,
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _mostrarAlertaPersonalizada(
        'Error al refrescar carrito: $e',
        Colors.red,
        Icons.error,
      );
    }
  }

  void _eliminarProducto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('eliminar_producto')),
        content: Text(AppLocalizations.of(context).get('confirmar_eliminar_producto')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).get('cancelar')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).get('eliminar')),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      context.read<CarritoProvider>().eliminarProducto(index);
      _mostrarAlertaPersonalizada(
        AppLocalizations.of(context).get('producto_eliminado'),
        Colors.orange,
        Icons.delete,
      );
    }
  }

  void _limpiarCarrito() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('vaciar_carrito')),
        content: Text(AppLocalizations.of(context).get('confirmar_vaciar_carrito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).get('cancelar')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).get('vaciar')),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      context.read<CarritoProvider>().limpiarCarrito();
      _mostrarAlertaPersonalizada(
        AppLocalizations.of(context).get('carrito_vaciado'),
        Colors.blue,
        Icons.clear_all,
      );
    }
  }

  Future<Map<String, String>?> _mostrarModalUbicacion() async {
    return await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const UbicacionModal(),
    );
  }

  void _realizarPedido() async {
    final carrito = context.watch<CarritoProvider>().carrito;
    final carritoProvider = context.watch<CarritoScreenProvider>();
    
    if (carrito.isEmpty) {
      _mostrarAlertaPersonalizada(
        AppLocalizations.of(context).get('carrito_vacio'),
        Colors.orange,
        Icons.shopping_cart_outlined,
      );
      return;
    }

    final ubicacionData = await _mostrarModalUbicacion();
    if (ubicacionData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail == null || userEmail.isEmpty) {
        Navigator.pop(context);
        _mostrarAlertaPersonalizada(
          'Error: No se pudo identificar al usuario. Por favor, inicia sesión nuevamente.',
          Colors.red,
          Icons.error,
        );
        return;
      }

      final pedidoExitoso = await carritoProvider.realizarPedido(
        carrito: carrito,
        userEmail: userEmail,
        ubicacion: ubicacionData['ubicacion']!,
        referencias: ubicacionData['referencias']!,
      );

      Navigator.pop(context);

      if (pedidoExitoso) {
        context.read<CarritoProvider>().limpiarCarrito();

        showTopInfoMessage(
          context,
          '¡Pedidos realizados con éxito! 🎉\nTu pedido está siendo procesado.',
          icon: Icons.check_circle,
          backgroundColor: Colors.green[50],
          textColor: Colors.green[700],
          iconColor: Colors.green[700],
          showDuration: const Duration(seconds: 4),
        );

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      } else {
        _mostrarAlertaPersonalizada(
          carritoProvider.error ?? 'Error al realizar el pedido',
          Colors.red,
          Icons.error,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarAlertaPersonalizada(
        'Error al realizar el pedido: $e',
        Colors.red,
        Icons.error,
      );
    }
  }
}

// Modal para seleccionar ubicación
class UbicacionModal extends StatefulWidget {
  const UbicacionModal({super.key});

  @override
  State<UbicacionModal> createState() => _UbicacionModalState();
}

class _UbicacionModalState extends State<UbicacionModal> {
  String? direccionManual;
  String? ubicacionActual;
  bool buscando = false;
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _referenciasController.dispose();
    super.dispose();
  }

  Future<void> _cargarDirecciones() async {
    final userEmail = context.read<CarritoProvider>().userEmail;
    if (userEmail != null) {
      await context.read<DireccionesProvider>().cargarDirecciones(userEmail);
    }
  }

  Future<Position?> obtenerMejorUbicacion({int segundos = 5}) async {
    Position? mejorPosicion;
    double mejorPrecision = double.infinity;
    final completer = Completer<Position?>();
    final subscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (position.accuracy < mejorPrecision) {
        mejorPrecision = position.accuracy;
        mejorPosicion = position;
      }
    });
    await Future.delayed(Duration(seconds: segundos));
    await subscription.cancel();
    completer.complete(mejorPosicion);
    return completer.future;
  }

  void _validarYSeleccionarDireccion(DireccionModel direccion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar dirección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres enviar tu pedido a esta dirección?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    direccion.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    direccion.direccion,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (direccion.referencias != null && direccion.referencias!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${direccion.referencias}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'ubicacion': direccion.direccion,
                'referencias': direccion.referencias ?? '',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📍 Selecciona tu ubicación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Necesitamos tu ubicación para entregar tu pedido',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildSeccionDireccionesGuardadas(),
              const SizedBox(height: 24),
              _buildBotonesAccion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionDireccionesGuardadas() {
    return Consumer<DireccionesProvider>(
      builder: (context, direccionesProvider, child) {
        if (direccionesProvider.direcciones.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mis direcciones guardadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...direccionesProvider.direcciones.map((direccion) => _buildDireccionItem(direccion)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
          );
        }
        return _buildSinDireccionesGuardadas();
      },
    );
  }

  Widget _buildDireccionItem(DireccionModel direccion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: direccion.esPredeterminada ? Colors.orange : Colors.green.shade200,
          width: direccion.esPredeterminada ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: direccion.esPredeterminada ? Colors.orange : Colors.green,
        ),
        title: Text(
          direccion.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              direccion.direccion,
              style: const TextStyle(fontSize: 12),
            ),
            if (direccion.referencias != null && direccion.referencias!.isNotEmpty)
              Text(
                'Ref: ${direccion.referencias}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (direccion.esPredeterminada)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Predeterminada',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _validarYSeleccionarDireccion(direccion),
      ),
    );
  }

  Widget _buildSinDireccionesGuardadas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_off, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'No tienes direcciones guardadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DireccionesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text('Gestionar direcciones'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Selección requerida'),
                    content: const Text(
                      'Por favor, selecciona una de tus direcciones guardadas para continuar.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}
