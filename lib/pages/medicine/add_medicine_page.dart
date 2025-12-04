import 'package:flutter/material.dart';
import 'package:medi_app/controllers/db_helper.dart'; // Import DbHelper
import 'dart:math';

class AddMedicinePage extends StatefulWidget {
  final String username;

  const AddMedicinePage({super.key, required this.username});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper dbHelper = DbHelper();  

  // --- Background Definitions ---
  static const List<Color> _gradientColors = [
    Color(0xFFE3F2FD), 
    Color(0xFFBBDEFB), 
  ];
  static const List<IconData> _backgroundIcons = [
    Icons.medical_services_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long,
    Icons.calendar_month,
    Icons.add_box_outlined,
    Icons.local_pharmacy_outlined,
  ];
  // ------------------------------

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController(); 
  final _pillIDController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isCritical = false; 
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pillIDController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // --- HIVE SAVE FUNCTION ---
  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      String getCleanPrice() {
        final text = _priceController.text.trim();
        return text.isEmpty ? '0.0' : text; 
      }

      try {
        await dbHelper.addData(
          _pillIDController.text.trim().isEmpty 
            ? DateTime.now().millisecondsSinceEpoch.toString() 
            : _pillIDController.text.trim(),
          _nameController.text.trim(),
          getCleanPrice(), 
          _quantityController.text.trim(), 
          _descriptionController.text.trim(),
          _isCritical, 
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine saved successfully!')),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving medicine: $e')),
          );
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF42A5F5); 
    // Get media query data once
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Medicine'),
        backgroundColor: primaryColor, 
        foregroundColor: Colors.white,
        elevation: 0, 
      ),
      
      body: Stack(
        children: [
          // 1. Gradient Background Layer (Light Blue)
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
                final rotation = Random().nextDouble() * 0.2 - 0.1; 
                return Transform.rotate(
                  angle: rotation,
                  child: Icon(
                    iconData,
                    size: 80,
                    color: Colors.blue.withOpacity(0.12), 
                  ),
                );
              },
            ),
          ),
          
          // 3. Foreground Content Layer (The Scrollable Form)
          // The form content now stops short of the bottom button area.
          Positioned.fill(
            bottom: 80 + mediaQuery.padding.bottom, // Make space for the fixed bottom button (height approx 80)
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Fields (omitted for brevity, they are the same as before)
                    _buildCardTextFormField(
                      controller: _nameController,
                      labelText: 'Medicine Name',
                      icon: Icons.medication,
                      primaryColor: primaryColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the medicine name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildCardTextFormField(
                      controller: _quantityController,
                      labelText: 'Quantity (Pills per Dosage)',
                      icon: Icons.format_list_numbered,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null) {
                          return 'Please enter a valid number for quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildCardTextFormField(
                      controller: _priceController,
                      labelText: 'Price (Rs.)',
                      // Changed icon to match the screenshot more closely (rupee symbol)
                      icon: Icons.currency_rupee, 
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    _buildCardTextFormField(
                      controller: _pillIDController,
                      // The screenshot uses a different icon here. Let's use Icons.vpn_key or a key icon
                      icon: Icons.vpn_key,
                      labelText: 'Pill ID (Optional)',
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    
                    _buildCardTextFormField(
                      controller: _descriptionController,
                      labelText: 'Description / Special Instructions (Note)',
                      icon: Icons.description,
                      primaryColor: primaryColor,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    
                    // Critical Checkbox (Styled as a Card)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        title: const Text("Mark as Critical Medicine", style: TextStyle(fontSize: 16)),
                        value: _isCritical,
                        onChanged: (val) {
                          setState(() {
                            _isCritical = val ?? false;
                          });
                        },
                        // Fix for Checkbox design in screenshot: use unselected icon for better visual
                        checkColor: Colors.white,
                        activeColor: primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        tileColor: Colors.transparent, 
                      ),
                    ),
                    // Note: Removed the final SizedBox here to prevent unnecessary scroll padding

                  ],
                ),
              ),
            ),
          ),
          
          // 4. Fixed Bottom Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // The white curve at the bottom of the screenshot suggests a clipped container
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1), // Base color to define the area
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + mediaQuery.padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMedicine,
                  icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Medicine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    elevation: 5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),  
    );
  }

  // --- Extracted Widget for Card-Style Text Form Field ---
  Widget _buildCardTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none, 
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          prefixIcon: Icon(icon, color: primaryColor),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: validator,
      ),
    );
  }
}