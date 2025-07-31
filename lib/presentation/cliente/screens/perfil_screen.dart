import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'historial_pedidos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../common/screens/configuracion_screen.dart';
import '../../../core/localization.dart';

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
          _error = AppLocalizations.of(context).get('no_identificar_usuario');
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
        _error = '${AppLocalizations.of(context).get('error_cargar_perfil_detalle')}$e';
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
          _error = AppLocalizations.of(context).get('no_identificar_usuario');
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

      showTopInfoMessage(
        context,
        AppLocalizations.of(context).get('perfil_actualizado'),
        icon: Icons.check_circle,
        backgroundColor: Colors.green[50],
        textColor: Colors.green[700],
        iconColor: Colors.green[700],
      );
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context).get('error_actualizar_perfil')}$e';
        _isLoading = false;
      });
    }
  }

  // Cerrar sesión
  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('cerrar_sesion')),
        content: Text(AppLocalizations.of(context).get('confirmar_cerrar_sesion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).get('cancelar')),
          ),
          ElevatedButton(
            onPressed: () async {
              // Limpia sesión de Supabase (si aplica)
              await Supabase.instance.client.auth.signOut();
              // Limpia todas las preferencias
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                context.read<CarritoProvider>().setUserEmail('');
                context.read<CarritoProvider>().setUserId('');
                context.read<CarritoProvider>().setRestauranteId(null);
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ClienteLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).get('cerrar_sesion')),
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
    final showAppBar = widget.showAppBar ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: showAppBar
          ? AppBar(
              title: Text(
                AppLocalizations.of(context).get('mi_perfil'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isLoading && _usuario != null)
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: _isEditing ? Colors.red : Colors.blue,
                    ),
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
                    tooltip: _isEditing ? AppLocalizations.of(context).get('cancelar') : AppLocalizations.of(context).get('editar'),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).get('perfil'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando perfil...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).get('error'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _cargarPerfil,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(AppLocalizations.of(context).get('intentar_nuevamente')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _usuario == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).get('error_cargar_perfil'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Header con avatar y información básica
                          _buildProfileHeader(),
                          const SizedBox(height: 24),

                          // Información personal
                          _buildPersonalInfoSection(),
                          const SizedBox(height: 24),

                          // Acciones
                          _buildActionsSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Email
          Text(
            _usuario!['email']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Badge de cliente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).get('cliente'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).get('informacion_personal'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Campo Nombre
          _buildFormField(
            controller: _nombreController,
            label: AppLocalizations.of(context).get('nombre_completo'),
            icon: Icons.person_outline,
            enabled: _isEditing,
            validator: (value) {
              if (_isEditing && (value == null || value.trim().isEmpty)) {
                return AppLocalizations.of(context).get('ingrese_nombre');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Teléfono
          _buildFormField(
            controller: _telefonoController,
            label: AppLocalizations.of(context).get('telefono'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: _isEditing,
            validator: (value) {
              if (_isEditing && (value == null || value.trim().isEmpty)) {
                return AppLocalizations.of(context).get('ingrese_telefono');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Dirección
          _buildFormField(
            controller: _direccionController,
            label: AppLocalizations.of(context).get('direccion'),
            icon: Icons.location_on_outlined,
            maxLines: 3,
            enabled: _isEditing,
            validator: (value) {
              if (_isEditing && (value == null || value.trim().isEmpty)) {
                return AppLocalizations.of(context).get('ingrese_direccion');
              }
              return null;
            },
          ),

          // Botón guardar si está editando
          if (_isEditing) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarPerfil,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  _isLoading
                      ? 'Guardando...'
                      : AppLocalizations.of(context).get('guardar_cambios'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? Colors.blue.shade600 : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).get('acciones'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Historial de pedidos
          _buildActionTile(
            icon: Icons.receipt_long,
            iconColor: Colors.blue,
            title: AppLocalizations.of(context).get('historial_pedidos'),
            subtitle: AppLocalizations.of(context).get('ver_mis_pedidos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistorialPedidosScreen(),
                ),
              );
            },
          ),

          // Configuración de idioma
          _buildActionTile(
            icon: Icons.language,
            iconColor: Colors.orange,
            title: AppLocalizations.of(context).get('configuracion'),
            subtitle: AppLocalizations.of(context).get('idioma'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracionScreen(),
                ),
              );
            },
          ),

          // Quiero ser repartidor
          _buildActionTile(
            icon: Icons.delivery_dining,
            iconColor: Colors.purple,
            title: AppLocalizations.of(context).get('quiero_ser_repartidor'),
            subtitle: AppLocalizations.of(context).get('notificar_disponibilidad'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context).get('confirmar_notificar_repartidor_titulo')),
                  content: Text(AppLocalizations.of(context).get('confirmar_notificar_repartidor_mensaje')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context).get('cancelar')),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(AppLocalizations.of(context).get('confirmar')),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              // Verificar datos del usuario
              final nombre = _nombreController.text.trim();
              final correo = _usuario?['email']?.toString() ?? '';
              final direccion = _direccionController.text.trim();
              final telefono = _telefonoController.text.trim();
              if (nombre.isEmpty || correo.isEmpty || direccion.isEmpty || telefono.isEmpty) {
                showWarningAlert(
                  context,
                  AppLocalizations.of(context).get('completar_datos_repartidor'),
                );
                return;
              }

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Obtener todos los dueños de negocios
                final duenos = await Supabase.instance.client
                    .from('usuarios')
                    .select()
                    .eq('rol', 'duenio');

                print('🔔 Encontrados ${duenos.length} dueños de restaurantes');

                // Insertar notificación para cada dueño
                for (final dueno in duenos) {
                  final usuarioId = dueno['id']?.toString() ??
                      dueno['user_id']?.toString() ??
                      dueno['uid']?.toString();
                  if (usuarioId != null && usuarioId.isNotEmpty) {
                    await Supabase.instance.client
                        .from('notificaciones')
                        .insert({
                          'usuario_id': usuarioId,
                          'mensaje': AppLocalizations.of(context)
                              .get('mensaje_repartidor_disponible')
                              .replaceAll('{nombre}', nombre)
                              .replaceAll('{correo}', correo)
                              .replaceAll('{direccion}', direccion)
                              .replaceAll('{telefono}', telefono),
                          'tipo': 'repartidor_disponible',
                          'leida': false,
                          'fecha': DateTime.now().toIso8601String(),
                        });
                    print('🔔 Notificación enviada a dueño: ${dueno['email']}');
                  } else {
                    print('⚠️ No se pudo obtener ID de usuario para: ${dueno['email']}');
                  }
                }
                Navigator.pop(context); // Cerrar loading
                showSuccessAlert(
                  context,
                  AppLocalizations.of(context).get('notificacion_enviada'),
                );
              } catch (e) {
                Navigator.pop(context); // Cerrar loading
                showErrorAlert(
                  context,
                  '${AppLocalizations.of(context).get('error_notificar')}${e.toString()}',
                );
              }
            },
          ),

          // Cerrar sesión
          _buildActionTile(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: AppLocalizations.of(context).get('cerrar_sesion'),
            subtitle: AppLocalizations.of(context).get('salir_aplicacion'),
            onTap: _cerrarSesion,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDestructive ? Colors.red.shade600 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? Colors.red.shade400 : Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
