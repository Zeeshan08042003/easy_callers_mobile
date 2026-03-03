import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationController extends GetxController {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        notifications.insert(
          0,
          AppNotification(
            title: notification.title,
            body: notification.body,
          ),
        );
      }
    });

    // When user taps a notification to open app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        notifications.insert(
          0,
          AppNotification(
            title: notification.title,
            body: notification.body,
          ),
        );
      }
    });
  }
}

class AppNotification {
  final String? title;
  final String? body;

  AppNotification({this.title, this.body});
}
