// medicine_detail_screen.dart

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:medi_app/constants/color_codes.dart';

import 'package:url_launcher/url_launcher.dart';

class MedicineInformationScreen extends StatelessWidget {
  List<dynamic> medicine;
  
  // NOTE: You are passing a List<dynamic> here, which is unconventional.
  // Accessing data by index (e.g., medicine[0]) is error-prone.
  MedicineInformationScreen(
    this.medicine,
  );
  
  // --- Helper to safely get data ---
  String _safeGet(int index, {String defaultValue = "No Data available"}) {
    return medicine.length > index ? medicine[index]?.toString() ?? defaultValue : defaultValue;
  }

  // --- Helper to build consistent detail rows ---
  Widget _buildDetailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorCode col = ColorCode();
    
    // --- Data mapping based on your indices ---
    final String medicineName = _safeGet(0);
    final String prescription = _safeGet(1);
    final String typeOfSell = _safeGet(2);
    // [3] and [4] are unused here
    final String mrp = _safeGet(5);
    final String uses = _safeGet(6);
    final String alternate = _safeGet(7);
    final String sideEffects = _safeGet(8);
    final String howToUse = _safeGet(9);
    // [10], [11], [12], [13] are unused here
    final String howItWorks = _safeGet(14);
    
    // ⚠️ Placeholder for Pill ID - ASSUMING INDEX 15. CHANGE THIS INDEX IF NEEDED!
    final String pillID = _safeGet(15, defaultValue: "Pill ID Not Found");


    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Infromation"),
        centerTitle: true,
        backgroundColor: col.bgColor,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      medicineName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.clip,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // 💡 NEW: DISPLAYING PILL ID PROMINENTLY
            _buildDetailRow("Pill ID / NDC", pillID),
            
            // Replaced the verbose old structure with the helper widget:
            _buildDetailRow("Uses", uses),
            _buildDetailRow("Type of Sell", typeOfSell),
            _buildDetailRow("Prescription", prescription),
            _buildDetailRow("M.R.P", mrp),
            _buildDetailRow("How to use ?", howToUse),
            _buildDetailRow("How it works ?", howItWorks),
            _buildDetailRow("Side Effects -:", sideEffects),
            _buildDetailRow("Alternate Medicines -:", alternate),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}