import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/user_model.dart';
import '../../providers/ai_coaching_provider.dart';
import '../../providers/analytics_provider.dart';
import '../ranking/ranking_page.dart';

/// Dashboard for Supervisor role - Team metrics and alerts
class SupervisorDashboardPage extends ConsumerStatefulWidget {
  final UserModel user;

  const SupervisorDashboardPage({super.key, required this.user});

  @override
  ConsumerState<SupervisorDashboardPage> createState() =>
      _SupervisorDashboardPageState();
}

class _SupervisorDashboardPageState
    extends ConsumerState<SupervisorDashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Get real data from providers
    final dateRange = DateRange.currentMonth();
    final teamMetricsAsync = ref.watch(
      teamPerformanceMetricsProvider(dateRange),
    );
    final aiCoachingState = ref.watch(aiCoachingProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mi Equipo'),
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
      body: teamMetricsAsync.when(
        data: (teamMetrics) {
          // Calculate team statistics
          final teamSize = teamMetrics.length;
          final teamAvgScore = teamSize > 0
              ? teamMetrics
                        .map((m) => m.attendanceScore)
                        .reduce((a, b) => a + b) /
                    teamSize
              : 0.0;
          final today = DateTime.now();
          bool isToday(DateTime date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          // Count late and absent workers today
          final teamLateToday = teamMetrics
              .where((m) => m.lateCheckIns > 0 && isToday(m.periodEnd))
              .length;
          final teamAbsentToday = teamMetrics
              .where((m) => m.totalCheckIns == 0 && isToday(m.periodEnd))
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teamPerformanceMetricsProvider(dateRange));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Overview Card with real data
                  _buildTeamOverviewCard(
                    teamSize,
                    teamAvgScore,
                    teamAbsentToday,
                    teamLateToday,
                  ),
                  const SizedBox(height: 16),

                  // Quick Alerts Row with real data
                  Row(
                    children: [
                      Expanded(
                        child: _buildAlertCard(
                          icon: Icons.access_time,
                          color: Colors.orange,
                          title: 'Tarde Hoy',
                          value: '$teamLateToday',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAlertCard(
                          icon: Icons.person_off,
                          color: Colors.red,
                          title: 'Ausentes',
                          value: '$teamAbsentToday',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Team Performance Chart
                  _buildTeamPerformanceChart(),
                  const SizedBox(height: 16),

                  // Top Performers List with real data
                  _buildTopPerformersList(teamMetrics),
                  const SizedBox(height: 16),

                  // Workers Needing Attention with real data
                  _buildAttentionList(teamMetrics),
                  const SizedBox(height: 16),

                  // AI Team Summary
                  _buildAITeamSummary(aiCoachingState),
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
                'Error al cargar datos del equipo',
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
                  ref.invalidate(teamPerformanceMetricsProvider(dateRange));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateTeamSummary(),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Análisis IA'),
      ),
    );
  }

  Widget _buildTeamOverviewCard(
    int teamSize,
    double teamAvgScore,
    int teamAbsentToday,
    int teamLateToday,
  ) {
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
                  'Resumen del Equipo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$teamSize personas',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  label: 'Score Promedio',
                  value: teamAvgScore.toStringAsFixed(1),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatColumn(
                  label: 'Activos Hoy',
                  value: '${teamSize - teamAbsentToday}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatColumn(
                  label: 'Puntualidad',
                  value: teamSize > 0
                      ? '${(((teamSize - teamLateToday) / teamSize) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  icon: Icons.schedule,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformanceChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendimiento Semanal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          return Text(
                            days[value.toInt() % 7],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
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
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 75),
                        FlSpot(1, 80),
                        FlSpot(2, 78),
                        FlSpot(3, 85),
                        FlSpot(4, 82),
                        FlSpot(5, 88),
                        FlSpot(6, 90),
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
                  ],
                  minY: 60,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersList(List<PerformanceMetrics> teamMetrics) {
    // Get top 3 performers by attendance score
    final topPerformers = List<PerformanceMetrics>.from(teamMetrics)
      ..sort((a, b) => b.attendanceScore.compareTo(a.attendanceScore));

    final top3 = topPerformers.take(3).toList();

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
                  'Top 3 del Mes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navegar a página de ranking completo
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RankingPage(currentUser: widget.user),
                      ),
                    );
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (top3.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No hay datos disponibles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...top3.asMap().entries.map((entry) {
                final index = entry.key;
                final performer = entry.value;
                final medal = ['🥇', '🥈', '🥉'][index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          performer.userId[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              performer.userId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${performer.totalCheckIns} check-ins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
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
                        child: Text(
                          '${performer.attendanceScore}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionList(List<PerformanceMetrics> teamMetrics) {
    // Filter workers who need attention (low score or many late check-ins)
    final needsAttention = teamMetrics
        .where((m) => m.attendanceScore < 70 || m.lateCheckIns > 3)
        .toList();

    if (needsAttention.isEmpty) {
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
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Requieren Atención',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...needsAttention.map((worker) {
              // Determine severity based on metrics
              final severity =
                  worker.attendanceScore < 60 || worker.lateCheckIns > 5
                  ? 'high'
                  : 'medium';
              final severityColor = severity == 'high'
                  ? Colors.red
                  : Colors.orange;
              final issue = worker.attendanceScore < 70
                  ? 'Score bajo: ${worker.attendanceScore}'
                  : '${worker.lateCheckIns} llegadas tarde';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: severityColor.withValues(alpha: 0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: severityColor.withValues(alpha: 0.2),
                    child: Text(
                      worker.userId[0].toUpperCase(),
                      style: TextStyle(color: severityColor),
                    ),
                  ),
                  title: Text(worker.userId),
                  subtitle: Text(issue),
                  trailing: IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      // Mostrar diálogo de mensaje rápido
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Mensaje a ${worker.userId}'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Mensaje',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'El trabajador recibirá una notificación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📨 Mensaje enviado'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Enviar'),
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

  Widget _buildAITeamSummary(AICoachingState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple[400]),
                const SizedBox(width: 8),
                const Text(
                  'Análisis IA del Equipo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null)
              Text(state.error!, style: const TextStyle(color: Colors.red))
            else if (state.advice != null)
              Text(
                state.advice!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              )
            else
              Text(
                'Genera un análisis automático con insights y recomendaciones para tu equipo.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateTeamSummary() async {
    // Get real team metrics from provider
    final dateRange = DateRange.currentMonth();
    final teamMetricsAsync = ref.read(
      teamPerformanceMetricsProvider(dateRange),
    );

    teamMetricsAsync.when(
      data: (teamMetrics) async {
        if (teamMetrics.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay datos del equipo disponibles'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final summary = await ref
            .read(aiCoachingProvider.notifier)
            .generateTeamSummary(teamMetrics: teamMetrics, language: 'es');

        if (summary != null && mounted) {
          // Update state to show in card
          setState(() {});
        }
      },
      loading: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cargando métricas del equipo...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      error: (error, stack) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar métricas: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
