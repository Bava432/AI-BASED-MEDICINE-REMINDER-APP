import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medi_app/bloc/lab_investigation_information_bloc/lab_investigation_list/lab_test_list_bloc.dart';
import 'medicine_detail_screen.dart';

class Body extends StatefulWidget {
  final MedicineListBloc medicineListBloc;

  const Body(this.medicineListBloc, {super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  void initState() {
    super.initState();
    // 🔹 Fetch medicine data when the screen loads
    widget.medicineListBloc.add(GetMedicineData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MedicineListBloc, MedicineListState>(
      bloc: widget.medicineListBloc,
      listener: (context, state) {
        if (state is ShowSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<MedicineListBloc, MedicineListState>(
        bloc: widget.medicineListBloc,
        builder: (context, state) {
          if (state is LoadingMedicineDataState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LoadedListState) {
            // ✅ Updated variable name
            return showList(state.medicineListData);
          } else if (state is ErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.message,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// 🔹 Widget to display the list of medicines
Widget showList(List<List<dynamic>> medicineList) {
  return Scrollbar(
    child: ListView.builder(
      itemCount: medicineList.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[50]),
            child: ListTile(
              title: Text(
                medicineList[index][0],
                maxLines: null,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineInformationScreen(
                        medicineList.elementAt(index),
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Get Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
