import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:medi_app/controllers/db_helper.dart';
import 'navigationbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _loginNameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureLoginPassword = true;

  // --- Background Definitions (Purple/Pink/Orange Theme) ---
  static const List<Color> _gradientColors = [
    Color(0xFFFFECB3), // Lightest Yellow/Cream
    Color(0xFFF3E5F5), // Lightest Purple/Pink
  ];
  static const List<IconData> _backgroundIcons = [
    Icons.lock_open_rounded,
    Icons.person_add_alt_1_rounded,
    Icons.key_rounded,
    Icons.how_to_reg_rounded,
    Icons.verified_user_rounded,
    Icons.login_rounded,
  ];
  // ------------------------------------------------

  Widget _buildTextField({
    required String labelText,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: Colors.deepOrangeAccent.shade200,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(fontSize: 18),
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.deepOrangeAccent.shade200),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final phone = _phoneController.text.trim();
    final issue = _issueController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || age.isEmpty || phone.isEmpty || issue.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please fill in all fields.')),
      );
      return;
    }

    final dbHelper = DbHelper();
    final existingUsers = await dbHelper.getUserByName(name);
    if (existingUsers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orangeAccent, content: Text('User already registered! Please login.')),
      );
      return;
    }

    await dbHelper.addUser(name, age, phone, issue, password);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.green, content: Text('Registration successful! Please login.')),
    );

    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _issueController.clear();
    _passwordController.clear();
  }

  Future<void> _login() async {
    final name = _loginNameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter name and password.')),
      );
      return;
    }

    final dbHelper = DbHelper();
    final users = await dbHelper.getUserByName(name);

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('User not found. Please register.')),
      );
      return;
    }

    final user = users.first;
    if (user['password'] == password) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          // 🎯 FIX: Added the required 'medicines' parameter here
          builder: (context) => NavigationBarPage(
            username: user['name'],
            medicines: const [], // Initializing with an empty list
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Incorrect password!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.purpleAccent.shade700,
          title: const Text('User Portal', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Already Registered", icon: Icon(Icons.login_rounded)),
              Tab(text: "New Register", icon: Icon(Icons.person_add_alt_1_rounded)),
            ],
          ),
        ),
        body: Stack( // 🔑 Start of the Stack to layer background and content
          children: [
            // 1. Gradient Background Container
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _gradientColors, // Light Yellow to Light Purple/Pink
                  ),
                ),
              ),
            ),
            
            // 2. ICON PATTERN OVERLAY
            Positioned.fill(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // Makes background non-scrollable
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
                      color: Colors.black.withOpacity(0.02), // Very subtle overlay
                    ),
                  );
                },
              ),
            ),

            // 3. TabBarView (The main content, layered on top)
            TabBarView(
              children: [
                // LOGIN TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(height: 250, child: Lottie.asset('assets/lottiefile/login_hello.json')),
                      _buildTextField(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        controller: _loginNameController,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        controller: _loginPasswordController,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureLoginPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.deepOrangeAccent.shade200,
                          ),
                          onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.shade700,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _login,
                        child: const Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                // REGISTER TAB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(height: 250, child: Lottie.asset('assets/lottiefile/login_hello.json')),
                      _buildTextField(labelText: 'Name', hintText: 'Enter your name', controller: _nameController, icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      _buildTextField(labelText: 'Age', hintText: 'Enter your age', controller: _ageController, icon: Icons.calendar_today_rounded, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(labelText: 'Phone', hintText: 'Enter your phone number', controller: _phoneController, icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildTextField(labelText: 'Medical Issue', hintText: 'e.g., Diabetes, Asthma', controller: _issueController, icon: Icons.medical_services_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(labelText: 'Password', hintText: 'Enter password', controller: _passwordController, icon: Icons.lock_outline_rounded, obscureText: _obscurePassword, suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.deepOrangeAccent.shade200),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.shade700,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _register,
                        child: const Text('Register', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ), // 🔑 End of TabBarView
          ],
        ), // 🔑 End of Stack
      ),
    );
  }
}