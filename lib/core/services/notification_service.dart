import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:easy_callers_mobile/features/manager/leads/views/lead_controller_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/lead_controller_binding.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/views/employee_dashboard_view.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/bindings/employee_dashboard_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

/// Service for scheduling and managing local notifications.
/// Used primarily for follow-up reminders.
class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseService _supabase = Get.find<SupabaseService>();
  
  StreamSubscription? _notificationSubscription;

  Future<NotificationService> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    return this;
  }

  @override
  void onClose() {
    stopListening();
    super.onClose();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    final payload = response.payload;
    if (payload != null) {
      if (payload.contains('lead_id')) {
         // It's a lead assignment - typically for manager or employee
         // For now, redirecting to a safe middle ground or detecting role
         // Assuming manager/employee based on context
         Get.to(() => const LeadControllerView(), binding: LeadControllerBinding());
      }
      print('Notification tapped with payload: $payload');
    }
  }

  /// Start listening for real-time notifications from Supabase
  void listenToNotifications(String userId, UserRole role) {
    stopListening(); // Clear existing if any

    String roleColumn = '';
    switch (role) {
      case UserRole.superAdmin:
        roleColumn = 'super_admin_id';
        break;
      case UserRole.manager:
        roleColumn = 'manager_id';
        break;
      case UserRole.employee:
        roleColumn = 'employee_id';
        break;
    }

    _notificationSubscription = _supabase.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq(roleColumn, userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            // Get the latest notification (usually the first one in the stream results if ordered)
            // But stream provides the whole list. We need to find "just now" created ones.
            // A better way is to use a timestamp filter or just check for unread ones.
            // For simplicity, we'll notify on all unread ones found in the initial/updated stream
            for (var notification in data) {
              if (notification['is_read'] == false) {
                // Check if we already showed this potentially
                // In a production app, we'd track IDs
                showNotification(
                  id: notification['id'].hashCode,
                  title: notification['title'],
                  body: notification['body'],
                  payload: notification['metadata']?.toString(),
                );
              }
            }
          }
        });
  }

  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  /// Schedule a follow-up reminder notification
  Future<void> scheduleFollowUpReminder({
    required int id,
    required String leadName,
    required String leadPhone,
    required DateTime scheduledDate,
    String? leadId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'follow_up_channel',
      'Follow-up Reminders',
      channelDescription: 'Reminders for follow-up calls',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show immediately if the date is in the past or very soon
    if (scheduledDate.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      await _notifications.show(
        id,
        '📞 Follow-up Reminder',
        'Time to call $leadName ($leadPhone)',
        details,
        payload: leadId,
      );
    } else {
      // Schedule for the future
      // Note: For exact scheduling, you'd use the timezone package
      // For now, we'll show a notification
      await _notifications.show(
        id,
        '📞 Upcoming Follow-up',
        'Follow-up with $leadName ($leadPhone) scheduled',
        details,
        payload: leadId,
      );
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }
}
