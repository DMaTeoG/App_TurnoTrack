import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_scheduler.dart';

// Provider para el servicio de notificaciones instantáneas (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider para el servicio de notificaciones programadas
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  return NotificationScheduler(plugin);
});

// Estados de notificación
sealed class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final bool isInitialized;
  const NotificationLoaded({this.isInitialized = true});
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
}

// Notifier para manejar las notificaciones (Riverpod 3.x)
class NotificationNotifier extends Notifier<NotificationState> {
  late final NotificationService _notificationService;
  late final NotificationScheduler _notificationScheduler;

  @override
  NotificationState build() {
    _notificationService = ref.read(notificationServiceProvider);
    _notificationScheduler = ref.read(notificationSchedulerProvider);
    return const NotificationInitial();
  }

  Future<void> initialize() async {
    state = const NotificationLoading();
    try {
      // Inicializar servicio de notificaciones instantáneas
      await _notificationService.initialize();
      // Inicializar servicio de notificaciones programadas
      await _notificationScheduler.init();
      state = const NotificationLoaded(isInitialized: true);
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  // Control de recordatorios diarios (usa notification_scheduler)
  Future<void> enableDailyReminders() async {
    try {
      await _notificationScheduler.enableDailyReminders();
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> disableDailyReminders() async {
    try {
      await _notificationScheduler.disableDailyReminders();
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  // Notificaciones instantáneas (usa notification_service)
  Future<void> notifyCheckIn() async {
    await _notificationService.notifyCheckInSuccess();
  }

  Future<void> notifyCheckOut() async {
    await _notificationService.notifyCheckOutSuccess();
  }

  Future<void> notifyLate(int minutesLate) async {
    await _notificationService.notifyLateCheckIn(minutesLate);
  }

  Future<void> notifyRankingUpdate(int ranking, int change) async {
    await _notificationService.notifyRankingUpdate(ranking, change);
  }

  Future<void> sendAIRecommendation(String recommendation) async {
    await _notificationService.notifyAIRecommendation(recommendation);
  }

  Future<void> notifyGoalAchieved(String goalName) async {
    await _notificationService.notifyGoalAchieved(goalName);
  }

  Future<void> notifyPendingSync(int pendingItems) async {
    await _notificationService.notifyPendingSync(pendingItems);
  }

  // Notificaciones programadas (usa notification_scheduler)
  Future<void> scheduleWeeklySummary() async {
    try {
      await _notificationScheduler.scheduleWeeklyPerformanceSummary();
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> cancelAll() async {
    await _notificationService.cancelAllNotifications();
    await _notificationScheduler.disableDailyReminders();
  }
}

// Provider para el notifier (Riverpod 3.x)
final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(() {
      return NotificationNotifier();
    });
