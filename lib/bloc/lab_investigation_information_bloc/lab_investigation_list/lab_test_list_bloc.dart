import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medi_app/network/medicines_api.dart';

part 'lab_test_list_event.dart';
part 'lab_test_list_state.dart';

class MedicineListBloc extends Bloc<MedicineListEvent, MedicineListState> {
  final MedicineInformation medicineInformation;
  List<List<dynamic>> medicineData = [];
  List<List<dynamic>> filterMedicineData = [];

  MedicineListBloc(this.medicineInformation)
      : super(LoadingMedicineDataState()) {
    // 🔹 Handle GetMedicineData event
    on<GetMedicineData>((event, emit) async {
      emit(LoadingMedicineDataState());
      try {
        // Fetch data from the API or assets
        medicineData = await medicineInformation.getListOfMedicines();

        if (medicineData.isEmpty) {
          emit(ErrorState("No medicines found."));
          return;
        }

        // Print for debugging
        print("✅ Medicine Data Loaded: ${medicineData.length} items");
        print("Sample Entry: ${medicineData.first}");

        filterMedicineData = List.from(medicineData);
        emit(LoadedListState(filterMedicineData));
      } catch (e) {
        print("❌ Error loading medicines: $e");
        emit(ShowSnackBar("Error: $e"));
        emit(ErrorState("Failed to load medicines. Please try again."));
      }
    });

    // 🔹 Handle SearchTestData event
    on<SearchTestData>((event, emit) async {
      try {
        if (event.query.trim().isEmpty) {
          emit(LoadedListState(medicineData));
          return;
        }

        filterMedicineData = medicineData
            .where((element) =>
                element.isNotEmpty &&
                element[0]
                    .toString()
                    .toLowerCase()
                    .contains(event.query.toLowerCase()))
            .toList();

        if (filterMedicineData.isEmpty) {
          emit(ErrorState('No Result Found'));
        } else {
          emit(LoadedListState(filterMedicineData));
        }
      } catch (e) {
        print("❌ Search error: $e");
        emit(ErrorState('Something went wrong while searching.'));
      }
    });
  }
}

class MedicineInformation {
  Future<List<List<dynamic>>> getListOfMedicines() async {
    try {
      MedicineAPIClient medicineAPIClient = MedicineAPIClient();
      final data = await medicineAPIClient.fetchMedicinesFromAssets();

      if (data == null || data.isEmpty) {
        // FIX APPLIED HERE: Enclosing the entire string in quotes
        print("⚠️ No medicine data found from API client.");
        return [];
      }

      print("✅ Data fetched successfully: ${data.length} entries");
      return data;
    } catch (e) {
      print("❌ Failed to fetch medicine data: $e");
      return [];
    }
  }
}