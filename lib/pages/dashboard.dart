import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medi_app/constants/color_codes.dart';
// 💡 IMPORTANT: Ensure this file exists at this path!
import 'package:medi_app/pages/medicine/medicine_catalog_screen.dart';

class Dashboard extends StatefulWidget {
  final String username;
  final List<dynamic>? medicines;

  const Dashboard({
    super.key,
    required this.username,
    this.medicines,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // ColorCode col = ColorCode(); // Assuming this is defined elsewhere

  Widget _buildFrostedCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 100,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(width: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/icons/favicon(2).png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 🎯 REVERTED: Now uses the actual username passed to the widget.
                    "Hello, ${widget.username} 👋",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Manage your health smartly",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildFrostedCard(
                            title: "Basic Medicine Detail",
                            icon: Icons.list_alt_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MedicineCatalogScreen(),
                              ),
                            ),
                          ),
                          _buildFrostedCard(
                            title: "Add Medicine",
                            icon: Icons.add_circle_outline,
                            onTap: () =>
                                Navigator.pushNamed(context, '/addMedicine'),
                          ),
                          _buildFrostedCard(
                            title: "AI-Health Chatbot",
                            icon: Icons.monitor_heart,
                            onTap: () =>
                                Navigator.pushNamed(context, '/healthTracker'),
                          ),
                          _buildFrostedCard(
                            title: "Reminders",
                            icon: Icons.notifications_active_outlined,
                            onTap: () =>
                                Navigator.pushNamed(context, '/reminder'),
                          ),
                                                  ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}