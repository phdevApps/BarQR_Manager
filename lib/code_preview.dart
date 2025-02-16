import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/code_types.dart';

Widget codePreview(BarcodeFormat format, String data,BuildContext context) {
  try {
    int i = commonTypes(
      formatName: format.name,
      objFormats: bw.BarcodeType.values.toList(),
    ).getFormatIndex();

    return bw.BarcodeWidget(
      data: data,
      barcode: bw.Barcode.fromType(bw.BarcodeType.values[i]),
      width: AppSpacing.previewWidth,
      height: AppSpacing.previewHeight,
      style: Theme.of(context).textTheme.titleMedium,
      textPadding: AppSpacing.medium,
    );
  } catch (e) {
    return Container();
  }
}