import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// scanned_result.dart
class ScannedResult extends Equatable {
  final int? id;
  final String title; // Add title field
  final String data;
  final BarcodeFormat format;
  final DateTime timestamp;

  ScannedResult({
    this.id,
    required this.title, // Add to constructor
    required this.data,
    required this.format,
    required this.timestamp,
  });

  // Update copyWith
  ScannedResult copyWith({
    int? id,
    String? title,
    String? data,
    BarcodeFormat? format,
    DateTime? timestamp,
  }) {
    return ScannedResult(
      id: id ?? this.id,
      title: title ?? this.title,
      data: data ?? this.data,
      format: format ?? this.format,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Update toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title, // Add title
      'data': data,
      'format': format.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScannedResult.fromMap(Map<String, dynamic> map) {
    try {
      return ScannedResult(
        id: map['id'],
        title: map['title'] ?? 'Untitled',
        data: map['data'],
        format: BarcodeFormat.values.firstWhere(
              (e) => e.name == map['format'],
          orElse: () => BarcodeFormat.qrCode,
        ),
        timestamp: DateTime.parse(map['timestamp']),
      );
    } catch (e) {
      print('Error parsing scanned result: $e');
      return ScannedResult(
        title: 'Invalid Entry',
        data: 'Corrupted data',
        format: BarcodeFormat.qrCode,
        timestamp: DateTime.now(),
      );
    }
  }
  @override
  List<Object?> get props => [id, title, data, format, timestamp];
}