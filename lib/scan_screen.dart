import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/code_preview.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:barqr_manager/scanned_results_cubit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'database_helper.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],
  );
  bool _isDialogOpen = false;

  Future<void> _initializeFlash() async {
    await context.read<ScannedResultsCubit>().loadFlashState();
    final shouldEnable = context.read<ScannedResultsCubit>().state.autoFlashEnabled;
    if (shouldEnable && controller.torchState.value != TorchState.on) {
      controller.toggleTorch();
    }
  }

  void _handleTorchStateChange() {
    setState(() {});
  }

  Future<void> _updateFlashState(bool value) async {
    context.read<ScannedResultsCubit>().updateFlashState(value);
    if (value) {
      await controller.toggleTorch();
    } else {
      await controller.toggleTorch();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFlash();
    controller.torchState.addListener(_handleTorchStateChange);
    _requestCameraPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannedResultsCubit>().loadFlashState().then((_) {
        if (context.read<ScannedResultsCubit>().state.autoFlashEnabled) {
          Timer(Duration(milliseconds: 100), () => controller.toggleTorch());
        }
      });
    });
  }

  @override
  void dispose() {
    if (controller.torchState.value == TorchState.on) {
      controller.toggleTorch();
    }
    controller.stop();
    controller.torchState.removeListener(_handleTorchStateChange);
    controller.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  Future<void> _showResultPopup(
      String result, BarcodeFormat format, BuildContext context) async {
    final titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Scanned Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Enter Title',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSpacing.small),
                ),
              ),
              SizedBox(height: AppSpacing.medium),
              Container(
                width: AppSpacing.previewWidth,
                height: AppSpacing.previewHeight,
                child: FittedBox(child: codePreview(format, result, context)),
              ),
              SizedBox(height: AppSpacing.medium),
              Text(result, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                DateTime now = DateTime.now();
                ScannedResult scannedResult = ScannedResult(
                  title: titleController.text,
                  data: result,
                  format: format,
                  timestamp: now,
                );

                int id = await DatabaseHelper.instance
                    .insertScannedResult(scannedResult);
                scannedResult = scannedResult.copyWith(id: id);
                context.read<ScannedResultsCubit>().addResult(scannedResult);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        actions: [
          BlocBuilder<ScannedResultsCubit, ScannedResultsState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.autoFlashEnabled ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _updateFlashState(!state.autoFlashEnabled),
              );
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture barcode) async {
          if (_isDialogOpen) return;

          final barcodeData = barcode.barcodes.first.rawValue;
          final barcodeFormat = barcode.barcodes.first.format;
          final prefs = await SharedPreferences.getInstance();
          final vibrate = prefs.getBool('vibrate_feedback') ?? false;

          if (barcodeData != null) {
            _isDialogOpen = true;
            controller.stop();

            await _showResultPopup(barcodeData, barcodeFormat, context);

            controller.start();
            _isDialogOpen = false;
          }

          if (vibrate && (await Vibration.hasVibrator() ?? false)) {
            Vibration.vibrate(duration: 200);
          }
        },
      ),
    );
  }
}