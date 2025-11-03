import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../data/models/user_model.dart';
import '../../providers/analytics_provider.dart';

/// Gamified ranking screen with animated podium and badges
class RankingPage extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const RankingPage({super.key, required this.currentUser});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with TickerProviderStateMixin {
  late AnimationController _podiumController;
  late AnimationController _badgeController;
  late AnimationController _confettiController;

  String _selectedPeriod = 'Semana';
  final List<String> _periods = ['Día', 'Semana', 'Mes', 'Año'];

  @override
  void initState() {
    super.initState();

    _podiumController = AnimationController(
      vsync: this,
      duration: AppTheme.slowAnimation,
    );

    _badgeController = AnimationController(
      vsync: this,
      duration: AppTheme.normalAnimation,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Start animations
    _podiumController.forward();
    Future.delayed(AppTheme.slowAnimation, () {
      if (mounted) _badgeController.forward();
    });
  }

  @override
  void dispose() {
    _podiumController.dispose();
    _badgeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  DateRange _getDateRangeForPeriod() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Día':
        return DateRange(
          startDate: DateTime(now.year, now.month, now.day),
          endDate: now,
        );
      case 'Semana':
        return DateRange.lastWeek();
      case 'Mes':
        return DateRange.currentMonth();
      case 'Año':
        return DateRange(startDate: DateTime(now.year, 1, 1), endDate: now);
      default:
        return DateRange.currentMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateRange = _getDateRangeForPeriod();
    final rankingParams = RankingParams(dateRange: dateRange, limit: 50);
    final rankingAsync = ref.watch(performanceRankingProvider(rankingParams));

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Ranking'),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
      ),
      body: rankingAsync.when(
        data: (rankingData) {
          // Convert PerformanceMetrics to RankingUser format
          final topUsers = rankingData.take(3).toList();
          final otherUsers = rankingData.skip(3).toList();

          return _buildRankingContent(context, isDark, topUsers, otherUsers);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error al cargar ranking: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(performanceRankingProvider(rankingParams));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedFAB(
        icon: Icons.emoji_events,
        label: 'Mi Progreso',
        onPressed: _showProgressDialog,
      ),
    );
  }

  Widget _buildRankingContent(
    BuildContext context,
    bool isDark,
    List<PerformanceMetrics> topUsers,
    List<PerformanceMetrics> otherUsers,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar with gradient
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: AppTheme.primaryBlue,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Ranking',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.secondaryBlue,
                    AppTheme.accentBlue,
                  ],
                ),
              ),
              child: Stack(
                children: List.generate(15, (index) {
                  return Positioned(
                    top: math.Random().nextDouble() * 120,
                    left: math.Random().nextDouble() * 400,
                    child: Icon(
                      Icons.star,
                      color: Colors.white.withValues(alpha: 0.1),
                      size: 20 + (math.Random().nextDouble() * 10),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingL),

              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: AppTheme.spacingL),

              // Animated Podium
              _buildAnimatedPodium(topUsers),
              const SizedBox(height: AppTheme.spacingXL), // Current User Stats
              _buildCurrentUserStats(),
              const SizedBox(height: AppTheme.spacingL),

              // Badges Section
              _buildBadgesSection(),
              const SizedBox(height: AppTheme.spacingL),

              // Ranking List Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clasificación General',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Mostrar opciones de filtro
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filtrar Ranking',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.people),
                                  title: const Text('Mi equipo'),
                                  subtitle: const Text(
                                    'Solo trabajadores de mi equipo',
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Filtro: Mi equipo'),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.business),
                                  title: const Text('Toda la organización'),
                                  subtitle: const Text(
                                    'Todos los trabajadores',
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Filtro: Organización'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filtros'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Ranking List
              ...otherUsers.asMap().entries.map((entry) {
                final user = entry.value;
                return AnimatedListItem(
                  index: entry.key,
                  delay: Duration(milliseconds: 800 + (entry.key * 50).toInt()),
                  child: _buildRankingCard(
                    RankingUser(
                      name: user.userId,
                      score: user.attendanceScore,
                      rank: (user.ranking ?? 0) + 4,
                      avatar: '👤',
                      trend: 0,
                      badges: [],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: _periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: BouncyButton(
                onPressed: () {
                  setState(() => _selectedPeriod = period);
                  // Restart animations
                  _podiumController.reset();
                  _podiumController.forward();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
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

  Widget _buildAnimatedPodium(List<PerformanceMetrics> topUsers) {
    // Ensure we have at least 3 users for podium
    if (topUsers.length < 3) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('No hay suficientes datos para mostrar el podio'),
        ),
      );
    }

    // Convert to RankingUser format
    final rankingUsers = topUsers
        .take(3)
        .map(
          (m) => RankingUser(
            name: m.userId,
            score: m.attendanceScore,
            rank: m.ranking ?? 0,
            avatar: m.ranking == 1
                ? '🥇'
                : m.ranking == 2
                ? '🥈'
                : '🥉',
            trend: 0,
            badges: [],
          ),
        )
        .toList();

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Confetti effect
          if (_confettiController.value > 0)
            ...List.generate(30, (index) {
              return _ConfettiParticle(
                animation: _confettiController,
                index: index,
              );
            }),

          // Podium platforms
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodiumPlace(rankingUsers[1], 2, 140, 0.2),
              const SizedBox(width: 8),
              _buildPodiumPlace(rankingUsers[0], 1, 180, 0.0),
              const SizedBox(width: 8),
              _buildPodiumPlace(rankingUsers[2], 3, 120, 0.4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    RankingUser user,
    int place,
    double height,
    double delay,
  ) {
    final colors = [
      [const Color(0xFFFFD700), const Color(0xFFFFA500)], // Gold
      [const Color(0xFFC0C0C0), const Color(0xFF808080)], // Silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // Bronze
    ];

    final medals = ['🥇', '🥈', '🥉'];

    return AnimatedBuilder(
      animation: _podiumController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _podiumController,
            curve: Interval(delay, delay + 0.5, curve: AppTheme.bounceCurve),
          ),
        );

        return Transform.scale(
          scale: animation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with medal
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors[place - 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[place - 1][0].withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    medals[place - 1],
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Name
              SizedBox(
                width: 100,
                child: Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Score
              Text(
                '${user.score}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors[place - 1][0],
                ),
              ),
              const SizedBox(height: 8),

              // Platform
              Container(
                width: 100,
                height: height * animation.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors[place - 1][0], colors[place - 1][1]],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMedium),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[place - 1][1].withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '#$place',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserStats() {
    // Mock current user ranking
    final currentRank = 12;
    final currentScore = 85;
    final teamAvg = 78;
    final difference = currentScore - teamAvg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Tu Posición',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currentRank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.trending_up, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+3',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBubble('Tu Score', '$currentScore', Icons.star),
                _buildStatBubble('Promedio', '$teamAvg', Icons.people),
                _buildStatBubble(
                  'Diferencia',
                  '${difference > 0 ? '+' : ''}$difference',
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            SmoothProgressIndicator(
              value: currentScore / 100,
              color: Colors.white,
              height: 10,
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Estás a 13 puntos del top 10!',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBubble(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      BadgeData(
        icon: Icons.stars,
        title: 'Puntualidad Perfecta',
        description: '30 días sin retrasos',
        color: AppTheme.success,
        unlocked: true,
        progress: 1.0,
      ),
      BadgeData(
        icon: Icons.local_fire_department,
        title: 'Racha de Fuego',
        description: '15 días consecutivos',
        color: Colors.orange,
        unlocked: true,
        progress: 1.0,
      ),
      BadgeData(
        icon: Icons.trending_up,
        title: 'Mejora del Mes',
        description: '+20 puntos este mes',
        color: AppTheme.info,
        unlocked: false,
        progress: 0.65,
      ),
      BadgeData(
        icon: Icons.emoji_events,
        title: 'Top 10',
        description: 'Alcanza el top 10',
        color: AppTheme.warning,
        unlocked: false,
        progress: 0.35,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            'Logros',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _badgeController,
                builder: (context, child) {
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _badgeController,
                      curve: Interval(
                        index * 0.2,
                        (index * 0.2) + 0.5,
                        curve: AppTheme.bounceCurve,
                      ),
                    ),
                  );

                  return Transform.scale(
                    scale: animation.value,
                    child: _buildBadgeCard(badges[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BadgeData badge) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: badge.progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(badge.color),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: badge.unlocked
                      ? badge.color.withValues(alpha: 0.2)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.icon,
                  color: badge.unlocked ? badge.color : Colors.grey,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(RankingUser user) {
    final isCurrentUser = user.rank == 12; // Mock check

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isCurrentUser
              ? AppTheme.primaryBlue
              : Colors.grey.withValues(alpha: 0.1),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 40,
            child: Text(
              '#${user.rank}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? AppTheme.primaryBlue : Colors.grey[600],
              ),
            ),
          ),

          // Avatar
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(user.avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),

          // Name and badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.badges.isNotEmpty)
                  Row(
                    children: user.badges.map((badge) {
                      final icons = {
                        'perfect': '⭐',
                        'streak': '🔥',
                        'improvement': '📈',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(icons[badge] ?? ''),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Score
          Column(
            children: [
              Text(
                '${user.score}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.trend != 0)
                Row(
                  children: [
                    Icon(
                      user.trend > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 12,
                      color: user.trend > 0 ? AppTheme.success : AppTheme.error,
                    ),
                    Text(
                      '${user.trend.abs()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: user.trend > 0
                            ? AppTheme.success
                            : AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 60, color: AppTheme.warning),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Mi Progreso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildProgressItem('Score Actual', 85, 100),
              _buildProgressItem('Puntualidad', 95, 100),
              _buildProgressItem('Asistencia', 96, 100),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                '$value/$max',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SmoothProgressIndicator(
            value: value / max,
            color: AppTheme.primaryBlue,
            height: 8,
          ),
        ],
      ),
    );
  }
}

// Models
class RankingUser {
  final String name;
  final int score;
  final int rank;
  final String avatar;
  final int trend; // positive = up, negative = down
  final List<String> badges;

  RankingUser({
    required this.name,
    required this.score,
    required this.rank,
    required this.avatar,
    required this.trend,
    required this.badges,
  });
}

class BadgeData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool unlocked;
  final double progress;

  BadgeData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.unlocked,
    required this.progress,
  });
}

// Confetti animation widget
class _ConfettiParticle extends StatelessWidget {
  final Animation<double> animation;
  final int index;

  const _ConfettiParticle({required this.animation, required this.index});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index);
    final color = [
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.purple,
    ][random.nextInt(5)];

    final startX = random.nextDouble() * 400;
    final endX = startX + (random.nextDouble() - 0.5) * 100;
    final endY = 300 + random.nextDouble() * 100;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          left: Tween<double>(
            begin: startX,
            end: endX,
          ).animate(animation).value,
          top: Tween<double>(begin: 0, end: endY).animate(animation).value,
          child: Opacity(
            opacity: 1 - animation.value,
            child: Transform.rotate(
              angle: animation.value * math.pi * 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }
}
