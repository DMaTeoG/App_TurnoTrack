import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/user_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/ai_coaching_provider.dart';
import '../../providers/attendance_provider.dart';

/// Dashboard for Manager role - Organization-wide KPIs and insights
class ManagerDashboardPage extends ConsumerStatefulWidget {
  final UserModel user;

  const ManagerDashboardPage({super.key, required this.user});

  @override
  ConsumerState<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends ConsumerState<ManagerDashboardPage> {
  String _selectedPeriod = 'Mes';

  @override
  Widget build(BuildContext context) {
    // Get real data from provider
    final dateRange = DateRange.currentMonth();
    final kpisAsync = ref.watch(organizationKPIsProvider(dateRange));
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Panel Gerencial'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              Navigator.pushNamed(context, '/reports');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: kpisAsync.when(
        data: (kpis) {
          // Extract KPIs from map with safe defaults
          final totalEmployees = kpis['total_employees'] as int? ?? 0;
          final activeToday = kpis['active_today'] as int? ?? 0;
          final orgAvgScore =
              (kpis['average_score'] as num?)?.toDouble() ?? 0.0;
          final totalCheckInsToday = kpis['total_check_ins'] as int? ?? 0;
          final lateToday = kpis['late_today'] as int? ?? 0;
          final supervisors = kpis['supervisors'] as int? ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(organizationKPIsProvider(dateRange));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),

                  // KPI Cards Grid with real data
                  _buildKPIGrid(
                    totalEmployees,
                    activeToday,
                    orgAvgScore,
                    lateToday,
                    totalCheckInsToday,
                    supervisors,
                  ),
                  const SizedBox(height: 16),

                  // Attendance Trend Chart
                  _buildAttendanceTrendChart(),
                  const SizedBox(height: 16),

                  // Performance Distribution
                  _buildPerformanceDistribution(),
                  const SizedBox(height: 16),

                  // Supervisors Performance
                  _buildSupervisorsSection(),
                  const SizedBox(height: 16),

                  // Department Comparison
                  _buildTopSupervisorsList(),
                  const SizedBox(height: 16),

                  // Critical Alerts
                  _buildCriticalAlerts(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar KPIs',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(organizationKPIsProvider(dateRange));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateAttendancePredictions(),
        icon: const Icon(Icons.assessment),
        label: const Text('Predicciones IA'),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Semana', 'Mes', 'Trimestre', 'Año'].map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(
    int totalEmployees,
    int activeToday,
    double orgAvgScore,
    int lateToday,
    int totalCheckInsToday,
    int supervisors,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildKPICard(
          title: 'Empleados Totales',
          value: '$totalEmployees',
          subtitle: '$supervisors supervisores',
          icon: Icons.people,
          color: Colors.blue,
          trend: '+5%',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Activos Hoy',
          value: '$activeToday',
          subtitle: totalEmployees > 0
              ? '${((activeToday / totalEmployees) * 100).toStringAsFixed(1)}% asistencia'
              : '0% asistencia',
          icon: Icons.check_circle,
          color: Colors.green,
          trend: '+2%',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Score Promedio',
          value: orgAvgScore.toStringAsFixed(1),
          subtitle: 'Organización completa',
          icon: Icons.star,
          color: Colors.amber,
          trend: '+1.5',
          trendUp: true,
        ),
        _buildKPICard(
          title: 'Llegadas Tarde',
          value: '$lateToday',
          subtitle: totalCheckInsToday > 0
              ? '${((lateToday / totalCheckInsToday) * 100).toStringAsFixed(1)}% del total'
              : '0% del total',
          icon: Icons.access_time,
          color: Colors.orange,
          trend: '-3%',
          trendUp: true,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          color: trendUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tendencia de Asistencia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '↑ Tendencia positiva',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[200], strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Ene',
                            'Feb',
                            'Mar',
                            'Abr',
                            'May',
                            'Jun',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Asistencia
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 92),
                        FlSpot(1, 93),
                        FlSpot(2, 91),
                        FlSpot(3, 94),
                        FlSpot(4, 95),
                        FlSpot(5, 96),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    // Puntualidad
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 85),
                        FlSpot(1, 86),
                        FlSpot(2, 84),
                        FlSpot(3, 88),
                        FlSpot(4, 89),
                        FlSpot(5, 90),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: 80,
                  maxY: 100,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Asistencia', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Puntualidad', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPerformanceDistribution() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Desempeño',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: 65,
                            title: '65',
                            color: Colors.green,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 25,
                            title: '25',
                            color: Colors.amber,
                            radius: 55,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 10,
                            title: '10',
                            color: Colors.orange,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPerformanceLabel(
                        'Excelente (90-100)',
                        Colors.green,
                        65,
                      ),
                      const SizedBox(height: 12),
                      _buildPerformanceLabel('Bueno (70-89)', Colors.amber, 25),
                      const SizedBox(height: 12),
                      _buildPerformanceLabel(
                        'Mejorar (<70)',
                        Colors.orange,
                        10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceLabel(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value empleados',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupervisorsSection() {
    // Mock data
    final supervisors = [
      {'name': 'Carlos Ruiz', 'team': 18, 'avgScore': 88.5},
      {'name': 'Ana García', 'team': 22, 'avgScore': 91.2},
      {'name': 'Luis Torres', 'team': 15, 'avgScore': 85.3},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rendimiento por Supervisor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navegar a Users page con filtro de supervisores
                    Navigator.pushNamed(context, '/users');
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...supervisors.map((supervisor) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.grey[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      supervisor['name'].toString()[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(supervisor['name'].toString()),
                  subtitle: Text('${supervisor['team']} personas en equipo'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${supervisor['avgScore']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSupervisorsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa por Área',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDepartmentBar('Ventas', 92, Colors.blue),
            _buildDepartmentBar('Operaciones', 88, Colors.green),
            _buildDepartmentBar('Logística', 85, Colors.orange),
            _buildDepartmentBar('Administración', 90, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentBar(String department, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                department,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts() {
    final alerts = [
      {
        'title': 'Ausentismo alto en Logística',
        'description': '15% más que el promedio',
        'severity': 'high',
      },
      {
        'title': 'Patrón de retrasos en Ventas',
        'description': 'Martes y jueves críticos',
        'severity': 'medium',
      },
    ];

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Alertas Críticas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map((alert) {
              final color = alert['severity'] == 'high'
                  ? Colors.red
                  : Colors.orange;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: color.withValues(alpha: 0.05),
                child: ListTile(
                  leading: Icon(Icons.warning, color: color),
                  title: Text(alert['title'].toString()),
                  subtitle: Text(alert['description'].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      // Mostrar diálogo con detalles de la alerta
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(alert['title'].toString()),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert['description'].toString()),
                              const SizedBox(height: 12),
                              Text(
                                'Tipo: ${alert['severity']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Generate attendance predictions using AI
  Future<void> _generateAttendancePredictions() async {
    // Show loading dialog immediately
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando predicciones con IA...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get recent attendance data from provider
      final recentAttendance = await ref.read(
        recentOrganizationAttendanceProvider.future,
      );

      final predictions = await ref
          .read(aiCoachingProvider.notifier)
          .predictAttendanceIssues(
            recentAttendance: recentAttendance,
            language: 'es',
          );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (predictions != null) {
        // Show predictions dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple),
                SizedBox(width: 8),
                Text('Predicciones IA'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                predictions,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar predicciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
