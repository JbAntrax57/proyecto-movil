import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_configuracion_provider.dart';

// configuracion_section.dart - Pantalla de configuración para el admin
// Refactorizada para usar AdminConfiguracionProvider y separar lógica de negocio
class AdminConfiguracionSection extends StatefulWidget {
  const AdminConfiguracionSection({super.key});

  @override
  State<AdminConfiguracionSection> createState() => _AdminConfiguracionSectionState();
}

class _AdminConfiguracionSectionState extends State<AdminConfiguracionSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminConfiguracionProvider>().inicializarConfiguracion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminConfiguracionProvider>(
      builder: (context, configProvider, child) {
        if (configProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (configProvider.error != null) {
          return Center(child: Text('Error: ${configProvider.error}'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuración del Sistema',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Datos del Admin
              _buildSeccionDatosAdmin(configProvider),
              const SizedBox(height: 24),

              // Configuración de la Aplicación
              _buildSeccionConfiguracionApp(configProvider),
              const SizedBox(height: 24),

              // Configuración de la Plataforma
              _buildSeccionConfiguracionPlataforma(configProvider),
              const SizedBox(height: 24),

              // Acciones del Sistema
              _buildSeccionAccionesSistema(configProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccionDatosAdmin(AdminConfiguracionProvider configProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos del Administrador',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: configProvider.nombreAdmin),
              onChanged: (value) => configProvider.setNombreAdmin(value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: configProvider.emailAdmin),
              onChanged: (value) => configProvider.setEmailAdmin(value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: configProvider.telefonoAdmin),
              onChanged: (value) => configProvider.setTelefonoAdmin(value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: configProvider.direccionAdmin),
              onChanged: (value) => configProvider.setDireccionAdmin(value),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => configProvider.guardarDatosAdmin(context),
                    child: const Text('Guardar Datos'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => configProvider.mostrarDialogoCambiarContrasena(context),
                    child: const Text('Cambiar Contraseña'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionConfiguracionApp(AdminConfiguracionProvider configProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Configuración de la Aplicación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificaciones'),
              subtitle: const Text('Activar notificaciones push'),
              value: configProvider.notificacionesActivadas,
              onChanged: (value) => configProvider.setNotificacionesActivadas(value),
            ),
            SwitchListTile(
              title: const Text('Modo Oscuro'),
              subtitle: const Text('Activar tema oscuro'),
              value: configProvider.modoOscuro,
              onChanged: (value) => configProvider.setModoOscuro(value),
            ),
            ListTile(
              title: const Text('Idioma'),
              subtitle: DropdownButton<String>(
                value: configProvider.idioma,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) => configProvider.setIdioma(value!),
              ),
            ),
            ListTile(
              title: const Text('Tiempo de Sesión'),
              subtitle: DropdownButton<int>(
                value: configProvider.tiempoSesion,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutos')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 60, child: Text('1 hora')),
                  DropdownMenuItem(value: 120, child: Text('2 horas')),
                ],
                onChanged: (value) => configProvider.setTiempoSesion(value!),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => configProvider.guardarConfiguracionApp(context),
                child: const Text('Guardar Configuración'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionConfiguracionPlataforma(AdminConfiguracionProvider configProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Configuración de la Plataforma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Comisión de la Plataforma'),
              subtitle: Slider(
                value: configProvider.comisionPlataforma,
                min: 0,
                max: 20,
                divisions: 20,
                label: '${configProvider.comisionPlataforma.toStringAsFixed(1)}%',
                onChanged: (value) => configProvider.setComisionPlataforma(value),
              ),
            ),
            ListTile(
              title: const Text('Tiempo de Entrega Estimado'),
              subtitle: Slider(
                value: configProvider.tiempoEntregaEstimado.toDouble(),
                min: 15,
                max: 60,
                divisions: 9,
                label: '${configProvider.tiempoEntregaEstimado} min',
                onChanged: (value) => configProvider.setTiempoEntregaEstimado(value.toInt()),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Métodos de Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Pago en Efectivo'),
              value: configProvider.pagoEnEfectivo,
              onChanged: (value) => configProvider.setPagoEnEfectivo(value),
            ),
            SwitchListTile(
              title: const Text('Pago con Tarjeta'),
              value: configProvider.pagoConTarjeta,
              onChanged: (value) => configProvider.setPagoConTarjeta(value),
            ),
            SwitchListTile(
              title: const Text('Pago Digital'),
              value: configProvider.pagoDigital,
              onChanged: (value) => configProvider.setPagoDigital(value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => configProvider.guardarConfiguracionPlataforma(context),
                child: const Text('Guardar Configuración de Plataforma'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionAccionesSistema(AdminConfiguracionProvider configProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Acciones del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Exportar Datos'),
              subtitle: const Text('Exportar todos los datos de la plataforma'),
              onTap: () => configProvider.mostrarDialogoExportarDatos(context),
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text('Crear Respaldo'),
              subtitle: const Text('Crear respaldo completo de la base de datos'),
              onTap: () => configProvider.mostrarDialogoRespaldo(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              subtitle: const Text('Cerrar sesión del administrador'),
              onTap: () => configProvider.cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }
} 