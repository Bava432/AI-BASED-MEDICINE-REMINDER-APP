// lib/pages/medicine/medicine_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:medi_app/services/csv_loader_service.dart';

class MedicineCatalogScreen extends StatefulWidget {
  const MedicineCatalogScreen({super.key});

  @override
  State<MedicineCatalogScreen> createState() => _MedicineCatalogScreenState();
}

class _MedicineCatalogScreenState extends State<MedicineCatalogScreen> {
  // 1. STATE VARIABLES for Search
  late Future<List<Map<String, dynamic>>> _catalogFuture;
  List<Map<String, dynamic>> _fullCatalog = [];
  List<Map<String, dynamic>> _filteredCatalog = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
    // 2. Add listener to filter the list whenever the text changes
    _searchController.addListener(_filterMedicines);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMedicines);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCatalog() async {
    final List<Map<String, dynamic>> loadedCatalog = 
        await CsvLoaderService().loadMedicineCatalog();
    
    // Store the full catalog and initialize the filtered list
    _fullCatalog = loadedCatalog;
    _filteredCatalog = loadedCatalog;
    return loadedCatalog;
  }

  void _filterMedicines() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredCatalog = _fullCatalog;
      } else {
        _filteredCatalog = _fullCatalog.where((medicine) {
          // Check if the medicine name contains the query (case-insensitive)
          final name = (medicine['Medicine Name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  // --- Widget for the Search Bar ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search medicine by name...',
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterMedicines(); // Trigger filtering with empty query
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 💡 FIX: Replaced Colors.blueAccent.shade50 (which caused an error) 
    // with Colors.blue.shade50 for the lightest blue background shade.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Medicine Detail'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 3. Insert the Search Bar at the top
          _buildSearchBar(),

          // 4. Use FutureBuilder for initial loading only
          Expanded(
            child: Container(
              color: Colors.blue.shade50,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _catalogFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading catalog: ${snapshot.error}'));
                  }

                  // Use the filtered list for display
                  if (_filteredCatalog.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text(
                          'No medicines found matching your search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _filteredCatalog.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredCatalog[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: MedicineCatalogCard(
                          medicine: medicine,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MedicineCatalogCard Widget (Unchanged) ---

class MedicineCatalogCard extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineCatalogCard({
    super.key,
    required this.medicine,
  });

  Widget _buildDetailRow(String label, String value, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 16 : 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                color: isLarge ? Colors.black : Colors.grey[700],
              ),
              maxLines: isLarge ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = medicine['Medicine Name'] ?? 'N/A';
    final manufacturer = medicine['Manufacturer'] ?? 'N/A';
    final uses = medicine['Uses'] ?? 'No usage details provided.';
    final mrp = medicine['MRP'] ?? 'N/A';
    final sideEffects = medicine['Side Effects'] ?? 'Not listed.';
    final primaryColor = Theme.of(context).primaryColor;


    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                ),
                Text(
                  'Rs. $mrp',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),

            _buildDetailRow('Manufacturer', manufacturer),
            
            const Divider(height: 18),

            const Text(
              'Key Uses:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                uses,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Divider(height: 18),

            _buildDetailRow('Side Effects', sideEffects, isLarge: true),
            
            const SizedBox(height: 8),

            if (medicine['Chemical Class'] != null && medicine['Chemical Class']!.isNotEmpty)
              _buildDetailRow('Chemical Class', medicine['Chemical Class']!),

          ],
        ),
      ),
    );
  }
}