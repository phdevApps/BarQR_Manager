import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/scanned_results_cubit.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:barqr_manager/settings_repository.dart';
import 'package:path/path.dart' as path;

class SavedScreen extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();
  final SettingsRepository _settingsRepo = SettingsRepository();
  // print('=========>clicked');
  // print('=========>clicked');
  // print('=========>clicked');
  // print('=========>clicked');


  Future<Uint8List?> _generateBarcodeImage(BuildContext context, ScannedResult result) async {
    try {
      // Use ScreenshotController's captureFromWidget method.
      // You can adjust the delay and pixelRatio as needed.
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        Material(
          child: bw.BarcodeWidget(
            barcode: _getBarcodeType(result.format),
            data: result.data,
            width: 300,
            height: 150,
            drawText: false,
          ),
        ),
        pixelRatio: 3.0,
        delay: Duration(milliseconds: 200),
      );
      return imageBytes;
    } catch (e) {
      print("Error generating barcode image: $e");
      return null;
    }
  }

  Future<bool> requestManageExternalStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> _exportResult(BuildContext context, ScannedResult result) async {
    try {
      // Request all-files permission.
      if (!await requestManageExternalStoragePermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manage storage permission not granted')),
        );
        return;
      }

      // Ask the user whether to use default or custom path.
      final bool? useDefaultPath = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Select Save Location"),
            content: Text("Save using the default location or choose a custom path?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Default Path"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Select Manually"),
              ),
            ],
          );
        },
      );
      if (useDefaultPath == null) return; // User canceled

      // Generate barcode (or QR code) image.
      final image = await _generateBarcodeImage(context, result);
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate image')),
        );
        return;
      }

      Directory dir=Directory('/storage/emulated/0/BarQR Manager');
      if (useDefaultPath) {
        Directory dir = Directory('/storage/emulated/0/BarQR Manager');
        if (!await dir.exists()) await dir.create(recursive: true);
      } else {
        // Use a file picker to select a directory (e.g. via file_selector package).
        final String? selectedDir = await getDirectoryPath(); // Ensure you import and configure file_selector
        if (selectedDir == null) return;
        dir = Directory(selectedDir);
      }

      if (!await dir.exists()) await dir.create(recursive: true);

      final filename = '${result.title}_${result.timestamp.millisecondsSinceEpoch}.png';
      final file = File(path.join(dir.path, filename));
      await file.writeAsBytes(image);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${dir.path}')),
      );
    } catch (e) {
      print('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }




// Capture widget as an image
  Future<Uint8List?> _captureWidgetAsImage(GlobalKey repaintBoundaryKey) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget as image: $e');
      return null;
    }
  }

  bw.Barcode _getBarcodeType(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128:
        return bw.Barcode.code128();
      case BarcodeFormat.code39:
        return bw.Barcode.code39();
      case BarcodeFormat.qrCode:
        return bw.Barcode.qrCode(); // Added for QR codes
      default:
        return bw.Barcode.qrCode(); // Default to QR if unknown
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Results'),
      ),
      body: BlocBuilder<ScannedResultsCubit, ScannedResultsState>(
        builder: (context, state) {
          if (state.results.isEmpty) {
            return Center(child: Text('No results saved yet.'));
          } else {
            return Screenshot(
              controller: screenshotController,
              child: ListView.builder(
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  ScannedResult result = state.results[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                    title: Text(result.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${_formatTypeName(result.format.name)}'),
                        Text('Date: ${DateFormat('dd/MM/yyyy').format(result.timestamp)}'),
                        Text('Time: ${DateFormat('hh:mm a').format(result.timestamp)}'),
                        SizedBox(height: 8),
                        Text('Content: ${result.data}'),
                      ],
                    ),
                    leading: Container(
                      width: 100,
                      child: FittedBox(
                        child: QrImageView(
                          data: result.data,
                          version: QrVersions.auto,
                          size: 100,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () => _exportResult(context, result),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            if (result.id != null) {
                              context.read<ScannedResultsCubit>().deleteResult(result.id!);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

String _formatTypeName(String type) {
  return type[0].toUpperCase() + type.substring(1);
}
