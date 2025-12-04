import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:medi_app/controllers/db_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// Global instance of the notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initializes the time zones and **locks the system to IST (Asia/Kolkata)**.
void initializeTimeZones() {
  tz.initializeTimeZones();
  const istLocationName = 'Asia/Kolkata'; // IST Time Zone ID

  try {
    // CRITICAL FIX: Explicitly set the local time zone to IST
    tz.setLocalLocation(tz.getLocation(istLocationName));
    print("Timezone initialized successfully and locked to: ${tz.local.name}");
  } catch (e) {
    // Fallback if IST location is not found
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    print("Timezone initialization error: Falling back to UTC. $e");
  }
}

enum RecurrenceType { daily, dateRange }

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  // Assuming DbHelper is available and correctly imported
  final DbHelper dbHelper = DbHelper(); 

  static const List<Color> _gradientColors = [
    Color(0xFFE0F7FA),
    Colors.white,
  ];
  static const List<IconData> _backgroundIcons = [
    Icons.medical_services_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long,
    Icons.calendar_month,
    Icons.add_box_outlined,
    Icons.local_pharmacy_outlined,
  ];

  final List<Map<String, dynamic>> _reminders = [];
  bool _exactAlarmGranted = false; 

  @override
  void initState() {
    super.initState();
    initializeTimeZones(); // Initializes and locks to IST
    _initializeNotifications();
    _loadSavedReminders();
  }

  Future<void> _loadSavedReminders() async {
    // Placeholder for loading persisted reminders from DB
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // handle taps
      },
    );

    if (Platform.isAndroid) {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        try {
          final granted = await androidImpl.requestExactAlarmsPermission();
          setState(() { 
            _exactAlarmGranted = granted ?? false;
          });
          print("Requested EXACT_ALARM permission. Granted: $_exactAlarmGranted");
        } catch (e) {
          print("Could not request EXACT_ALARM permission: $e");
        }
      }
    }
  }

  // Requests the system to ignore battery optimizations for this app
  Future<void> _requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied) {
      status = await Permission.ignoreBatteryOptimizations.request();
    }

    if (status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Battery optimization successfully ignored.')),
        );
      }
    } else if (status.isPermanentlyDenied || status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please manually set your app to "Unrestricted" in system settings.')),
        );
      }
      openAppSettings();
    }
  }

  // Function to check all pending notifications for debugging
  Future<void> _checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print('--- PENDING NOTIFICATIONS: ${pending.length} ---');
    if (pending.isEmpty) {
      print('No notifications are currently scheduled.');
    } else {
      for (var p in pending) {
        print('ID: ${p.id}, Title: ${p.title}, Payload: ${p.payload}');
      }
    }
    print('-----------------------------------------');
  }

  // Utility to produce a stable-ish unique id for each scheduled notification
  int _makeId(String medicineName, TimeOfDay time, [DateTime? day]) {
    final dayString = day != null ? DateFormat('yyyyMMdd').format(day) : "daily";
    final key = '${medicineName}_${time.hour}_${time.minute}_$dayString';
    return key.hashCode.abs() % 2000000000;
  }

  // Function to schedule a test alarm 30 seconds from now
  Future<void> _scheduleAlarmTestNotification() async {
    const int testId = 999999;
    
    // tz.local is now IST
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30)); 
    const String testMedicineName = 'Test Medicine'; 

    print('--- STARTING TEST ALARM SCHEDULE ---');
    print('Current IST Time: ${tz.TZDateTime.now(tz.local).toIso8601String()}');
    print('Scheduling TEST ALARM ID: $testId at ${scheduledDate.toIso8601String()}');
    
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test alarm scheduled for ${DateFormat('jms').format(scheduledDate)} IST')),
        );
    }

    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Alarm Test', 
      channelDescription: 'Temporary channel for testing alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      testId,
      'Medicine Reminder (TEST)', 
      'Time to take $testMedicineName', 
      scheduledDate,
      NotificationDetails(android: androidDetails),
      // Use exactAllowWhileIdle for reliable, precise timing
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('--- TEST ALARM SCHEDULED ---');

    _checkPendingNotifications();
  }

  /// Schedules a daily repeating notification.
  Future<void> _scheduleDailyRepeatingNotification(
      int id, String medicineName, TimeOfDay pickedTime, DateTime startDate) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local); // now is IST time

    // 1. Create a TZDateTime for the initial schedule time on the start date
    tz.TZDateTime first = tz.TZDateTime(
      tz.local, // IST
      startDate.year,
      startDate.month,
      startDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // CRITICAL FIX: Adjust to the next occurrence if the desired time has already passed NOW (in IST).
    if (first.isBefore(now)) {
      // If the time already passed today (relative to now), shift the base time to tomorrow.
      first = first.add(const Duration(days: 1));
      print('DEBUG: Time already passed in IST. Shifting daily schedule to tomorrow.');
    }

    print('Scheduling Daily ID: $id (for $medicineName) at ${first.toIso8601String()} (IST)');

    final androidDetails = AndroidNotificationDetails(
      'med_channel',
      'Medicine Reminders',
      channelDescription: 'Channel for medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Medicine Reminder',
      'Time to take $medicineName',
      first, // Use the calculated future time
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      matchDateTimeComponents: DateTimeComponents.time, // KEY: Makes it repeat daily at this time
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules notifications for a date range (one-off for each day).
  Future<void> _scheduleDateRangeNotifications(
      String medicineName, TimeOfDay pickedTime, DateTime startDate, DateTime endDate) async {
    final days = endDate.difference(startDate).inDays + 1;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local); // now is IST time

    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));

      // Construct the exact time for the day in IST timezone
      final tz.TZDateTime schedule = tz.TZDateTime(
        tz.local, // IST
        day.year,
        day.month,
        day.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // CRITICAL FIX: Only schedule if the time is strictly in the future (relative to IST).
      if (schedule.isBefore(now)) {
        print('DEBUG: Skipping past schedule for $medicineName on ${DateFormat('MMM d').format(day)} at ${pickedTime.format(context)} IST');
        continue;
      }

      final id = _makeId(medicineName, pickedTime, day);

      print('Scheduling DateRange ID: $id at ${schedule.toIso8601String()} (IST)');

      final androidDetails = AndroidNotificationDetails(
        'med_channel',
        'Medicine Reminders',
        channelDescription: 'Channel for medicine reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Medicine Reminder',
        'Time to take $medicineName',
        schedule,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        matchDateTimeComponents: null, // KEY: one-off notification 
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _cancelNotificationById(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Canceled notification ID: $id');
  }

  // High-level: schedules one or many notification ids and returns list of ids
  Future<List<int>> _scheduleForTimes({
    required String medicineName,
    required List<TimeOfDay> times,
    required RecurrenceType recurrence,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final List<int> ids = [];

    for (final t in times) {
      if (recurrence == RecurrenceType.daily) {
        final id = _makeId(medicineName, t);
        await _scheduleDailyRepeatingNotification(id, medicineName, t, startDate);
        ids.add(id);
      } else {
        if (endDate == null) continue; 
        
        await _scheduleDateRangeNotifications(medicineName, t, startDate, endDate);
        
        final days = endDate.difference(startDate).inDays + 1;
        for (int i = 0; i < days; i++) {
          final day = startDate.add(Duration(days: i));
          // We collect all potential IDs here.
          final id = _makeId(medicineName, t, day);
          ids.add(id);
        }
      }
    }

    _checkPendingNotifications();
    return ids;
  }
  
  
  Future<void> _addReminder() async {
    // Assuming dbHelper.getRoutines() returns a Future<List<Map<String, dynamic>>>
    final List<Map<String, dynamic>> medicines = await dbHelper.getRoutines();

    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add medicines in the 'My Medicines' screen first.")),
        );
      }
      return;
    }

    String? selectedMedicineName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Medicine"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final name = medicines[index]['medicineName'] ?? 'Unknown Medicine';
              return ListTile(
                title: Text(name),
                onTap: () {
                  selectedMedicineName = name;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );

    if (selectedMedicineName == null) return;

    RecurrenceType recurrenceType = RecurrenceType.daily;
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          title: Text('Schedule for $selectedMedicineName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Radio<RecurrenceType>(
                  value: RecurrenceType.daily,
                  groupValue: recurrenceType,
                  onChanged: (v) => setStateSB(() => recurrenceType = v!),
                ),
                title: const Text('Daily (no end date)'),
              ),
              ListTile(
                leading: Radio<RecurrenceType>(
                  value: RecurrenceType.dateRange,
                  groupValue: recurrenceType,
                  onChanged: (v) => setStateSB(() => recurrenceType = v!),
                ),
                title: const Text('Date Range (from - to)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Next')),
            ],
          ),
        );
      }),
    );

    if (proceed != true) return;

    List<TimeOfDay> times = [];
    bool done = false;
    while (!done) {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked == null) {
        if (times.isEmpty) return;
        break;
      }
      times.add(picked);

      final addMore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add another time?'),
          content: Text('Current times: ${times.map((t) => t.format(context)).join(', ')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No, Finish')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Add More')),
          ],
        ),
      );
      if (addMore != true) done = true;
    }
    
    // Set the start date to the beginning of today for correct scheduling logic
    DateTime todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    DateTime startDate = todayStart;
    DateTime? endDate;

    if (recurrenceType == RecurrenceType.dateRange) {
      final DateTimeRange? pickedRange = await showDateRangePicker(
        context: context,
        firstDate: todayStart,
        lastDate: DateTime(2100),
      );
      if (pickedRange == null) return;
      startDate = pickedRange.start; 
      endDate = pickedRange.end;
    }

    final List<int> scheduledIds = await _scheduleForTimes(
      medicineName: selectedMedicineName!,
      times: times,
      recurrence: recurrenceType,
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      _reminders.add({
        'name': selectedMedicineName!,
        'times': times,
        'recurrence': recurrenceType,
        'startDate': startDate,
        'endDate': endDate,
        'notificationIds': scheduledIds,
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder scheduled successfully.')),
      );
    }
  }

  Future<void> _editReminder(int index) async {
    final reminder = _reminders[index];
    final String name = reminder['name'];
    
    // 1. Cancel existing notifications
    final List<int> existingIds = List<int>.from(reminder['notificationIds']);
    for (final id in existingIds) {
      await _cancelNotificationById(id);
    }
    
    // Reuse existing data for flow
    RecurrenceType recurrenceType = reminder['recurrence'];
    List<TimeOfDay> times = List<TimeOfDay>.from(reminder['times']);
    DateTime startDate = reminder['startDate'];
    DateTime? endDate = reminder['endDate'];


    // 2. Recurrence dialog
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        return AlertDialog(
          title: Text('Edit schedule for $name'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Radio<RecurrenceType>(
                value: RecurrenceType.daily,
                groupValue: recurrenceType,
                onChanged: (v) => setStateSB(() => recurrenceType = v!),
              ),
              title: const Text('Daily (no end date)'),
            ),
            ListTile(
              leading: Radio<RecurrenceType>(
                value: RecurrenceType.dateRange,
                groupValue: recurrenceType,
                onChanged: (v) => setStateSB(() => recurrenceType = v!),
              ),
              title: const Text('Date Range (from - to)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Next')),
          ]),
        );
      }),
    );
    if (proceed != true) {
       // If canceled, we should ideally try to re-schedule the original notification.
       return; 
    }

    // 3. Edit times
    bool editing = true;
    while (editing) {
      final choice = await showDialog<String?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Edit Times'),
          children: [
            SimpleDialogOption(
              child: Text('Add a time (${times.length} set)'),
              onPressed: () => Navigator.pop(context, 'add'),
            ),
            SimpleDialogOption(
              child: Text('Change a time (Current: ${times.map((t) => t.format(context)).join(', ')})'),
              onPressed: () => Navigator.pop(context, 'change'), // NEW OPTION
            ),
            SimpleDialogOption(
              child: const Text('Remove a time'),
              onPressed: () => Navigator.pop(context, 'remove'),
            ),
            SimpleDialogOption(
              child: const Text('Done Editing'),
              onPressed: () => Navigator.pop(context, 'done'),
            ),
          ],
        ),
      );

      if (choice == 'add') {
        final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked != null) times.add(picked);
        
      } else if (choice == 'remove') {
        if (times.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No times to remove.')));
          continue;
        }
        final int? toRemove = await showDialog<int?>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select time to remove'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: times.length,
                itemBuilder: (context, i) {
                  final t = times[i];
                  return ListTile(
                    title: Text(t.format(context)),
                    onTap: () => Navigator.pop(context, i),
                  );
                },
              ),
            ),
          ),
        );
        if (toRemove != null) times.removeAt(toRemove);
        
      } else if (choice == 'change') { // LOGIC FOR CHANGING A TIME
        if (times.isEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No times to change.')));
            continue;
        }
        
        // Step 3a: Select which time to change (by index)
        final int? indexToChange = await showDialog<int?>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Select time to change'),
                content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: times.length,
                        itemBuilder: (context, i) => ListTile(
                            title: Text(times[i].format(context)),
                            onTap: () => Navigator.pop(context, i),
                        ),
                    ),
                ),
            ),
        );

        if (indexToChange != null) {
            // Step 3b: Pick the new time
            final TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: times[indexToChange], // Use the old time as the initial selection
            );

            if (newTime != null) {
                // Step 3c: Update the list
                times[indexToChange] = newTime;
                // Note: No need for setState here, as the outer setState after the while loop handles the UI update.
            }
        }
        
      } else {
        editing = false;
      }
    }
    
    if (times.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot save reminder: At least one time is required.')));
      return;
    }
    
    // 4. Edit Dates
    DateTime todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    if (recurrenceType == RecurrenceType.dateRange) {
      final DateTimeRange? pickedRange = await showDateRangePicker(
        context: context,
        firstDate: todayStart,
        lastDate: DateTime(2100),
        initialDateRange: endDate != null ? DateTimeRange(start: startDate, end: endDate) : DateTimeRange(start: startDate, end: startDate.add(const Duration(days: 7))),
      );
      if (pickedRange == null) return;
      startDate = pickedRange.start;
      endDate = pickedRange.end;
    } else {
      startDate = todayStart;
      endDate = null;
    }

    // 5. Schedule new notifications
    final List<int> scheduledIds = await _scheduleForTimes(
      medicineName: name,
      times: times,
      recurrence: recurrenceType,
      startDate: startDate,
      endDate: endDate,
    );

    // 6. Update local state
    setState(() {
      _reminders[index] = {
        'name': name,
        'times': times,
        'recurrence': recurrenceType,
        'startDate': startDate,
        'endDate': endDate,
        'notificationIds': scheduledIds,
      };
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder for $name updated')));
    }
  }

  Future<void> _deleteReminder(int index) async {
    final reminder = _reminders[index];
    final List<int> ids = List<int>.from(reminder['notificationIds']);
    for (final id in ids) await _cancelNotificationById(id);

    setState(() {
      _reminders.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
    }
    _checkPendingNotifications(); // Check state after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders (IST)'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add, color: Colors.yellowAccent), 
            tooltip: 'Schedule Test Alarm (30s, IST)',
            onPressed: _scheduleAlarmTestNotification,
          ),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradientColors,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 40,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              mainAxisSpacing: 50,
              crossAxisSpacing: 50,
            ),
            itemBuilder: (context, index) {
              final iconData = _backgroundIcons[index % _backgroundIcons.length];
              return Transform.rotate(
                angle: index % 2 == 0 ? 0.1 : -0.1,
                child: Icon(
                  iconData,
                  size: 80,
                  color: Colors.black.withOpacity(0.03),
                ),
              );
            },
          ),
        ),
        _reminders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No reminders yet.\nTap + to add one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    // Display status of Exact Alarm Permission
                    if (Platform.isAndroid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _exactAlarmGranted
                              ? '✅ Exact Alarm Permission Granted'
                              : '⚠️ Exact Alarm Permission Needed (Tap Fix Below)',
                          style: TextStyle(
                            color: _exactAlarmGranted ? Colors.green.shade700 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Button to request ignore battery optimization
                    ElevatedButton.icon(
                      onPressed: _requestIgnoreBatteryOptimization,
                      icon: const Icon(Icons.power_off, size: 20),
                      label: const Text('Fix Reminder Reliability (Important)', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade100,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    // Button to check status for debugging
                    TextButton.icon(
                      onPressed: _checkPendingNotifications,
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('Check Status (Debug)'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _reminders.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  final List<TimeOfDay> times = List<TimeOfDay>.from(reminder['times']);
                  final rec = reminder['recurrence'] as RecurrenceType;
                  final String timesText = times.map((t) => t.format(context)).join(', ');

                  String dateText;
                  if (rec == RecurrenceType.daily) {
                    dateText = 'Daily (Starts: ${DateFormat('MMM d, yyyy').format(reminder['startDate'])})';
                  } else {
                    dateText = 'From ${DateFormat('MMM d, yyyy').format(reminder['startDate'])} to ${DateFormat('MMM d, yyyy').format(reminder['endDate'])}';
                  }

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: const Icon(Icons.medication, color: Colors.blueAccent),
                      title: Text(reminder['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Times: $timesText (IST)', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(dateText, style: const TextStyle(color: Colors.black54)),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _editReminder(index)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteReminder(index)),
                      ]),
                    ),
                  );
                },
              )
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addBtn', 
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}