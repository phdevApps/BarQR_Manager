import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/scanned_results_cubit.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SavedScreen extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _captureAndSave() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = File('${directory.path}/saved_result.png');
    await imagePath.writeAsBytes(image);

    await GallerySaver.saveImage(imagePath.path);
    print("Image saved to gallery");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Results'),
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _captureAndSave,
          ),
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
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        if (result.id != null) {
                          context.read<ScannedResultsCubit>().deleteResult(result.id!);
                        }
                      },
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
