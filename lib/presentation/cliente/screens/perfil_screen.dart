import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historial_pedidos_screen.dart';

// perfil_screen.dart - Pantalla de perfil del cliente
// Permite ver y editar información del usuario
class PerfilScreen extends StatefulWidget {
  final bool? showAppBar;

  const PerfilScreen({super.key, this.showAppBar});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  String? _error;
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // Cargar perfil del usuario desde Supabase
  Future<void> _cargarPerfil() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail == null) {
        setState(() {
          _error = 'No se pudo identificar al usuario';
          _isLoading = false;
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', userEmail)
          .single();

      setState(() {
        _usuario = data;
        _nombreController.text = data['name']?.toString() ?? '';
        _telefonoController.text = data['telephone']?.toString() ?? '';
        _direccionController.text = data['direccion']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  // Guardar cambios del perfil
  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail == null) {
        setState(() {
          _error = 'No se pudo identificar al usuario';
          _isLoading = false;
        });
        return;
      }

      await Supabase.instance.client
          .from('usuarios')
          .update({
            'name': _nombreController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'direccion': _direccionController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('email', userEmail);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Error al actualizar perfil: $e';
        _isLoading = false;
      });
    }
  }

  // Cerrar sesión
  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Limpiar carrito
      context.read<CarritoProvider>().limpiarCarrito();
      context.read<CarritoProvider>().setUserEmail('');

      // Navegar al login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar ?? true; // Asegurar que sea bool

    return Container(
      color: Colors
          .blue[50], // Fondo uniforme para toda la pantalla, incluyendo el área segura superior
      child: SafeArea(
        top:
            false, // Permite que el color de fondo cubra la parte superior (barra de estado)
        child: Scaffold(
          extendBody:
              true, // Permite que el contenido se extienda detrás de widgets flotantes
          backgroundColor:
              Colors.transparent, // El fondo lo pone el Container exterior
          appBar: showAppBar
              ? AppBar(
                  title: const Text('Mi Perfil'),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (!_isLoading && _usuario != null)
                      IconButton(
                        icon: Icon(_isEditing ? Icons.close : Icons.edit),
                        onPressed: () {
                          setState(() {
                            if (_isEditing) {
                              // Cancelar edición
                              _nombreController.text =
                                  _usuario!['name']?.toString() ?? '';
                              _telefonoController.text =
                                  _usuario!['telefono']?.toString() ?? '';
                              _direccionController.text =
                                  _usuario!['direccion']?.toString() ?? '';
                            }
                            _isEditing = !_isEditing;
                          });
                        },
                        tooltip: _isEditing ? 'Cancelar' : 'Editar',
                      ),
                  ],
                )
              : null,
          body: Column(
            children: [
              // Título personalizado cuando no hay AppBar
              if (!showAppBar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Mi Perfil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              // Espacio extra para evitar que el contenido quede tapado por la barra de estado o AppBar
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                    : _error != null
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
                              'Error al cargar perfil',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarPerfil,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _usuario == null
                    ? const Center(child: Text('No se pudo cargar el perfil'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ), // Padding inferior para evitar que el navbar tape el contenido
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Avatar y email
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.blue[100],
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _usuario!['email']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.green[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          'Cliente',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Información del perfil
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Información Personal',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Nombre
                                      TextFormField(
                                        controller: _nombreController,
                                        enabled: _isEditing,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre completo',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (_isEditing &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Por favor ingresa tu nombre';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Teléfono
                                      TextFormField(
                                        controller: _telefonoController,
                                        enabled: _isEditing,
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(
                                          labelText: 'Teléfono',
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (_isEditing &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Por favor ingresa tu teléfono';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Dirección
                                      TextFormField(
                                        controller: _direccionController,
                                        enabled: _isEditing,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Dirección',
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (_isEditing &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Por favor ingresa tu dirección';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Botón guardar si está editando
                                      if (_isEditing) ...[
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _guardarPerfil,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Guardar cambios',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Acciones
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Acciones',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Historial de pedidos
                                      ListTile(
                                        leading: const Icon(
                                          Icons.receipt_long,
                                          color: Colors.blue,
                                        ),
                                        title: const Text(
                                          'Historial de pedidos',
                                        ),
                                        subtitle: const Text(
                                          'Ver todos mis pedidos',
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const HistorialPedidosScreen(),
                                            ),
                                          );
                                        },
                                      ),

                                      const Divider(),

                                      // Cerrar sesión
                                      ListTile(
                                        leading: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                        ),
                                        title: const Text('Cerrar sesión'),
                                        subtitle: const Text(
                                          'Salir de la aplicación',
                                        ),
                                        onTap: _cerrarSesion,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
