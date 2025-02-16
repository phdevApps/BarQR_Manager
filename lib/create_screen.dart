import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/code_preview.dart';
import 'package:barqr_manager/database_helper.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:barqr_manager/scanned_results_cubit.dart';

class CreateScreen extends StatefulWidget {
  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  BarcodeFormat _selectedFormat = BarcodeFormat.qrCode;

  final Map<BarcodeFormat, RegExp> _formatValidators = {
    BarcodeFormat.ean13: RegExp(r'^\d{13}$'),
    BarcodeFormat.ean8: RegExp(r'^\d{8}$'),
    BarcodeFormat.code39: RegExp(r'^[A-Z0-9\-\.\ \$\/\+\%]+$'),
    BarcodeFormat.code93: RegExp(r'^[\x00-\x7F]+$'),
    BarcodeFormat.code128: RegExp(r'^[\x00-\x7F]+$'),
    BarcodeFormat.itf: RegExp(r'^\d+$'),
    BarcodeFormat.upcA: RegExp(r'^\d{12}$'),
    BarcodeFormat.upcE: RegExp(r'^\d{6,8}$'),
    BarcodeFormat.codabar: RegExp(r'^[A-D][0-9\-\$\:\.\/\+]+[A-D]$'),
    BarcodeFormat.pdf417: RegExp(r'.*'),
    BarcodeFormat.aztec: RegExp(r'.*'),
    BarcodeFormat.dataMatrix: RegExp(r'.*'),
    BarcodeFormat.qrCode: RegExp(r'.*'),
  };

  final Map<BarcodeFormat, String> _validationMessages = {
    BarcodeFormat.ean13: 'Must be exactly 13 digits',
    BarcodeFormat.ean8: 'Must be exactly 8 digits',
    BarcodeFormat.code39: 'Only A-Z, 0-9, and - . \$ / + %',
    BarcodeFormat.code93: 'ASCII characters only',
    BarcodeFormat.code128: 'ASCII characters only',
    BarcodeFormat.itf: 'Digits only with even count',
    BarcodeFormat.upcA: 'Must be 12 digits',
    BarcodeFormat.upcE: 'Must be 6-8 digits',
    BarcodeFormat.codabar: 'Must start/end with A-D and contain digits/symbols',
    BarcodeFormat.pdf417: '',
    BarcodeFormat.aztec: '',
    BarcodeFormat.dataMatrix: '',
    BarcodeFormat.qrCode: '',
  };

  final Map<BarcodeFormat, String> _formatInstructions = {
    BarcodeFormat.ean13: '• Must be exactly 13 numeric digits\n• Example: 5901234123457',
    BarcodeFormat.ean8: '• Must be exactly 8 numeric digits\n• Example: 96385074',
    BarcodeFormat.code39: '• Letters (A-Z), numbers (0-9), and symbols (- . \$ / + %)\n• Example: ABC-123',
    BarcodeFormat.code93: '• ASCII characters only\n• Example: SAMPLE93',
    BarcodeFormat.code128: '• ASCII characters (letters, numbers, symbols)\n• Example: {Code128_Example}',
    BarcodeFormat.itf: '• Even number of digits only\n• Example: 12345678',
    BarcodeFormat.upcA: '• Must be 12 numeric digits\n• Example: 012345678905',
    BarcodeFormat.upcE: '• Must be 6-8 numeric digits\n• Example: 01234565',
    BarcodeFormat.codabar: '• Start/end with A-D, digits/symbols in between\n• Example: A12345B',
    BarcodeFormat.pdf417: '• Can encode text, numbers, or binary data\n• Example: PDF417 Sample',
    BarcodeFormat.aztec: '• Supports text, URLs, or binary data\n• Example: https://example.com',
    BarcodeFormat.dataMatrix: '• Encodes text or binary data\n• Example: DataMatrix123',
    BarcodeFormat.qrCode: '• Supports text, URLs, or other data types\n• Example: https://flutter.dev',
  };

  String? _validateContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Content is required';
    }

    final validator = _formatValidators[_selectedFormat];
    final message = _validationMessages[_selectedFormat];

    if (_selectedFormat == BarcodeFormat.itf && value.length.isOdd) {
      return 'ITF requires even number of digits';
    }

    if (!validator!.hasMatch(value)) {
      return message!.isNotEmpty ? message : 'Invalid format';
    }

    return null;
  }

  Widget _buildPreview() {
    return Column(
      children: [
        SizedBox(height: AppSpacing.large),
        Text(
          'Preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: AppSpacing.small),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.small),
          ),
          padding: EdgeInsets.all(AppSpacing.medium),
          child: _contentController.text.isEmpty
              ? Text(
            'Enter content to see preview',
            style: Theme.of(context).textTheme.bodyMedium,
          )
              : SizedBox(
            width: 200,
            height: 200,
            child: FittedBox(
              child: codePreview(
                  _selectedFormat,
                  _contentController.text,context
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final newEntry = ScannedResult(
        title: _titleController.text,
        data: _contentController.text,
        format: _selectedFormat,
        timestamp: DateTime.now(),
      );

      final databaseHelper = DatabaseHelper.instance;
      final id = await databaseHelper.insertScannedResult(newEntry);
      final savedEntry = newEntry.copyWith(id: id);

      context.read<ScannedResultsCubit>().addResult(savedEntry);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entry saved successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );

      _clearForm();
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedFormat = BarcodeFormat.qrCode;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Entry'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.large),
              DropdownButtonFormField<BarcodeFormat>(
                value: _selectedFormat,
                decoration: InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.type_specimen),
                ),
                items: _formatValidators.keys
                    .map((format) => DropdownMenuItem(
                  value: format,
                  child: Text(
                    format.name[0].toUpperCase() +
                        format.name.substring(1),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _formKey.currentState?.validate();
                  });
                },
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: AppSpacing.large),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  prefixIcon: Icon(Icons.text_snippet),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                validator: _validateContent,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.medium),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.small),
                ),
                child: Text(
                  _formatInstructions[_selectedFormat]!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildPreview(),
              SizedBox(height: AppSpacing.large),
              ElevatedButton(
                onPressed: _saveEntry,
                child: Text(
                  'Save Entry',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}