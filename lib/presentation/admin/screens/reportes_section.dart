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

              // Gráfica de dona mejorada
              _buildGraficaCategoriasMejorada(reportesProvider),
              const SizedBox(height: 24),

              // Análisis detallado por categoría
              _buildAnalisisDetalladoCategorias(reportesProvider),
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

  Widget _buildGraficaCategoriasMejorada(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título flexible
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Layout vertical para pantallas muy pequeñas
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Análisis de Pedidos por Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${reportesProvider.pedidosPorCategoria.length} categorías',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal para pantallas más grandes
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: const Text(
                          'Análisis de Pedidos por Categoría',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${reportesProvider.pedidosPorCategoria.length} categorías',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            
            // KPIs de categorías con altura ajustable
            SizedBox(
              height: 80, // Altura fija para evitar overflow
              child: _buildKPIsCategorias(reportesProvider),
            ),
            const SizedBox(height: 16),
            
            // Gráfica de dona con altura ajustable
            LayoutBuilder(
              builder: (context, constraints) {
                double height = 250;
                double radius = 80;
                
                if (constraints.maxWidth < 600) {
                  height = 180;
                  radius = 60;
                }
                if (constraints.maxWidth < 400) {
                  height = 150;
                  radius = 50;
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
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: radius < 60 ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: radius * 0.4,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Leyenda mejorada con scroll si es necesario
            _buildLeyendaMejorada(reportesProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIsCategorias(AdminReportesProvider reportesProvider) {
    final categorias = reportesProvider.pedidosPorCategoria;
    if (categorias.isEmpty) return const SizedBox.shrink();

    // Calcular métricas
    final totalPedidos = categorias.fold<int>(0, (sum, cat) => sum + (cat['pedidos'] as int));
    
    // Encontrar categoría más vendida
    Map<String, dynamic> categoriaMasVendida = categorias.first;
    for (var categoria in categorias) {
      if ((categoria['pedidos'] as int) > (categoriaMasVendida['pedidos'] as int)) {
        categoriaMasVendida = categoria;
      }
    }
    
    final promedioPedidos = totalPedidos / categorias.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2; // Default para móvil
        double childAspectRatio = 2.5;
        
        if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
          childAspectRatio = 3.0;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 2.8;
        } else if (constraints.maxWidth < 400) {
          crossAxisCount = 1;
          childAspectRatio = 4.0;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
          children: [
            _buildKPICategoriaCard(
              'Total Pedidos',
              '$totalPedidos',
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildKPICategoriaCard(
              'Categorías',
              '${categorias.length}',
              Icons.category,
              Colors.purple,
            ),
            _buildKPICategoriaCard(
              'Promedio',
              '${promedioPedidos.toStringAsFixed(1)}',
              Icons.analytics,
              Colors.green,
            ),
            _buildKPICategoriaCard(
              'Mejor Categoría',
              categoriaMasVendida['categoria'],
              Icons.trending_up,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICategoriaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaMejorada(AdminReportesProvider reportesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalle por Categoría',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Layout vertical para móvil
              return Column(
                children: reportesProvider.pedidosPorCategoria.map((categoria) {
                  return _buildLeyendaItem(categoria, reportesProvider);
                }).toList(),
              );
            } else {
              // Layout horizontal para desktop
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                children: reportesProvider.pedidosPorCategoria.map((categoria) {
                  return SizedBox(
                    width: 200,
                    child: _buildLeyendaItem(categoria, reportesProvider),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLeyendaItem(Map<String, dynamic> categoria, AdminReportesProvider reportesProvider) {
    final color = reportesProvider.obtenerColorParaCategoria(categoria['categoria']);
    final porcentaje = categoria['porcentaje'];
    final pedidos = categoria['pedidos'];
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria['categoria'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                                 Text(
                   '${pedidos as int} pedidos ($porcentaje%)',
                   style: TextStyle(
                     fontSize: 10,
                     color: Colors.grey.shade600,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisDetalladoCategorias(AdminReportesProvider reportesProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis Detallado por Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tabla de análisis
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Pedidos')),
                  DataColumn(label: Text('Porcentaje')),
                  DataColumn(label: Text('Tendencia')),
                  DataColumn(label: Text('Rendimiento')),
                ],
                rows: reportesProvider.pedidosPorCategoria.map((categoria) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          categoria['categoria'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                                             DataCell(Text('${categoria['pedidos'] as int}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorPorPorcentaje(categoria['porcentaje']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoria['porcentaje']}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(_buildTendenciaIndicator(categoria['porcentaje'])),
                      DataCell(_buildRendimientoIndicator(categoria['porcentaje'])),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resumen y recomendaciones
            _buildResumenCategorias(reportesProvider),
          ],
        ),
      ),
    );
  }

  Color _getColorPorPorcentaje(int porcentaje) {
    if (porcentaje >= 30) return Colors.green;
    if (porcentaje >= 20) return Colors.orange;
    if (porcentaje >= 10) return Colors.yellow.shade700;
    return Colors.red;
  }

  Widget _buildTendenciaIndicator(int porcentaje) {
    IconData icon;
    Color color;
    
    if (porcentaje >= 25) {
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (porcentaje >= 15) {
      icon = Icons.trending_flat;
      color = Colors.orange;
    } else {
      icon = Icons.trending_down;
      color = Colors.red;
    }
    
    return Icon(icon, color: color, size: 20);
  }

  Widget _buildRendimientoIndicator(int porcentaje) {
    String texto;
    Color color;
    
    if (porcentaje >= 25) {
      texto = 'Excelente';
      color = Colors.green;
    } else if (porcentaje >= 15) {
      texto = 'Bueno';
      color = Colors.orange;
    } else if (porcentaje >= 10) {
      texto = 'Regular';
      color = Colors.yellow.shade700;
    } else {
      texto = 'Bajo';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildResumenCategorias(AdminReportesProvider reportesProvider) {
    final categorias = reportesProvider.pedidosPorCategoria;
    if (categorias.isEmpty) return const SizedBox.shrink();

    // Encontrar categoría más vendida
    Map<String, dynamic> categoriaMasVendida = categorias.first;
    for (var categoria in categorias) {
      if ((categoria['pedidos'] as int) > (categoriaMasVendida['pedidos'] as int)) {
        categoriaMasVendida = categoria;
      }
    }

    // Encontrar categoría menos vendida
    Map<String, dynamic> categoriaMenosVendida = categorias.first;
    for (var categoria in categorias) {
      if ((categoria['pedidos'] as int) < (categoriaMenosVendida['pedidos'] as int)) {
        categoriaMenosVendida = categoria;
      }
    }

    final categoriasExitosas = categorias.where((c) => c['porcentaje'] >= 15).length;
    final categoriasNecesitanAtencion = categorias.where((c) => c['porcentaje'] < 10).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Resumen del Análisis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text('• Categoría más vendida: ${categoriaMasVendida['categoria']} (${categoriaMasVendida['porcentaje']}%)'),
          Text('• Categoría menos vendida: ${categoriaMenosVendida['categoria']} (${categoriaMenosVendida['porcentaje']}%)'),
          Text('• Categorías exitosas: $categoriasExitosas de ${categorias.length}'),
          if (categoriasNecesitanAtencion > 0)
            Text(
              '• Categorías que necesitan atención: $categoriasNecesitanAtencion',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
        ],
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