import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:screenshot/screenshot.dart';
// import 'package:gallery_saver/gallery_saver.dart';
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
import 'package:path_provider/path_provider.dart';

class SavedScreen extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();

  // Future<void> _captureAndSave() async {
  //   final image = await screenshotController.capture();
  //   if (image == null) return;
  //
  //   final directory = await getApplicationDocumentsDirectory();
  //   final imagePath = File('${directory.path}/saved_result.png');
  //   await imagePath.writeAsBytes(image);
  //
  //   await GallerySaver.saveImage(imagePath.path);
  //   print("Image saved to gallery");
  // }




  // Add to SavedScreen class
  final SettingsRepository _settingsRepo = SettingsRepository();

// Add these methods to SavedScreen class
  Future<void> _exportResult(ScannedResult result,BuildContext context) async {
    try {
      final image = await _generateBarcodeImage(result);
      if (image == null) return;

      final saveLocation = await _settingsRepo.getSaveLocation();
      Directory dir;

      if (saveLocation == 'internal') {
        dir = Directory(path.join(
            (await getExternalStorageDirectory())!.path,
            'BarQR Manager'
        ));
      } else {
        dir = await getApplicationDocumentsDirectory();
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

  Future<Uint8List?> _generateBarcodeImage(ScannedResult result) async {
    try {
      if (result.format == BarcodeFormat.qrCode) {
        final painter = QrPainter(
          data: result.data,
          version: QrVersions.auto,
          color: Colors.black,
          emptyColor: Colors.white,
        );
        final image = await painter.toImageData(300, format: ImageByteFormat.png);
        return image!.buffer.asUint8List();
      } else {
        final svg = bw.BarcodeWidget(
          barcode: _getBarcodeType(result.format),
          data: result.data,
          drawText: false,
        ).toSvg(width: 300, height: 150);
        final image = await svg.toPicture().toImage(300, 150);
        final byteData = await image.toByteData(format: ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }
    } catch (e) {
      print('Image generation error: $e');
      return null;
    }
  }

  bw.Barcode _getBarcodeType(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.code128: return bw.Barcode.code128();
      case BarcodeFormat.code39: return bw.Barcode.code39();
      default: return bw.Barcode.code128();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Results'),
        actions: [

        ],
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
                    contentPadding:
                    EdgeInsets.symmetric(vertical: AppSpacing.medium),
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
                        onPressed: () => _exportResult(result,context),
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
