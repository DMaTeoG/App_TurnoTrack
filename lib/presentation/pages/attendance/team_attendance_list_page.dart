import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';

/// Página para visualizar asistencias del equipo (Managers/Supervisores)
///
/// Managers: Ven todas las asistencias
/// Supervisores: Solo ven asistencias de sus trabajadores
class TeamAttendanceListPage extends ConsumerStatefulWidget {
  const TeamAttendanceListPage({super.key});

  @override
  ConsumerState<TeamAttendanceListPage> createState() =>
      _TeamAttendanceListPageState();
}

class _TeamAttendanceListPageState
    extends ConsumerState<TeamAttendanceListPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedUserId; // null = todos los usuarios

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).value;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isManager = currentUser.role == 'manager';
    final bool isSupervisor = currentUser.role == 'supervisor';

    if (!isManager && !isSupervisor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sin Acceso')),
        body: const Center(
          child: Text('No tienes permisos para ver esta página'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Asistencia del Equipo'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          // Filtro de rango de fechas
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrar por fecha',
            onPressed: _selectDateRange,
          ),
          // Filtro de usuario (solo para managers)
          if (isManager)
            IconButton(
              icon: const Icon(Icons.person_search),
              tooltip: 'Filtrar por usuario',
              onPressed: () => _showUserFilterDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chip con el rango de fechas seleccionado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[50],
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _startDate = DateTime.now().subtract(
                        const Duration(days: 7),
                      );
                      _endDate = DateTime.now().add(const Duration(days: 1));
                    });
                  },
                ),
                if (_selectedUserId != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: const Text(
                      'Filtrado',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green[50],
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedUserId = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          // Lista de asistencias
          Expanded(child: _buildAttendanceList(currentUser)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(UserModel currentUser) {
    final usersAsync = ref.watch(allUsersListProvider);

    return usersAsync.when(
      data: (users) {
        // Filtrar usuarios según rol
        List<UserModel> filteredUsers = users;

        if (currentUser.role == 'supervisor') {
          // Supervisores solo ven su equipo
          filteredUsers = users
              .where((user) => user.supervisorId == currentUser.id)
              .toList();
        } else if (_selectedUserId != null) {
          // Manager con filtro de usuario específico
          filteredUsers = users
              .where((user) => user.id == _selectedUserId)
              .toList();
        }

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  currentUser.role == 'supervisor'
                      ? 'No tienes trabajadores asignados'
                      : 'No hay usuarios para mostrar',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Obtener todas las asistencias de los usuarios filtrados
        return _buildAttendancesByUser(filteredUsers);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error al cargar usuarios: $error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allUsersListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendancesByUser(List<UserModel> users) {
    // Crear una lista de todos los attendance records agrupados por fecha
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserAttendanceSection(user);
      },
    );
  }

  Widget _buildUserAttendanceSection(UserModel user) {
    final params = AttendanceHistoryParams(
      userId: user.id,
      startDate: _startDate,
      endDate: _endDate,
    );

    final attendanceAsync = ref.watch(userAttendanceHistoryProvider(params));

    return attendanceAsync.when(
      data: (attendances) {
        if (attendances.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.fullName),
              subtitle: const Text('Sin registros en este periodo'),
              trailing: Icon(
                Icons.check_circle_outline,
                color: Colors.grey[400],
              ),
            ),
          );
        }

        // Agrupar por día
        final groupedByDay = <String, List<AttendanceModel>>{};
        for (final attendance in attendances) {
          final dateKey = DateFormat(
            'yyyy-MM-dd',
          ).format(attendance.checkInTime);
          groupedByDay.putIfAbsent(dateKey, () => []);
          groupedByDay[dateKey]!.add(attendance);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${attendances.length} registros • ${groupedByDay.length} días',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAttendanceBadge(attendances),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ],
            ),
            children: groupedByDay.entries.map((entry) {
              final dateKey = entry.key;
              final dayAttendances = entry.value;
              final date = DateTime.parse(dateKey);

              return Column(
                children: [
                  // Header de fecha
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, d MMMM', 'es').format(date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de asistencias del día
                  ...dayAttendances.map((attendance) {
                    return _buildAttendanceListItem(attendance, user);
                  }),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            ),
          ),
          title: Text(user.fullName),
          trailing: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red[100],
            child: Icon(Icons.error, color: Colors.red[700]),
          ),
          title: Text(user.fullName),
          subtitle: Text('Error: ${error.toString().substring(0, 50)}...'),
        ),
      ),
    );
  }

  Widget _buildAttendanceBadge(List<AttendanceModel> attendances) {
    // Mostrar cantidad de check-ins en lugar de porcentaje de completitud
    final total = attendances.length;
    final completed = attendances.where((a) => a.checkOutTime != null).length;

    Color badgeColor;
    String badgeText;

    if (completed == total) {
      badgeColor = Colors.green;
      badgeText = '✓ $total';
    } else if (completed > 0) {
      badgeColor = Colors.orange;
      badgeText = '$completed/$total';
    } else {
      badgeColor = Colors.blue;
      badgeText = '→ $total';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildAttendanceListItem(AttendanceModel attendance, UserModel user) {
    final timeFormat = DateFormat('HH:mm');
    final hasCheckOut = attendance.checkOutTime != null;

    return InkWell(
      onTap: () => _showAttendanceDetails(attendance, user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Thumbnail de foto
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(attendance.checkInPhotoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.login, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(attendance.checkInTime),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (hasCheckOut) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.logout, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(attendance.checkOutTime!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attendance.checkInAddress ?? 'Ubicación no disponible',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasCheckOut
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasCheckOut ? 'Completo' : 'En curso',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasCheckOut ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _buildAttendanceDetailSheet(
            attendance,
            user,
            scrollController,
          );
        },
      ),
    );
  }

  Widget _buildAttendanceDetailSheet(
    AttendanceModel attendance,
    UserModel user,
    ScrollController scrollController,
  ) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Header con info del usuario
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(attendance.checkInTime),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección de entrada (check-in)
          _buildSectionTitle('📍 Entrada', Colors.green),
          const SizedBox(height: 12),
          _buildPhotoCard(
            attendance.checkInPhotoUrl,
            timeFormat.format(attendance.checkInTime),
          ),
          const SizedBox(height: 12),
          _buildLocationCard(
            attendance.checkInLatitude,
            attendance.checkInLongitude,
            attendance.checkInAddress,
          ),
          const SizedBox(height: 24),

          // Sección de salida (check-out)
          if (attendance.checkOutTime != null) ...[
            _buildSectionTitle('📍 Salida', Colors.red),
            const SizedBox(height: 12),
            _buildPhotoCard(
              attendance.checkOutPhotoUrl,
              timeFormat.format(attendance.checkOutTime!),
            ),
            const SizedBox(height: 12),
            _buildLocationCard(
              attendance.checkOutLatitude,
              attendance.checkOutLongitude,
              attendance.checkOutAddress,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El trabajador aún no ha registrado salida',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 1.0),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String? photoUrl, String timestamp) {
    if (photoUrl == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Sin foto', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Mostrar imagen en pantalla completa
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Center(
                    child: Image.network(photoUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photoUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Overlay con timestamp
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Badge de "Tap para ampliar"
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, size: 14, color: Colors.black87),
                  SizedBox(width: 4),
                  Text(
                    'Ampliar',
                    style: TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    double? latitude,
    double? longitude,
    String? address,
  ) {
    if (latitude == null || longitude == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              'Ubicación no disponible',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Mapa
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.turnotrack.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude),
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dirección y coordenadas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address != null) ...[
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  // Botón copiar
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: '$latitude, $longitude'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Coordenadas copiadas'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Botón "Abrir en Google Maps"
        ElevatedButton.icon(
          onPressed: () async {
            final url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.map, size: 18),
          label: const Text('Abrir en Google Maps'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  void _showUserFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _UserFilterDialog(
        currentUserId: _selectedUserId,
        onUserSelected: (userId) {
          setState(() {
            _selectedUserId = userId;
          });
        },
      ),
    );
  }
}

/// Diálogo para seleccionar usuario (solo managers)
class _UserFilterDialog extends ConsumerWidget {
  final String? currentUserId;
  final Function(String?) onUserSelected;

  const _UserFilterDialog({
    required this.currentUserId,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersListProvider);

    return AlertDialog(
      title: const Text('Filtrar por usuario'),
      content: SizedBox(
        width: double.maxFinite,
        child: usersAsync.when(
          data: (users) {
            return ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Todos los usuarios'),
                  trailing: currentUserId == null
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    onUserSelected(null);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ...users.map((user) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text(user.role),
                    trailing: currentUserId == user.id
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      onUserSelected(user.id);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
