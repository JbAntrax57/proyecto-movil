import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/admin_reportes_provider.dart';

// reportes_section.dart - Pantalla de reportes para el admin
// Refactorizada para usar AdminReportesProvider y separar lógica de negocio
class AdminReportesSection extends StatefulWidget {
  const AdminReportesSection({super.key});

  @override
  State<AdminReportesSection> createState() => _AdminReportesSectionState();
}

class _AdminReportesSectionState extends State<AdminReportesSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminReportesProvider>().inicializarReportes(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminReportesProvider>(
      builder: (context, reportesProvider, child) {
        if (reportesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con selector de período
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: const Text(
                      'Dashboard de Reportes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 150,
                    child: DropdownButton<String>(
                      value: reportesProvider.periodoSeleccionado,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                        DropdownMenuItem(value: 'semana', child: Text('Esta semana')),
                        DropdownMenuItem(value: 'mes', child: Text('Este mes')),
                        DropdownMenuItem(value: 'año', child: Text('Este año')),
                      ],
                      onChanged: (value) {
                        reportesProvider.setPeriodoSeleccionado(value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPIs
              _buildKPIs(reportesProvider),
              const SizedBox(height: 24),

              // Gráficas
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Desktop layout
                    return Row(
                      children: [
                        Expanded(
                          child: _buildGraficaVentas(reportesProvider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGraficaProductos(reportesProvider),
                        ),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return Column(
                      children: [
                        _buildGraficaVentas(reportesProvider),
                        const SizedBox(height: 16),
                        _buildGraficaProductos(reportesProvider),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Gráfica de dona
              _buildGraficaCategorias(reportesProvider),
              const SizedBox(height: 24),

              // Tablas
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Desktop layout
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTablaTopNegocios(reportesProvider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTablaTopClientes(reportesProvider),
                        ),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return Column(
                      children: [
                        _buildTablaTopNegocios(reportesProvider),
                        const SizedBox(height: 16),
                        _buildTablaTopClientes(reportesProvider),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKPIs(AdminReportesProvider reportesProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3; // Default para desktop
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2; // Mobile
        }
        if (constraints.maxWidth < 400) {
          crossAxisCount = 1; // Muy pequeño
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              'Ingresos Totales',
              '\$${NumberFormat('#,###').format(reportesProvider.kpis['ingresos_totales'])}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildKPICard(
              'Pedidos Totales',
              '${reportesProvider.kpis['pedidos_totales']}',
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildKPICard(
              'Usuarios Activos',
              '${reportesProvider.kpis['usuarios_activos']}',
              Icons.people,
              Colors.orange,
            ),
            _buildKPICard(
              'Negocios Activos',
              '${reportesProvider.kpis['negocios_activos']}',
              Icons.store,
              Colors.purple,
            ),
            _buildKPICard(
              'Calificación Promedio',
              '${reportesProvider.kpis['calificacion_promedio']}',
              Icons.star,
              Colors.amber,
            ),
            _buildKPICard(
              'Tiempo Entrega',
              '${reportesProvider.kpis['tiempo_entrega_promedio']} min',
              Icons.access_time,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaVentas(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                double height = 200;
                if (constraints.maxWidth < 600) {
                  height = 150; // Más pequeño en móvil
                }
                return SizedBox(
                  height: height,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: reportesProvider.ventasPorDia.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['ventas'].toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaProductos(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos Más Vendidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                double height = 200;
                if (constraints.maxWidth < 600) {
                  height = 150; // Más pequeño en móvil
                }
                return SizedBox(
                  height: height,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 200,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      barGroups: reportesProvider.productosMasVendidos.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value['ventas'].toDouble(),
                              color: Colors.green,
                              width: 20,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaCategorias(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pedidos por Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                double height = 300;
                if (constraints.maxWidth < 600) {
                  height = 200; // Más pequeño en móvil
                }
                return SizedBox(
                  height: height,
                  child: PieChart(
                    PieChartData(
                      sections: reportesProvider.pedidosPorCategoria.map((categoria) {
                        return PieChartSectionData(
                          value: categoria['pedidos'].toDouble(),
                          title: '${categoria['porcentaje']}%',
                          color: reportesProvider.obtenerColorParaCategoria(categoria['categoria']),
                          radius: constraints.maxWidth < 600 ? 60 : 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: constraints.maxWidth < 600 ? 20 : 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Leyenda
            Wrap(
              spacing: 16,
              children: reportesProvider.pedidosPorCategoria.map((categoria) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: reportesProvider.obtenerColorParaCategoria(categoria['categoria']),
                    ),
                    const SizedBox(width: 8),
                    Text(categoria['categoria']),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaTopNegocios(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Negocios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...reportesProvider.topNegocios.map((negocio) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    negocio['nombre'][0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(negocio['nombre']),
                subtitle: Text('Dueño: ${negocio['dueno']} • ${negocio['pedidos']} pedidos'),
                trailing: Text(
                  '\$${NumberFormat('#,###').format(negocio['ingresos'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaTopClientes(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Clientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...reportesProvider.topClientes.map((cliente) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    cliente['nombre'][0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(cliente['nombre']),
                subtitle: Text('${cliente['pedidos']} pedidos'),
                trailing: Text(
                  '\$${NumberFormat('#,###').format(cliente['total_gastado'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
} 