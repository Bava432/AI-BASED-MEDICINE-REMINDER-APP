// lib/pages/medicine/medicine_information_screen.dart

import 'package:flutter/material.dart';
import 'package:medi_app/controllers/db_helper.dart';

class MedicineInformationScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;

  // Constructor now requires the full medicine map (which includes index/ID information if needed)
  const MedicineInformationScreen({super.key, required this.medicine});

  @override
  State<MedicineInformationScreen> createState() => _MedicineInformationScreenState();
}

class _MedicineInformationScreenState extends State<MedicineInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper dbHelper = DbHelper();
  
  // --- Background Definitions (Copied from MedicineListScreen) ---
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

  // Controllers initialized with existing data
  late TextEditingController _nameController;
  late TextEditingController _pillIDController;
  late TextEditingController _noteController;
  
  // NEW CONTROLLERS
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late bool _isCritical;

  bool _isSaving = false;
  
  // Assuming the original index is passed in the medicine map for editing
  late int _originalIndex; 

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current values, handling potential nulls
    _nameController = TextEditingController(text: widget.medicine['medicineName']?.toString() ?? '');
    _pillIDController = TextEditingController(text: widget.medicine['pillID']?.toString() ?? '');
    _noteController = TextEditingController(text: widget.medicine['note']?.toString() ?? '');
    
    // NEW FIELD INITIALIZATION
    _priceController = TextEditingController(text: widget.medicine['medicinePrice']?.toString() ?? '');
    _quantityController = TextEditingController(text: widget.medicine['quantity']?.toString() ?? '');
    _isCritical = widget.medicine['critical'] == true;

    // We must ensure the original index is available for the DB update
    _originalIndex = widget.medicine['originalIndex'] ?? -1; 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pillIDController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _updateMedicine() async {
    if (_formKey.currentState!.validate() && _originalIndex != -1) {
      setState(() {
        _isSaving = true;
      });

      try {
        final updatedData = {
          'pillID': _pillIDController.text.trim().isEmpty 
            ? DateTime.now().millisecondsSinceEpoch.toString() 
            : _pillIDController.text.trim(),
          'medicineName': _nameController.text.trim(),
          'medicinePrice': _priceController.text.trim(),
          'quantity': _quantityController.text.trim(),
          'note': _noteController.text.trim(),
          'critical': _isCritical,
        };

        // CRITICAL: Call the editRoutine function in DbHelper
        await dbHelper.editRoutine(_originalIndex, updatedData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine routine updated!')),
          );
          Navigator.pop(context, true); // Pop, indicating success/update
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating medicine: $e')),
          );
          setState(() => _isSaving = false);
        }
      }
    } else if (_originalIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Cannot find routine index for update.')),
        );
          setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medicine Routine'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      
      body: Stack(
        children: [
          // 1. Gradient Background Container (Light Blue/Cyan)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradientColors, // Light blue colors
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
                    color: Colors.black.withOpacity(0.06), // Subtle icon opacity
                  ),
                );
              },
            ),
          ),
          
          // 3. Foreground Content (The scrollable Form)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Medicine Name Field
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black), 
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      fillColor: Colors.white,
                      filled: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication, color: primaryColor),
                    ),
                    validator: (value) => value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 15),

                  // NEW FIELD: Quantity (Pills per Dosage)
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Quantity (Pills per Dosage)',
                      fillColor: Colors.white,
                      filled: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered, color: primaryColor),
                    ),
                    validator: (value) => value!.isEmpty ? 'Quantity is required' : null,
                  ),
                  const SizedBox(height: 15),

                  // NEW FIELD: Price
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Price (Rs.)',
                      fillColor: Colors.white,
                      filled: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Pill ID Field
                  TextFormField(
                    controller: _pillIDController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Pill ID / NDC (Optional)',
                      fillColor: Colors.white,
                      filled: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.barcode_reader, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Note/Description Field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Description / Special Instructions (Note)',
                      alignLabelWithHint: true,
                      fillColor: Colors.white,
                      filled: true,
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Critical Checkbox (Adjusted for light background)
                  CheckboxListTile(
                    title: const Text("Mark as Critical Medicine"), // Removed explicit white style
                    value: _isCritical,
                    onChanged: (val) {
                      setState(() {
                        _isCritical = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.red,
                  ),
                  const SizedBox(height: 30),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateMedicine,
                      icon: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Updating...' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
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