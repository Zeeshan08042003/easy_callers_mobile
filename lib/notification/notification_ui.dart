import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(child: Text("No notifications yet"));
        }
        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final n = controller.notifications[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n.title ?? "No Title",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(n.body ?? "No Body"),
              ),
            );
          },
        );
      }),
    );
  }
}


