import 'package:hive/hive.dart';

class DbHelper {
  // Ensure the box is not initialized globally without checking if it's open
  late Box box;
  static final DbHelper _instance = DbHelper._internal();

  factory DbHelper() => _instance;

  DbHelper._internal();

  // ===================================================
  // 🔹 Open Hive Box
  // ===================================================
  Future<void> openBox() async {
    // Ensure we use the 'health' box.
    if (!Hive.isBoxOpen('health')) {
        box = await Hive.openBox('health');
    } else {
      // If already open (e.g., from main.dart), just reference it
        box = Hive.box('health');
    }
  }

  // ===================================================
  // 👤 USER MANAGEMENT (Existing methods kept)
  // ===================================================

  Future<void> addUser(
    String name,
    String age,
    String phone,
    String issue,
    String password,
  ) async {
    await openBox();

    final Map<String, dynamic> users = Map<String, dynamic>.from(
      box.get('users', defaultValue: <String, dynamic>{}),
    );

    users[name] = {
      'name': name,
      'age': age,
      'phone': phone,
      'issue': issue,
      'password': password,
    };

    await box.put('users', users);
  }

  // ... (Other existing user methods: updateUser, getUserByName, getName) ...
  // ... (These methods are assumed to be complete and correct) ...

  Future<void> updateUser(
    String name,
    String age,
    String phone,
    String issue,
    String password,
  ) async {
    await openBox();

    final Map<String, dynamic> users = Map<String, dynamic>.from(
      box.get('users', defaultValue: <String, dynamic>{}),
    );

    if (users.containsKey(name)) {
      users[name] = {
        'name': name,
        'age': age,
        'phone': phone,
        'issue': issue,
        'password': password,
      };
      await box.put('users', users);
    }
  }

  Future<List<Map<String, dynamic>>> getUserByName(String name) async {
    await openBox();
    final Map<String, dynamic> users = Map<String, dynamic>.from(
      box.get('users', defaultValue: <String, dynamic>{}),
    );

    if (users.containsKey(name)) {
      return [Map<String, dynamic>.from(users[name] as Map)];
    } else {
      return [];
    }
  }

  Future<String?> getName() async {
    await openBox();
    final Map<String, dynamic> users = Map<String, dynamic>.from(
      box.get('users', defaultValue: <String, dynamic>{}),
    );
    if (users.isNotEmpty) {
      // Assuming the first user's name is the current user's name
      return users.values.first['name'] as String?;
    }
    return null;
  }
  
  // ===================================================
  // 💊 MEDICINE / ROUTINE MANAGEMENT (CRITICAL)
  // ===================================================

  /// Adds a new medicine routine to the 'routines' list in the Hive box.
  Future<void> addData(
    String pillId,
    String medicineName,
    String medicinePrice,
    String quantity,
    String note,
    bool critical,
  ) async {
    await openBox();

    final List<dynamic> rawRoutines =
        box.get('routines', defaultValue: <dynamic>[]);

    final List<Map<String, dynamic>> routines = rawRoutines
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    routines.add({
      'pillID': pillId,
      'medicineName': medicineName,
      'medicinePrice': medicinePrice,
      'quantity': quantity,
      'note': note,
      'critical': critical,
    });

    await box.put('routines', routines);
  }

  /// 🎯 CRITICAL METHOD: Retrieves all medicine routines.
  /// Used by the ReminderPage to populate the list of medicines available for scheduling.
  Future<List<Map<String, dynamic>>> getRoutines() async {
    await openBox();

    final List<dynamic> rawRoutines =
        box.get('routines', defaultValue: <dynamic>[]);
    
    // Convert the dynamic list of maps stored in Hive back to a clean list of Map<String, dynamic>
    return rawRoutines
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Deletes a routine by its index in the 'routines' list.
  Future<void> deleteData(int index) async {
    await openBox();

    final List<dynamic> rawRoutines =
        box.get('routines', defaultValue: <dynamic>[]);

    // Hive lists/arrays must be modified via a copy and re-put
    final List<dynamic> routines = List.from(rawRoutines);

    if (index >= 0 && index < routines.length) {
      routines.removeAt(index);
      await box.put('routines', routines);
    }
  }

  /// Edits an existing routine at a specific index.
  Future<void> editRoutine(int index, Map<String, dynamic> updatedData) async {
    await openBox();

    final List<dynamic> rawRoutines =
        box.get('routines', defaultValue: <dynamic>[]);

    final List<dynamic> routines = List.from(rawRoutines);

    if (index >= 0 && index < routines.length) {
      // Ensure the map is fully correct before updating
      routines[index] = updatedData;
      await box.put('routines', routines);
    }
  }
}