part of 'lab_test_list_bloc.dart';

/// Base abstract class for all MedicineList events
abstract class MedicineListEvent extends Equatable {
  const MedicineListEvent();

  @override
  List<Object> get props => [];
}

/// 🔹 Event: Fetch all medicines from the API or local asset
class GetMedicineData extends MedicineListEvent {}

/// 🔹 Event: Search medicines by query string
class SearchTestData extends MedicineListEvent {
  final String query;

  const SearchTestData(this.query);

  @override
  List<Object> get props => [query];
}

/// 🔹 (Optional) — Event: Update a test to get more information
/// You can uncomment and use these later if needed.
/// Keeping them modernized for future expansion:

// class UpdateTestToGetInformation extends MedicineListEvent {
//   final int index;
//   const UpdateTestToGetInformation(this.index);
//
//   @override
//   List<Object> get props => [index];
// }

// class SelectedTheTestToGetInformation extends MedicineListEvent {
//   final dynamic labInformationScreenBloc;
//   final int index;
//
//   const SelectedTheTestToGetInformation(this.labInformationScreenBloc, this.index);
//
//   @override
//   List<Object> get props => [labInformationScreenBloc, index];
// }
