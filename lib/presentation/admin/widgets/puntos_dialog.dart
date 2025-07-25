import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/puntos_service.dart';

class PuntosDialog extends StatefulWidget {
  final Map<String, dynamic> dueno;
  final VoidCallback onPuntosUpdated;

  const PuntosDialog({
    Key? key,
    required this.dueno,
    required this.onPuntosUpdated,
  }) : super(key: key);

  @override
  State<PuntosDialog> createState() => _PuntosDialogState();
}

class _PuntosDialogState extends State<PuntosDialog> {
  final _formKey = GlobalKey<FormState>();
  final _puntosController = TextEditingController();
  final _motivoController = TextEditingController();
  String _tipoOperacion = 'agregar';
  bool _isLoading = false;

  @override
  void dispose() {
    _puntosController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _procesarPuntos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final puntos = int.parse(_puntosController.text);
      final motivo = _motivoController.text;
      
      print('🔄 Procesando puntos...');
      print('🔄 Puntos: $puntos');
      print('🔄 Motivo: $motivo');
      print('🔄 Operación: $_tipoOperacion');
      
      // Usar ID del admin directamente
      final adminId = '61c7d5d8-0bdf-40fb-961c-b7e24333c6a4';
      print('🔄 Admin ID: $adminId');

      bool success;
      if (_tipoOperacion == 'agregar') {
        success = await PuntosService.agregarPuntos(
          duenoId: widget.dueno['dueno_id'],
          puntos: puntos,
          motivo: motivo,
          adminId: adminId,
        );
      } else {
        success = await PuntosService.quitarPuntos(
          duenoId: widget.dueno['dueno_id'],
          puntos: puntos,
          motivo: motivo,
          adminId: adminId,
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tipoOperacion == 'agregar' 
                  ? 'Puntos agregados exitosamente' 
                  : 'Puntos quitados exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPuntosUpdated();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tipoOperacion == 'agregar' 
                  ? 'Error al agregar puntos. Verifica que tengas permisos de admin.' 
                  : 'Error al quitar puntos. Verifica que tengas permisos de admin y que el dueño tenga suficientes puntos.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${_tipoOperacion == 'agregar' ? 'Agregar' : 'Quitar'} Puntos'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del dueño
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dueño: ${widget.dueno['dueno_email'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puntos actuales: ${widget.dueno['puntos_disponibles'] ?? 0}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de operación
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'agregar', label: Text('Agregar')),
                ButtonSegment(value: 'quitar', label: Text('Quitar')),
              ],
              selected: {_tipoOperacion},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _tipoOperacion = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Campo de puntos
            TextFormField(
              controller: _puntosController,
              decoration: const InputDecoration(
                labelText: 'Cantidad de puntos',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa la cantidad de puntos';
                }
                if (int.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                if (int.parse(value) <= 0) {
                  return 'La cantidad debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de motivo
            TextFormField(
              controller: _motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                hintText: 'Ej: Bonificación por buen servicio',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un motivo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _procesarPuntos,
          style: ElevatedButton.styleFrom(
            backgroundColor: _tipoOperacion == 'agregar' ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_tipoOperacion == 'agregar' ? 'Agregar' : 'Quitar'),
        ),
      ],
    );
  }
} 