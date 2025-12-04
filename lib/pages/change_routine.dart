import 'package:flutter/material.dart';

class ChangeRoutinePage extends StatefulWidget {
  const ChangeRoutinePage({super.key});

  @override
  State<ChangeRoutinePage> createState() => _ChangeRoutinePageState();
}

class _ChangeRoutinePageState extends State<ChangeRoutinePage> {
  final TextEditingController _routineController = TextEditingController();
  final List<String> _routines = [];

  void _addRoutine() {
    if (_routineController.text.isNotEmpty) {
      setState(() {
        _routines.add(_routineController.text);
        _routineController.clear();
      });
    }
  }

  void _deleteRoutine(int index) {
    setState(() => _routines.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Routine"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _routineController,
              decoration: InputDecoration(
                labelText: "Enter New Routine",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: _addRoutine,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _routines.isEmpty
                  ? const Center(
                      child: Text(
                        "No routines added yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _routines.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(_routines[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRoutine(index),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
