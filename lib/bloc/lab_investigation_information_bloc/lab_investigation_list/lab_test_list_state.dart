part of 'lab_test_list_bloc.dart';

/// Base abstract class for all medicine list states
abstract class MedicineListState extends Equatable {
  const MedicineListState();

  @override
  List<Object> get props => [];
}

/// 🔹 State: Loading medicines (before data fetch completes)
class LoadingMedicineDataState extends MedicineListState {}

/// 🔹 State: Medicines successfully loaded
class LoadedListState extends MedicineListState {
  final List<List<dynamic>> medicineListData;

  const LoadedListState(this.medicineListData);

  @override
  List<Object> get props => [medicineListData];
}

/// 🔹 State: Error occurred while fetching or processing data
class ErrorState extends MedicineListState {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object> get props => [message];
}

/// 🔹 State: Show a snackbar message (optional UI feedback)
class ShowSnackBar extends MedicineListState {
  final String message;

  const ShowSnackBar(this.message);

  @override
  List<Object> get props => [message];
}
