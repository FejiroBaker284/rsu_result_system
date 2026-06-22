import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/result_service.dart';
import '../models/result_model.dart';

final resultServiceProvider = Provider<ResultService>((ref) => ResultService());

final allResultSheetsProvider = FutureProvider<List<ResultSheetModel>>((ref) async {
  return ref.watch(resultServiceProvider).getAllResultSheets();
});

final lecturerResultSheetsProvider =
    FutureProvider.family<List<ResultSheetModel>, String>((ref, lecturerId) async {
  return ref.watch(resultServiceProvider).getResultSheetsByLecturer(lecturerId);
});

final sheetResultsProvider =
    FutureProvider.family<List<StudentResultModel>, String>((ref, sheetId) async {
  return ref.watch(resultServiceProvider).getResultsBySheet(sheetId);
});

final studentResultsProvider =
    FutureProvider.family<List<StudentResultModel>, String>((ref, studentId) async {
  return ref.watch(resultServiceProvider).getStudentResults(studentId: studentId);
});

final studentGpaProvider =
    FutureProvider.family<List<SemesterGpaModel>, String>((ref, studentId) async {
  return ref.watch(resultServiceProvider).getStudentGpa(studentId);
});
