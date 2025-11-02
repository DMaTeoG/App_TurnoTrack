import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones INSTANTÁNEAS para TurnoTrack
///
/// ⚡ Solo maneja notificaciones inmediatas:
/// - Notificaciones de check-in exitoso
/// - Alertas de ranking
/// - Recomendaciones de IA
/// - Alertas de eventos
///
/// 📅 Para notificaciones programadas usar: notification_scheduler.dart
/// - Notificaciones de eventos (ranking, metas, recomendaciones IA)
///
/// NO usa Firebase - todo es local o via Supabase Edge Functions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar notificaciones instantáneas
      await _initializeLocalNotifications();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ NotificationService (instantáneas) inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando NotificationService: $e');
      }
      rethrow;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      if (kDebugMode) {
        debugPrint('Notificación tocada con datos: $data');
      }
      // Manejar navegación
    }
  }

  // Mostrar notificación local
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'asistencia_channel',
      'Asistión',
      channelDescription: 'Notificaciones de Asistión',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // Notificaciones instantáneas específicas de la app
  Future<void> notifyCheckInSuccess() async {
    await showNotification(
      title: '✅ Entrada registrada',
      body: '¡Tu entrada ha sido registrada exitosamente!',
      id: 1,
    );
  }

  Future<void> notifyCheckOutSuccess() async {
    await showNotification(
      title: '✅ Salida registrada',
      body: '¡Tu salida ha sido registrada exitosamente!',
      id: 2,
    );
  }

  Future<void> notifyLateCheckIn(int minutesLate) async {
    await showNotification(
      title: '⚠️ Llegada tarde',
      body: 'Llegaste $minutesLate minutos tarde hoy',
      id: 3,
    );
  }

  Future<void> notifyRankingUpdate(int newRanking, int change) async {
    final emoji = change > 0
        ? '📈'
        : change < 0
        ? '📉'
        : '➡️';
    final changeText = change > 0
        ? 'subiste $change posiciones'
        : change < 0
        ? 'bajaste ${-change} posiciones'
        : 'mantuviste tu posición';

    await showNotification(
      title: '$emoji Actualización de Ranking',
      body: 'Ahora estás en el puesto #$newRanking. ¡$changeText!',
      id: 4,
    );
  }

  Future<void> notifyAIRecommendation(String recommendation) async {
    await showNotification(title: '🤖 Consejo IA', body: recommendation, id: 5);
  }

  Future<void> notifyGoalAchieved(String goalName) async {
    await showNotification(
      title: '🎯 ¡Meta alcanzada!',
      body: 'Felicidades, alcanzaste: $goalName',
      id: 6,
    );
  }

  // Notificación de sincronización pendiente
  Future<void> notifyPendingSync(int pendingItems) async {
    await showNotification(
      title: '🔄 Sincronización pendiente',
      body: 'Tienes $pendingItems registros pendientes de sincronizar',
      id: 7,
    );
  }

  // Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Obtener notificaciones activas
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      return await androidImpl.getActiveNotifications();
    }

    return [];
  }
}
