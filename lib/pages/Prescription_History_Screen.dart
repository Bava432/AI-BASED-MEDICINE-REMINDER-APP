// You'll need to import 'dart:io' and 'package:flutter/material.dart'
import 'dart:io';
import 'package:flutter/material.dart';

class PrescriptionHistoryScreen extends StatelessWidget {
  final List<String> imagePaths;

  const PrescriptionHistoryScreen({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription History"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: imagePaths.isEmpty
          ? const Center(
              child: Text("No prescriptions found."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                final path = imagePaths[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: PrescriptionHistoryItem(
                    path: path,
                    index: index,
                  ),
                );
              },
            ),
    );
  }
}

class PrescriptionHistoryItem extends StatelessWidget {
  final String path;
  final int index;

  const PrescriptionHistoryItem({super.key, required this.path, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.file(
            File(path),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, size: 50, color: Colors.red);
            },
          ),
        ),
        title: Text(
          "Prescription #${index + 1}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Saved on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
        trailing: const Icon(Icons.search, color: Colors.blueAccent),
        onTap: () {
          // You can add logic here to view the full-size image
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Viewing full image #${index + 1}")),
          );
        },
      ),
    );
  }
}