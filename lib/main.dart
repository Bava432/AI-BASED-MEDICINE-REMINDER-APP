import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz; // 🚀 NEW: Timezone data import
import 'package:timezone/timezone.dart' as tz; // 🚀 NEW: Timezone import

// Import the dispatcher function from the new background file
import 'background_tasks.dart'; 

// Pages
import 'package:medi_app/pages/dashboard.dart';
import 'package:medi_app/pages/navigationbar.dart';
import 'package:medi_app/pages/welcome_screen.dart';
import 'package:medi_app/pages/medicine/medicine_list.dart';
import 'package:medi_app/pages/medicine/add_medicine_page.dart';
import 'package:medi_app/pages/routine_list.dart';
import 'package:medi_app/pages/health_tips.dart';
import 'package:medi_app/pages/reminder.dart';
import 'package:medi_app/pages/rxcheck_page.dart';
import 'package:medi_app/pages/routine_change.dart';

// 💡 Timezone initialization function (copied from reminder.dart)
void initializeTimeZones() {
  tz.initializeTimeZones();
  try {
    // Attempt to set local location using the device's default timezone
    final String localTimezone = tz.local.name;
    tz.setLocalLocation(tz.getLocation(localTimezone));
    print("Timezone initialized to: ${tz.local.name}");
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    print("Timezone error: Falling back to UTC. $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Workmanager before running the app
  await Workmanager().initialize( // Changed to await to ensure completion
    callbackDispatcher, // The entry point defined in background_tasks.dart
    isInDebugMode: true, // Set to false for production
  );
  
  // 2. Initialize Timezones (Crucial for scheduled notifications)
  initializeTimeZones();
  
  // 3. Initialize Hive
  await Hive.initFlutter();

  // 🔥 Open Hive boxes before runApp
  await Hive.openBox('medicineBox'); // store medicines
  await Hive.openBox('health'); // another box you use

  runApp(const MediApp());
}

class MediApp extends StatelessWidget {
  const MediApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medi App',
      theme: ThemeData(
        fontFamily: 'Lato',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),

        // ❗ Do NOT send empty medicines list here — causes UI not to update later
        '/dashboard': (context) => const Dashboard(username: "User"),
        '/home': (context) => NavigationBarPage(username: "User"),

        // Medicine Pages
        '/medicineList': (context) => MedicineListScreen(username: "User"),
        '/addMedicine': (context) => AddMedicinePage(username: "User"),

        // Routine list should read Hive — not receive from outside
        '/routineList': (context) => RoutineList(),

        '/healthTracker': (context) => const HealthTipsPage(),
        '/reminder': (context) => const ReminderPage(),
        '/rxCheck': (context) => const RxCheckPage(),
        '/routineChange': (context) => const RoutineChange(),
      },
    );
  }
}