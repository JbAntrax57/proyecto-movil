import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/direcciones_provider.dart';
import '../providers/carrito_provider.dart';
import '../../../data/models/direccion_model.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';

class DireccionesScreen extends StatefulWidget {
  const DireccionesScreen({super.key});

  @override
  State<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends State<DireccionesScreen> {
  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    final userId = context.read<CarritoProvider>().userId;
    if (userId != null) {
      await context.read<DireccionesProvider>().cargarDirecciones(userId);
    } else {
      print('❌ Error: No se encontró userId en CarritoProvider');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).get('mis_direcciones'),
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
          IconButton(
            icon: const Icon(Icons.add_location, color: Colors.blue),
            onPressed: () => _mostrarDialogoDireccion(),
            tooltip: AppLocalizations.of(context).get('agregar_direccion'),
          ),
        ],
      ),
      body: Consumer<DireccionesProvider>(
        builder: (context, direccionesProvider, child) {
          if (direccionesProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando direcciones...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (direccionesProvider.error != null) {
            return Center(
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
                      direccionesProvider.error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _cargarDirecciones,
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
            );
          }

          if (direccionesProvider.direcciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.blue[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).get('no_hay_direcciones'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      AppLocalizations.of(context).get('agregar_primera_direccion'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoDireccion(),
                    icon: const Icon(Icons.add_location, size: 20),
                    label: Text(AppLocalizations.of(context).get('agregar_direccion')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _cargarDirecciones,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: direccionesProvider.direcciones.length,
              itemBuilder: (context, index) {
                final direccion = direccionesProvider.direcciones[index];
                return _buildDireccionCard(direccion, direccionesProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDireccionCard(DireccionModel direccion, DireccionesProvider provider) {
    final isSelected = provider.direccionSeleccionada?.id == direccion.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.seleccionarDireccion(direccion);
            showTopInfoMessage(
              context,
              '${AppLocalizations.of(context).get('direccion_seleccionada')}: ${direccion.nombre}',
              icon: Icons.check_circle,
              backgroundColor: Colors.green[50],
              textColor: Colors.green[700],
              iconColor: Colors.green[700],
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: direccion.esPredeterminada ? Colors.orange : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  direccion.nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (direccion.esPredeterminada)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).get('predeterminada'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            direccion.direccion,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) => _manejarAccionDireccion(value, direccion, provider),
                      itemBuilder: (context) => [
                        if (!direccion.esPredeterminada)
                          PopupMenuItem(
                            value: 'predeterminada',
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).get('marcar_predeterminada')),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).get('editar')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).get('eliminar')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).get('direccion_seleccionada'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _manejarAccionDireccion(String accion, DireccionModel direccion, DireccionesProvider provider) {
    switch (accion) {
      case 'predeterminada':
        _marcarComoPredeterminada(direccion, provider);
        break;
      case 'editar':
        _mostrarDialogoDireccion(direccion: direccion);
        break;
      case 'eliminar':
        _confirmarEliminarDireccion(direccion, provider);
        break;
    }
  }

  Future<void> _marcarComoPredeterminada(DireccionModel direccion, DireccionesProvider provider) async {
    final userEmail = context.read<CarritoProvider>().userEmail;
    if (userEmail == null) return;

    final exito = await provider.marcarComoPredeterminada(direccion.id!, userEmail);
    
    if (exito) {
      showTopInfoMessage(
        context,
        '${AppLocalizations.of(context).get('direccion_predeterminada')}: ${direccion.nombre}',
        icon: Icons.star,
        backgroundColor: Colors.orange[50],
        textColor: Colors.orange[700],
        iconColor: Colors.orange[700],
      );
    } else {
      showErrorAlert(
        context,
        provider.error ?? AppLocalizations.of(context).get('error_marcar_predeterminada'),
      );
    }
  }

  Future<void> _confirmarEliminarDireccion(DireccionModel direccion, DireccionesProvider provider) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('eliminar_direccion')),
        content: Text(
          '${AppLocalizations.of(context).get('confirmar_eliminar_direccion')} "${direccion.nombre}"?',
        ),
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

    if (confirmado == true) {
      final exito = await provider.eliminarDireccion(direccion.id!);
      
      if (exito) {
        showTopInfoMessage(
          context,
          '${AppLocalizations.of(context).get('direccion_eliminada')}: ${direccion.nombre}',
          icon: Icons.check_circle,
          backgroundColor: Colors.green[50],
          textColor: Colors.green[700],
          iconColor: Colors.green[700],
        );
      } else {
        showErrorAlert(
          context,
          provider.error ?? AppLocalizations.of(context).get('error_eliminar_direccion'),
        );
      }
    }
  }

  void _mostrarDialogoDireccion({DireccionModel? direccion}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DireccionDialog(direccion: direccion),
    );
  }
}

class _DireccionDialog extends StatefulWidget {
  final DireccionModel? direccion;

  const _DireccionDialog({this.direccion});

  @override
  State<_DireccionDialog> createState() => _DireccionDialogState();
}

class _DireccionDialogState extends State<_DireccionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciasController = TextEditingController();
  
  bool _esPredeterminada = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.direccion != null) {
      _nombreController.text = widget.direccion!.nombre;
      _direccionController.text = widget.direccion!.direccion;
      _referenciasController.text = widget.direccion!.referencias ?? '';
      _esPredeterminada = widget.direccion!.esPredeterminada;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _referenciasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.direccion != null ? Icons.edit_location : Icons.add_location,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.direccion != null
                        ? AppLocalizations.of(context).get('editar_direccion')
                        : AppLocalizations.of(context).get('agregar_direccion'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nombre de la dirección
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('nombre_direccion'),
                  hintText: 'Ej: Casa, Trabajo, Universidad',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).get('ingrese_nombre_direccion');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('direccion'),
                  hintText: 'Ej: Calle 123, Ciudad',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).get('ingrese_direccion');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Referencias
              TextFormField(
                controller: _referenciasController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('referencias'),
                  hintText: 'Ej: Cerca del parque, edificio azul',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Checkbox para dirección predeterminada
              Row(
                children: [
                  Checkbox(
                    value: _esPredeterminada,
                    onChanged: (value) {
                      setState(() {
                        _esPredeterminada = value ?? false;
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).get('marcar_predeterminada'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context).get('cancelar')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarDireccion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.direccion != null
                                  ? AppLocalizations.of(context).get('actualizar')
                                  : AppLocalizations.of(context).get('guardar'),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarDireccion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail == null) {
        showErrorAlert(
          context,
          AppLocalizations.of(context).get('no_identificar_usuario'),
        );
        return;
      }

      final provider = context.read<DireccionesProvider>();
      final direccion = DireccionModel(
        id: widget.direccion?.id, // null para nuevas direcciones
        usuarioId: userEmail,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        referencias: _referenciasController.text.trim().isEmpty
            ? null
            : _referenciasController.text.trim(),
        esPredeterminada: _esPredeterminada,
        fechaCreacion: widget.direccion?.fechaCreacion ?? DateTime.now(),
      );

      bool exito;
      if (widget.direccion != null) {
        exito = await provider.actualizarDireccion(direccion);
      } else {
        exito = await provider.crearDireccion(direccion);
      }

      if (exito) {
        Navigator.pop(context);
        showTopInfoMessage(
          context,
          widget.direccion != null
              ? AppLocalizations.of(context).get('direccion_actualizada')
              : AppLocalizations.of(context).get('direccion_guardada'),
          icon: Icons.check_circle,
          backgroundColor: Colors.green[50],
          textColor: Colors.green[700],
          iconColor: Colors.green[700],
        );
      } else {
        showErrorAlert(
          context,
          provider.error ?? AppLocalizations.of(context).get('error_guardar_direccion'),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 