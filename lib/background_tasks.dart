import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; // Required for timezone initialization
import 'package:timezone/timezone.dart' as tz; // Required for timezone initialization
import 'dart:typed_data';

// --- Task Names (Must match names used in lib/pages/reminder.dart) ---
const String dailyTaskName = "dailyReminderTask";
const String oneTimeTaskName = "oneTimeReminderTask";

// Global instance for notification, must be top-level
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 💡 Timezone initialization function (Repeated here for the background isolate)
void initializeTimeZones() {
  tz.initializeTimeZones();
  try {
    final String localTimezone = tz.local.name;
    tz.setLocalLocation(tz.getLocation(localTimezone));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
  }
}

// Initialize notifications for the background isolate
Future<void> _initializeNotificationsBackground() async {
  // 1. Initialize Timezones
  initializeTimeZones();

  // 2. Initialize Flutter Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // Add logic for handling notification taps if needed in the background
    onDidReceiveBackgroundNotificationResponse: (details) {
      print('Background notification response received: ${details.payload}');
    }
  );
}

// Function to show the notification immediately
Future<void> _showImmediateNotification({
    required int id, 
    required String title, 
    required String body,
  }) async {
    const String channelId = 'med_channel'; // Must match channel used in reminder.dart
    const String channelName = 'Medicine Reminders';

    final Int64List vibrationPatternList = Int64List.fromList([0, 1000, 500, 1000]);
    
    // Configuration for high-priority pop-up
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Channel for medicine reminders scheduled by Workmanager.',
      importance: Importance.max, // HIGHEST importance for pop-up
      priority: Priority.high,
      playSound: true, // Uses system default sound
      vibrationPattern: vibrationPatternList,
      fullScreenIntent: true, // Forces the notification to pop up on the lock screen
      ticker: 'ticker',
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'ReminderPayload:$id',
    );
    print("🔔 BACKGROUND WORKER: Notification $id shown for: $title");
}

// The function that runs when Workmanager fires the task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Check if inputData exists and contains necessary keys
    if (inputData == null || !inputData.containsKey('id') || !inputData.containsKey('title') || !inputData.containsKey('body')) {
      print("❌ Workmanager task failed: Missing input data for $taskName");
      return Future.value(true); // Return true to prevent endless retry
    }

    // You MUST re-initialize notifications inside the background task
    await _initializeNotificationsBackground();
    
    final int id = inputData['id'] as int;
    final String title = inputData['title'] as String;
    final String body = inputData['body'] as String;
    
    switch (taskName) {
      case dailyTaskName:
      case oneTimeTaskName:
        // Task names match. Fire the notification using the data passed.
        await _showImmediateNotification(
          id: id,
          title: title,
          body: body,
        );
        break;
      default:
        print("❓ WORKMANAGER: Unhandled task name: $taskName");
    }
    
    // Return true to indicate the task was successful.
    return Future.value(true);
  });
}