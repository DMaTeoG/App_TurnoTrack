import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/ai_coaching_provider.dart';
import '../providers/analytics_provider.dart'; // Contiene DateRange y userPerformanceMetricsProvider
import '../../core/widgets/animated_widgets.dart';
import '../pages/ranking/ranking_page.dart';
import '../pages/dashboards/worker_dashboard_page.dart';
import '../pages/sales/sales_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final attendanceState = ref.watch(attendanceProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildHomeContent(theme, user, attendanceState);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHomeContent(ThemeData theme, user, AsyncValue attendanceState) {
    final hasCheckedIn = ref
        .read(attendanceProvider.notifier)
        .hasCheckedInToday;

    // Obtener nombre real del usuario
    final firstName = user.fullName?.split(' ').first ?? 'Usuario';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $firstName',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Mostrar panel de notificaciones activas
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.notifications_active, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Notificaciones'),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🔔 Notificaciones habilitadas'),
                          SizedBox(height: 8),
                          Text('Recibirás alertas de:'),
                          SizedBox(height: 4),
                          Text('• Check-in exitoso'),
                          Text('• Actualizaciones de ranking'),
                          Text('• Recomendaciones de IA'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed('/settings');
                          },
                          child: const Text('Configurar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed('/settings');
                },
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Check-in Card
                _buildCheckInCard(theme, hasCheckedIn),
                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(theme),
                const SizedBox(height: 24),

                // Recent Activity
                _buildRecentActivity(theme),
                const SizedBox(height: 24),

                // AI Recommendations - Botón para generar bajo demanda
                _buildAIRecommendationsButton(theme),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildCheckInCard(ThemeData theme, bool hasCheckedIn) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registra tu Entrada',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toma una foto para comenzar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/check-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Registrar Entrada'),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickStats(ThemeData theme) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Obtener datos reales - solo ventas por ahora
    final salesStatsAsync = ref.watch(salesStatisticsProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen del Mes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Asistencias',
                'Sin datos',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Puntualidad',
                'Sin datos',
                Icons.access_time,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Ranking',
                'Sin datos',
                Icons.emoji_events,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: salesStatsAsync.when(
                data: (stats) => GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(SmoothPageRoute(page: const SalesPage()));
                  },
                  child: _buildStatCard(
                    theme,
                    'Ventas',
                    stats.totalSales > 0
                        ? '\$${(stats.totalAmount / 1000).toStringAsFixed(1)}K'
                        : 'Sin datos',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                loading: () => _buildStatCard(
                  theme,
                  'Ventas',
                  '...',
                  Icons.trending_up,
                  Colors.purple,
                ),
                error: (_, __) => GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(SmoothPageRoute(page: const SalesPage()));
                  },
                  child: _buildStatCard(
                    theme,
                    'Ventas',
                    'Sin datos',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad Reciente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('Ver Todo')),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) => _buildActivityItem(theme, index)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActivityItem(ThemeData theme, int index) {
    final times = ['8:30 AM', 'Ayer, 8:25 AM', '19 Nov, 8:35 AM'];
    final types = ['Entrada', 'Entrada', 'Entrada'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.login,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  types[index],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(times[index], style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  /// Botón para generar consejos IA bajo demanda
  Widget _buildAIRecommendationsButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Consejos IA',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¿Quieres recibir consejos personalizados basados en tu rendimiento?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAIRecommendations(),
              icon: const Icon(Icons.psychology),
              label: const Text('Generar Consejos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms);
  }

  /// Muestra los consejos IA en un diálogo (motivacional, sin presión)
  Future<void> _showAIRecommendations() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Mostrar loading directamente (el botón YA es la confirmación)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando consejos motivacionales...'),
                SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.pink),
                    SizedBox(width: 4),
                    Text(
                      'Powered by Google Gemini',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Obtener métricas del usuario
    final dateRange = DateRange.currentMonth();
    final metricsAsync = ref.read(userPerformanceMetricsProvider(dateRange));

    await metricsAsync.when(
      data: (metrics) async {
        try {
          // Llamar a Gemini con tipo MOTIVACIONAL
          await ref
              .read(aiCoachingProvider.notifier)
              .generateAdvice(
                user: user,
                metrics: metrics,
                language: 'es',
                coachingType: 'motivational', // Tipo motivacional para Home
              );

          if (!mounted) return;

          // Cerrar loading
          Navigator.pop(context);

          // Obtener el consejo generado
          final aiState = ref.read(aiCoachingProvider);

          if (aiState.advice != null) {
            // Mostrar resultados en diálogo
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Consejos Motivacionales',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: Text(
                            aiState.advice!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                            ),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            throw Exception('No se generó ningún consejo');
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Cerrar loading

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al generar consejos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      loading: () {
        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargando métricas...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (error, _) async {
        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        // Mostrar mensaje motivacional genérico
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Consejo del Día'),
              ],
            ),
            content: const Text(
              '¡Hoy es un buen día para dar lo mejor de ti! 💫\n\n'
              'Recuerda: la puntualidad y la constancia son clave para el éxito.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(theme, 0, Icons.home, 'Inicio'),
              _buildNavItem(theme, 1, Icons.shopping_bag, 'Ventas'),
              _buildNavItem(theme, 2, Icons.emoji_events, 'Ranking'),
              _buildNavItem(theme, 3, Icons.bar_chart, 'Stats'),
              _buildNavItem(theme, 4, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    ThemeData theme,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        final user = ref.read(authNotifierProvider).value;

        if (user == null) return;

        // Navigate to sales page
        if (index == 1) {
          Navigator.of(context).push(SmoothPageRoute(page: const SalesPage()));
        }
        // Navigate to ranking page
        else if (index == 2) {
          Navigator.of(
            context,
          ).push(SmoothPageRoute(page: RankingPage(currentUser: user)));
        }
        // Navigate to stats (worker dashboard)
        else if (index == 3) {
          Navigator.of(
            context,
          ).push(SmoothPageRoute(page: WorkerDashboardPage(user: user)));
        }
        // Navigate to profile/settings
        else if (index == 4) {
          Navigator.of(context).pushNamed('/settings');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
