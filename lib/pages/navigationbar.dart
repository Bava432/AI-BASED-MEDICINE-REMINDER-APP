import 'package:flutter/material.dart';
import 'package:medi_app/pages/dashboard.dart';
import 'package:medi_app/pages/medicine_routine.dart';
import 'package:medi_app/pages/settings.dart';

class NavigationBarPage extends StatefulWidget {
  final String username;
  final List<dynamic>? medicines; // optional

  const NavigationBarPage({
    super.key,
    required this.username,
    this.medicines,
  });

  @override
  State<NavigationBarPage> createState() => _NavigationBarPageState();
}

class _NavigationBarPageState extends State<NavigationBarPage> {
  int _selectedIndex = 0;
  late List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      Dashboard(username: widget.username),
      MedicineRoutine(medicines: widget.medicines ?? []), // 🔥 FIXED
      const SettingsPage(),
    ];
  }

  void _refreshMedicineRoutine() {
    setState(() {
      screens[1] = MedicineRoutine(medicines: widget.medicines ?? []); // 🔥 FIXED
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) _refreshMedicineRoutine();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: "My Medicines"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
