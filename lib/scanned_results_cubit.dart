// scanned_results_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:barqr_manager/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'scanned_results_state.dart';

class ScannedResultsCubit extends Cubit<ScannedResultsState> {
  ScannedResultsCubit() : super(const ScannedResultsState(results: [])) {
    fetchResults();
    loadFlashState();
  }
  Future<void> loadFlashState() async {
    final prefs = await SharedPreferences.getInstance();
    final flashState = prefs.getBool('auto_flash') ?? false;
    emit(state.copyWith(autoFlashEnabled: flashState));
  }


  Future<void> updateFlashState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_flash', value);
    emit(state.copyWith(autoFlashEnabled: value));
  }

  Future<void> fetchResults() async {
    List<ScannedResult> results = await DatabaseHelper.instance.getScannedResults();
    emit(ScannedResultsState(results: results));
  }

  Future<void> addResult(ScannedResult result) async {
    await DatabaseHelper.instance.insertScannedResult(result);
    List<ScannedResult> currentResults = state.results;
    List<ScannedResult> newResults = List.from(currentResults)..add(result);
    emit(ScannedResultsState(results: newResults));
  }

  Future<void> deleteResult(int id) async {
    await DatabaseHelper.instance.deleteScannedResult(id);
    List<ScannedResult> currentResults = state.results;
    List<ScannedResult> newResults = currentResults.where((result) => result.id != id).toList();
    emit(ScannedResultsState(results: newResults));
  }

  Future<void> deleteAllResults() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('scanned_results');
    emit(const ScannedResultsState(results: []));
  }
}