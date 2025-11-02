import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Servicio de notificaciones PROGRAMADAS para TurnoTrack
///
/// 📅 Solo maneja notificaciones recurrentes:
/// - Recordatorios diarios de check-in (7 AM)
/// - Recordatorios diarios de check-out (6 PM)
/// - Alertas de check-out perdido (1h después)
/// - Resumen semanal de rendimiento (Lunes 8 AM)
///
/// ⚡ Para notificaciones inmediatas usar: notification_service.dart
class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _notifications;

  NotificationScheduler(this._notifications);

  /// Initialize timezone data for scheduling
  Future<void> init() async {
    tz.initializeTimeZones();
  }

  /// Schedule daily check-in reminder at 7 AM
  Future<void> scheduleDailyCheckInReminder() async {
    await _notifications.zonedSchedule(
      0, // Notification ID
      '¡Hora de Check-In! ⏰',
      'No olvides registrar tu asistencia del día',
      _nextInstanceOf7AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkin',
          'Recordatorio de Check-In',
          channelDescription: 'Notificaciones diarias para recordar check-in',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule daily check-out reminder at 6 PM
  Future<void> scheduleDailyCheckOutReminder() async {
    await _notifications.zonedSchedule(
      1, // Notification ID
      'Recuerda hacer Check-Out 📍',
      'Finaliza tu jornada registrando tu salida',
      _nextInstanceOf6PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkout',
          'Recordatorio de Check-Out',
          channelDescription: 'Notificaciones diarias para recordar check-out',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule missed checkout notification (1 hour after typical end)
  Future<void> scheduleMissedCheckoutAlert(DateTime workEndTime) async {
    final alertTime = workEndTime.add(const Duration(hours: 1));

    await _notifications.zonedSchedule(
      2, // Notification ID
      '⚠️ Check-Out Pendiente',
      'Olvidaste registrar tu salida. Por favor, completa tu check-out',
      tz.TZDateTime.from(alertTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_checkout',
          'Alertas de Check-Out Perdido',
          channelDescription: 'Notificaciones cuando no se registra check-out',
          importance: Importance.max,
          priority: Priority.max,
          icon: 'app_icon',
          color: Color(0xFFFF6B6B),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule weekly performance summary (Monday 8 AM)
  Future<void> scheduleWeeklyPerformanceSummary() async {
    await _notifications.zonedSchedule(
      3, // Notification ID
      '📊 Resumen Semanal Disponible',
      'Revisa tu desempeño de la semana pasada',
      _nextInstanceOfMonday8AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary',
          'Resumen Semanal',
          channelDescription: 'Notificaciones semanales de desempeño',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'app_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get next occurrence of 7 AM (work start time)
  tz.TZDateTime _nextInstanceOf7AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7, // 7 AM
      0,
    );

    // If 7 AM already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next occurrence of 6 PM (typical work end time)
  tz.TZDateTime _nextInstanceOf6PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      18, // 6 PM
      0,
    );

    // If 6 PM already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next Monday at 8 AM
  tz.TZDateTime _nextInstanceOfMonday8AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // 8 AM
      0,
    );

    // Move to next Monday
    while (scheduledDate.weekday != DateTime.monday ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Enable daily reminders (both check-in and check-out)
  Future<void> enableDailyReminders() async {
    await scheduleDailyCheckInReminder();
    await scheduleDailyCheckOutReminder();
  }

  /// Disable daily reminders
  Future<void> disableDailyReminders() async {
    await cancelNotification(0); // Check-in
    await cancelNotification(1); // Check-out
  }

  /// Enable weekly summary
  Future<void> enableWeeklySummary() async {
    await scheduleWeeklyPerformanceSummary();
  }

  /// Disable weekly summary
  Future<void> disableWeeklySummary() async {
    await cancelNotification(3);
  }
}
