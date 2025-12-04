import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:medi_app/pages/swipe_deck%20cards/statcards.dart';
import 'package:swipe_deck/swipe_deck.dart';

class RoutineChange extends StatefulWidget {
  const RoutineChange({Key? key}) : super(key: key);

  @override
  State<RoutineChange> createState() => _RoutineChangeState();
}

class _RoutineChangeState extends State<RoutineChange> {
  List<int> id = [0, 1, 2, 3];

  List<Widget> card = [
    walkstats(),
    Container(
      alignment: Alignment.center,
      child: const Text(
        "Card 2 Placeholder",
        style: TextStyle(fontSize: 18, color: Colors.black54),
      ),
    ),
    Container(
      alignment: Alignment.center,
      child: const Text(
        "Card 3 Placeholder",
        style: TextStyle(fontSize: 18, color: Colors.black54),
      ),
    ),
    Container(
      alignment: Alignment.center,
      child: const Text(
        "Card 4 Placeholder",
        style: TextStyle(fontSize: 18, color: Colors.black54),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: customAppBar,
          ),
          const SizedBox(height: 20),
          deck(),
        ],
      ),
    );
  }

  Widget get customAppBar {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                FontAwesomeIcons.arrowLeft,
                color: Colors.black,
                size: 22,
              ),
            ),
            const Text(
              'Routine Plan Details',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 60,
              width: 80,
              child: Lottie.asset('assets/lottiefile/checklist.json'),
            ),
          ],
        ),
      ),
    );
  }

  Widget deck() {
    return SwipeDeck(
      aspectRatio: 1,
      startIndex: 0,
      emptyIndicator: const Center(
        child: Text(
          "Nothing Here",
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
      widgets: id
          .map(
            (e) => GestureDetector(
              onTap: () {
                print("Tapped card index: $e");
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 250,
                  child: card[e],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
