part of 'scanned_results_cubit.dart';

class ScannedResultsState extends Equatable {
  final List<ScannedResult> results;
  final bool autoFlashEnabled;

  const ScannedResultsState({
    required this.results,
    this.autoFlashEnabled = false,
  });

  ScannedResultsState copyWith({
    List<ScannedResult>? results,
    bool? autoFlashEnabled,
  }) {
    return ScannedResultsState(
      results: results ?? this.results,
      autoFlashEnabled: autoFlashEnabled ?? this.autoFlashEnabled,
    );
  }

  @override
  List<Object?> get props => [results, autoFlashEnabled];
}