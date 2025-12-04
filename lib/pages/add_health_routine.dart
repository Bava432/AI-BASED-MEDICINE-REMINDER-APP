import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:medi_app/constants/color_codes.dart';
import 'package:medi_app/controllers/db_helper.dart';

class AddRoutine extends StatefulWidget {
  const AddRoutine({Key? key}) : super(key: key);

  @override
  State<AddRoutine> createState() => _AddRoutineState();
}

class _AddRoutineState extends State<AddRoutine> {
  final DbHelper dbHelper = DbHelper();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isCritical = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: customAppBar(),
            ),
            medname(),
            priceQuantity(),
            mednote(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Critical Medicine?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isCritical,
                  onChanged: (val) {
                    setState(() {
                      isCritical = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String price = priceController.text.trim();
                String quantity = quantityController.text.trim();
                String note = noteController.text.trim();

                if (name.isEmpty || price.isEmpty || quantity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                await dbHelper.addData(
                  name,
                  price, // String ✅
                  quantity, // String ✅
                  note,
                  isCritical, // bool ✅
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Medicine added successfully!")),
                );

                // Clear fields
                nameController.clear();
                priceController.clear();
                quantityController.clear();
                noteController.clear();
                setState(() => isCritical = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorCode().bgColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              ),
              child: const Text(
                "Add Medicine",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔹 Custom app bar
  Widget customAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        const Text(
          "Add Medicine Routine",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 60,
          width: 60,
          child: Lottie.asset('assets/lottiefile/play.json'),
        ),
      ],
    );
  }

  // 🔹 Medicine name input
  Widget medname() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: "Medicine Name",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // 🔹 Price and quantity inputs
  Widget priceQuantity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price (Rs)",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Medicine note input
  Widget mednote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        controller: noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Special Instructions / Notes",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
