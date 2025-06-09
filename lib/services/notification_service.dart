import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform; // Import Platform

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    // You might want to get the local timezone string
    // tz.setLocalLocation(tz.getLocation('America/Detroit')); // Example

    const AndroidInitializationSettings
    initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ); // Or your custom notification icon e.g. '@drawable/app_icon_notification'

    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Optional callback
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          // macOS: initializationSettingsMacOS, // If you support macOS
          // linux: initializationSettingsLinux, // If you support Linux
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Optional callback for when a user taps a notification
    );

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      print("Notification permission granted on Android: $granted");
    }

    print("NotificationService initialized.");
  }

  // Example method to show a simple notification (not scheduled)
  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id', // id
          'Your Channel Name', // name
          channelDescription: 'Your channel description', // description
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDateTime, tz.local), // Use local timezone
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_reminder_channel', // Unique channel ID for subscription reminders
            'Subscription Reminders', // Channel name visible to user
            channelDescription:
                'Reminders for upcoming subscriptions', // Channel description
            importance: Importance.high,
            priority: Priority.high,
            // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional custom sound
            // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Optional
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // sound: 'default', // Or your custom sound file
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents:
            DateTimeComponents.dateAndTime, // Match exact date and time
      );
      print("Notification scheduled for ID $id at $scheduledDateTime");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Cancelled notification with ID: $id");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all notifications");
  }

  // --- Optional Callbacks ---
  // static void onDidReceiveLocalNotification(
  //     int id, String? title, String? body, String? payload) async {
  //   // display a dialog with the notification details, tap ok to go to another page
  //   print('onDidReceiveLocalNotification: id $id, title $title, body $body, payload $payload');
  // }

  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  //   final String? payload = notificationResponse.payload;
  //   if (notificationResponse.payload != null) {
  //     print('notification payload: $payload');
  //   }
  //   // Here you can navigate to a specific page based on the payload
  //   // e.g., if (payload == 'subscription_due') { navigatorKey.currentState.pushNamed('/subscriptions'); }
  // }
}
