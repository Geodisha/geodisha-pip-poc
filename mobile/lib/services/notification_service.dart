// Notification service — placeholder (Firebase Messaging disabled for seed-data mode)
// ignore_for_file: unused_element

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // No-op in seed-data mode
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    // No-op in seed-data mode
  }
}
