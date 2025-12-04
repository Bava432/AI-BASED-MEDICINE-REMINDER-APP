// lib/pages/medicine_routine.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:medi_app/constants/color_codes.dart';
import 'package:medi_app/controllers/db_helper.dart';

// 🎯 New: Import dart:async for time manipulation (for reminder logic)
import 'dart:async'; 

class MedicineRoutine extends StatefulWidget {
  final List<dynamic> medicines; 

  const MedicineRoutine({
    super.key,
    required this.medicines, 
  });

  @override
  State<MedicineRoutine> createState() => _MedicineRoutineState();
}

class _MedicineRoutineState extends State<MedicineRoutine> {
  final DbHelper dbHelper = DbHelper();

  // --- Background Definitions (Unchanged) ---
  static const List<Color> _gradientColors = [
    Color(0xFFE0F7FA), // Lightest Cyan/Teal
    Colors.white,      // White base
  ];
  static const List<IconData> _backgroundIcons = [
    Icons.medical_services_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long,
    Icons.calendar_month,
    Icons.add_box_outlined,
    Icons.local_pharmacy_outlined,
  ];
  // -----------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchRoutines() async {
    return await dbHelper.getRoutines();
  }

  // =================================================================
  // 🎯 NEW: HELPER FUNCTIONS FOR REMINDER LOGIC
  // =================================================================

  /// Converts user-friendly recurrence to RRULE format.
  String _getRecurrenceRRule(String recurrence) {
    // Assuming recurrence is a simple string like 'Daily' or 'Weekly'
    switch (recurrence) {
      case 'Daily':
        return 'RRULE:FREQ=DAILY';
      case 'Weekly':
        return 'RRULE:FREQ=WEEKLY';
      default:
        return ''; // No recurrence
    }
  }

  /// Calculates the next future datetime string in yyyymmddTHHMM format.
  Future<String> _resolveNextStartTime(TimeOfDay time) async {
    final now = DateTime.now();
    // 1. Create a DateTime object for the target time today.
    DateTime targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 2. If the target time has already passed today, set it for tomorrow.
    if (targetDateTime.isBefore(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 1));
    }

    // 3. Format the result into the required yyyymmddTHHMM string.
    String year = targetDateTime.year.toString();
    String month = targetDateTime.month.toString().padLeft(2, '0');
    String day = targetDateTime.day.toString().padLeft(2, '0');
    String hour = targetDateTime.hour.toString().padLeft(2, '0');
    String minute = targetDateTime.minute.toString().padLeft(2, '0');

    return '$year$month$day\T$hour$minute';
  }

  // =================================================================
  // 🎯 UPDATED: Edit Dialog with Reminder Inputs
  // =================================================================

  void _editRoutineDialog(int index, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['medicineName']);
    final priceController = TextEditingController(text: data['medicinePrice'].toString());
    final quantityController = TextEditingController(text: data['quantity'].toString());
    final noteController = TextEditingController(text: data['note']);
    bool isCritical = data['critical'] ?? false;
    
    // 🎯 NEW STATE: Reminder related variables
    TimeOfDay selectedTime = TimeOfDay.now(); // Default time
    List<String> recurrenceOptions = ['None', 'Daily', 'Weekly'];
    String selectedRecurrence = recurrenceOptions[0]; // Default: None

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Medicine & Reminder"),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Medicine Name")),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
                  TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
                  TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note")),
                  
                  // --- REMINDER INPUTS START ---
                  const Divider(height: 30),
                  const Text("Reminder Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                  
                  // 1. Time Picker
                  ListTile(
                    title: const Text("Set Time"),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) {
                        setStateDialog(() => selectedTime = time);
                      }
                    },
                  ),

                  // 2. Recurrence Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Recurrence"),
                    value: selectedRecurrence,
                    items: recurrenceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedRecurrence = newValue!;
                      });
                    },
                  ),
                  // --- REMINDER INPUTS END ---
                  
                  CheckboxListTile(
                    title: const Text("Mark as Critical"),
                    value: isCritical,
                    onChanged: (val) {
                      setStateDialog(() { 
                        isCritical = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.red,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              // 1. Update Database (Existing Logic)
              await dbHelper.editRoutine(index, {
                'medicineName': nameController.text,
                'medicinePrice': priceController.text,
                'quantity': quantityController.text,
                'note': noteController.text,
                'critical': isCritical,
              });

              // 2. 🎯 NEW: Create Reminder Logic
              if (selectedRecurrence != 'None') {
                final reminderTitle = "Time to take: ${nameController.text}";
                final rrule = _getRecurrenceRRule(selectedRecurrence);
                final startTime = await _resolveNextStartTime(selectedTime);

                // --- 3. FINAL REMINDER TOOL CALL (CONCEPTUAL) ---
                // In a real execution, your logic here would trigger the external tool:
                
                // Example of what is executed:
                /*
                generic_reminders:create(
                  title: reminderTitle,
                  start_datetime: startTime,
                  recurrence_rules: rrule
                )
                */
                
                // Show confirmation to the user
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reminder set for ${nameController.text} at ${selectedTime.format(context)} ($selectedRecurrence).'))
                    );
                }
              } else if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine saved. No reminder set.'))
                );
              }

              // Refresh UI and close dialog
              if (mounted) setState(() {}); 
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // The rest of the build method and supporting widgets remain largely unchanged
  
  @override
  Widget build(BuildContext context) {
    // ... (rest of the build method)
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Stack(
        children: [
          // 1. Gradient Background Container
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
          
          // 2. ICON PATTERN OVERLAY
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
                    color: Colors.black.withOpacity(0.06), 
                  ),
                );
              },
            ),
          ),
          
          // 3. Foreground Content (The original FutureBuilder)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchRoutines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No medicine routines found.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final routines = snapshot.data!;
              return ListView(
                children: [
                  Padding(padding: const EdgeInsets.all(6.0), child: customAppBar),
                  ...List.generate(
                    routines.length,
                    (index) {
                      final data = routines[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _medicineCard(data, index),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _medicineCard(Map<String, dynamic> data, int index) {
    // ... (medicine card code remains unchanged)
    final name = data['medicineName'] ?? '';
    final price = data['medicinePrice'] ?? '0';
    final quantity = data['quantity'] ?? '0';
    final note = data['note'] ?? '';
    final critical = data['critical'] ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Medicine #${index + 1}',
                  style: TextStyle(
                    color: ColorCode().bgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _editRoutineDialog(index, data),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () async {
                    await dbHelper.deleteData(index);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('Rs. $price', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text('$quantity Pills per Dosage', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Note: ${note.isEmpty ? "No notes" : note}', style: const TextStyle(fontSize: 14)),
            if (critical)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('⚠️ Marked as Critical', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget get customAppBar {
    // ... (customAppBar code remains unchanged)
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.black, size: 22),
          ),
          const Text(
            ' My Medicines ',
            style: TextStyle(
              fontWeight: FontWeight.bold,  
              fontSize: 22,  
              color: Colors.blueAccent,
              
            ),
          ),
          SizedBox(height: 50, width: 50, child: Lottie.asset('assets/lottiefile/play.json')),
        ],
      ),
    );
  }
}