import 'package:flutter/material.dart';
// import 'package:medi_app/constants/color_codes.dart'; // Keeping the original import
// import 'package:medi_app/controllers/db_helper.dart'; // Keeping the original import
import 'medicine_information_screen.dart'; 

// 🚨 Mocking missing dependencies for a runnable example
class ColorCode {
  final Color bgColor = const Color(0xFF004D40); // Dark Teal/Green for accents
}
class DbHelper {
  Future<List<Map<String, dynamic>>> getRoutines() async {
    // Mock routine list
    return []; 
  }
  Future<void> deleteData(int index) async {}
}
// ----------------------------------------------------

class MedicineListScreen extends StatefulWidget {
  final String username;

  const MedicineListScreen({super.key, required this.username});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  // --- Background Definitions (Light Theme) ---
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
  // --------------------------------------------------

  final DbHelper db = DbHelper();
  final ColorCode col = ColorCode();
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> allMedicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  bool isSearching = false;
  String? selectedPillId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    if (!mounted) return;

    final list = await db.getRoutines();
    setState(() {
      allMedicines = list;
      _searchMedicine(_controller.text);
    });
  }

  void _searchMedicine(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredMedicines = allMedicines.where((med) {
        final medicineName = med['medicineName']?.toString().toLowerCase() ?? '';
        return medicineName.contains(q);
      }).toList();

      if (selectedPillId != null &&
          !filteredMedicines.any((med) => med['pillID'].toString() == selectedPillId)) {
        selectedPillId = null;
      }
    });
  }
  
  List<DropdownMenuItem<String>> getPillIdDropdownItems() {
    return const [
      DropdownMenuItem(value: null, child: Text('All Pills')),
      DropdownMenuItem(value: '1', child: Text('Pill ID 1')),
    ];
  }
  
  void _filterByPillId(String? newValue) {
    setState(() {
      selectedPillId = newValue;
      _searchMedicine(_controller.text);
    });
  }
  
  Future<void> _deleteRoutine(int index) async {
    await db.deleteData(index);
    _loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medicines"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _controller.clear();
                  _searchMedicine('');
                }
              });
            },
          )
        ],
        bottom: isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    onChanged: _searchMedicine,
                    decoration: InputDecoration(
                      hintText: "Search medicine by name...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      fillColor: Colors.white.withOpacity(0.2),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.medical_services, color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
      
      // Floating Action Button (FAB) for adding medicine
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pass an empty map to signal the MedicineInformationScreen to create a new entry
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicineInformationScreen(medicine: const {}), 
            ),
          );
          _loadMedicines(); // Reload list after returning
        },
        backgroundColor: Colors.blueAccent, // Set to blue color
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
      
      body: Stack(
        children: [
          // 1. Gradient Background Container (Light)
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
          
          // 3. Foreground Content (Original Column)
          Column(
            children: [
              // Pill ID Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: selectedPillId,
                  decoration: InputDecoration(
                    labelText: 'Filter by Pill ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.white, 
                    filled: true,
                  ),
                  items: getPillIdDropdownItems(),
                  onChanged: _filterByPillId,
                ),
              ),
              
              // Medicine List
              Expanded(
                child: filteredMedicines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Text(
                            allMedicines.isEmpty 
                                ? "No medicine routines found."
                                : "No medicines match your current search/filter.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500), 
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredMedicines.length,
                        itemBuilder: (context, index) {
                          final med = filteredMedicines[index];
                          final originalIndex = allMedicines.indexOf(med);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: MedicineListCard(
                              medicine: med,
                              index: index,
                              originalIndex: originalIndex,
                              col: col,
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicineInformationScreen(medicine: med),
                                  ),
                                );
                                _loadMedicines(); // Reload list after returning
                              },
                              onDelete: () => _deleteRoutine(originalIndex), // Use the original index
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Card Widget
class MedicineListCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final int index;
  final int originalIndex;
  final ColorCode col;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineListCard({
    super.key,
    required this.medicine,
    required this.index,
    required this.originalIndex,
    required this.col,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Safely extract data
    final name = medicine['medicineName']?.toString() ?? 'N/A';
    final quantity = medicine['quantity']?.toString() ?? '0';
    final price = medicine['medicinePrice']?.toString() ?? '0';
    final note = medicine['note']?.toString() ?? 'No special instructions.';
    final critical = medicine['critical'] == true;
    final primaryColor = Theme.of(context).primaryColor; // Get the app's primary color

    return Card(
      elevation: 4,
      color: Colors.white,  
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      // 💡 CHANGE 2: Use Stack to layer the content over the background icon
      child: Stack(
        children: [
          // 1. Background Icon Layer (Subtle, large icon)
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              Icons.local_hospital_outlined, // Icon for visual background
              size: 100,
              color: primaryColor.withOpacity(0.08), // Light blue, highly transparent
            ),
          ),
          
          // 2. Content Layer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title, Edit, and Delete Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 💡 CHANGE 1: Display as "Medicine 1"
                    Text(
                      'Medicine ${index + 1}', // Changed from 'Medicine Number ${index + 1}'
                      style: TextStyle(
                        color: col.bgColor, // Dark Teal accent color
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100, // Light blue edit button background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 14, color: Colors.blue)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                
                // Row 2: Medicine Name and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Rs. $price',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Row 3: Quantity
                Text(
                  '$quantity Pills per Dosage',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                
                const SizedBox(height: 5),

                // Row 4: Special Instructions / Note Label
                const Text(
                  'Special Instructions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                ),

                // Row 5: Note Content
                Text(
                  note,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Critical Warning
                if (critical)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ CRITICAL MEDICINE',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}