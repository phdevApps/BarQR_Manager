import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeFormatUtils {
  static String toExportString(BarcodeFormat format) {
    return format.name.toLowerCase().trim();
  }

  static BarcodeFormat fromImportString(String input) {
    final cleaned = input
        .trim()
        .replaceAll('"', '')
        .toLowerCase();

    return BarcodeFormat.values.firstWhere(
          (f) => toExportString(f) == cleaned,
      orElse: () => BarcodeFormat.qrCode,
    );
  }
}
