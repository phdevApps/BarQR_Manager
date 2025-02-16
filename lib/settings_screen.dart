import 'dart:convert';
import 'dart:typed_data';
import 'package:barqr_manager/settings_repository.dart';
import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barqr_manager/barcode_format_utils.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'database_helper.dart';
import 'scanned_results_cubit.dart';
import 'theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.medium),
        children: [
          _ScanningSection(),
          SizedBox(height: AppSpacing.large),
          _AppearanceSection(),
          SizedBox(height: AppSpacing.large),
          _DataSection(),
          SizedBox(height: AppSpacing.large),
          _PermissionsSection(),
          SizedBox(height: AppSpacing.large),
          _AboutSection(),
          // TODO the export tile refactore later
          SizedBox(height: AppSpacing.large),
          ListTile(
            leading: Icon(Icons.folder, color: AppColors.info),
            title: Text('Save Location'),
            subtitle: FutureBuilder<String>(
              future: SettingsRepository().getSaveLocation(),
              builder: (context, snapshot) {
                return Text(snapshot.data == 'internal'
                    ? 'Internal Storage/BarQR Manager'
                    : 'App Documents');
              },
            ),
            trailing: DropdownButton<String>(
              value: 'internal',
              items: [
                DropdownMenuItem(
                  value: 'internal',
                  child: Text('Internal Storage'),
                ),
                DropdownMenuItem(
                  value: 'app',
                  child: Text('App Documents'),
                ),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await SettingsRepository().setSaveLocation(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save location updated')),
                  );
                  context.read<ScannedResultsCubit>().fetchResults();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Scanning',
      icon: Icons.qr_code_scanner,
      children: [
        _SwitchSetting(
          title: 'Auto-enable flash',
          prefKey: 'auto_flash',
          icon: Icons.flashlight_on,
          initialValue: context.watch<ScannedResultsCubit>().state.autoFlashEnabled,
          onChanged: (value) => context.read<ScannedResultsCubit>().updateFlashState(value),
        ),
        _SwitchSetting(
          title: 'Vibrate on success',
          prefKey: 'vibrate_feedback',
          icon: Icons.vibration,
          onChanged: (value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('vibrate_feedback', value);
          },
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        BlocBuilder<ThemeCubit, ThemeData>(
          builder: (context, theme) {
            return _SwitchSetting(
              title: 'Dark mode',
              prefKey: 'dark_mode',
              icon: Icons.dark_mode,
              initialValue: theme.brightness == Brightness.dark,
              onChanged: (value) {
                context.read<ThemeCubit>().toggleTheme(darkMode: value);
                print('-----------------testing--------------------------');
              },
            );
          },
        ),
        BlocBuilder<ThemeCubit, ThemeData>(
          builder: (context, theme) {
            return ListTile(
              leading: Icon(Icons.color_lens, color: AppColors.info),
              title: Text('Accent color'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () => _showColorPicker(context),
            );
          },
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose accent color'),
        content: Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: AppColors.primaries.map((color) =>
              _ColorCircle(
                color: color,
                isSelected: color == Theme.of(context).colorScheme.primary,
                onSelected: () => context.read<ThemeCubit>().toggleTheme(primaryColor: color),
              )
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Data',
      icon: Icons.storage,
      children: [
        ListTile(
          leading: Icon(Icons.import_export, color: AppColors.info),
          title: Text('Export history'),
          onTap: () => _exportData(context),
        ),
        ListTile(
          leading: Icon(Icons.upload, color: AppColors.info),
          title: Text('Import history'),
          onTap: () => _importData(context),
        ),
        ListTile(
          leading: Icon(Icons.delete, color: AppColors.error),
          title: Text('Clear all data'),
          onTap: () => _confirmClearData(context),
        ),
      ],
    );
  }


  Future<void> _importData(BuildContext context) async {
    try {
      const XTypeGroup csvType = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
        mimeTypes: ['text/csv'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: [csvType],
      );

      if (file == null) return;

      final Uint8List fileBytes = await file.readAsBytes();
      final String csvContent = utf8.decode(fileBytes);
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty || !_validateCsvHeader(rows[0])) {
        throw FormatException('Invalid CSV format. Required columns: Title, Content, Format, Timestamp');
      }

      final List<ScannedResult> validEntries = [];
      final database = DatabaseHelper.instance;

      for (var row in rows.skip(1)) {
        try {
          final entry = ScannedResult(
            title: row[0].toString(),
            data: row[1].toString(),
            format: BarcodeFormatUtils.fromImportString(row[2].toString()),
            timestamp: _parseTimestamp(row[3].toString()),
          );
          validEntries.add(entry);
        } catch (e) {
          print('Skipping invalid row: ${row.join(',')} - Error: $e');
        }
      }

      await database.bulkInsert(validEntries);
      context.read<ScannedResultsCubit>().fetchResults();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${validEntries.length} valid entries'),
          backgroundColor: Colors.green,
        ),
      );
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateCsvHeader(List<dynamic> header) {
    final expected = ['title', 'content', 'format', 'timestamp'];
    final received = header.map((h) => h.toString().toLowerCase()).toList();
    return received.length == expected.length &&
        received.every((h) => expected.contains(h));
  }

  DateTime _parseTimestamp(String timestamp) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').parse(timestamp);
    } catch (e) {
      throw FormatException('Invalid timestamp format: $timestamp');
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final results = await DatabaseHelper.instance.getScannedResults();
    final csvRows = [
      ['Title', 'Content', 'Format', 'Timestamp'],
      ...results.map((r) => [
        r.title,
        r.data,
        BarcodeFormatUtils.toExportString(r.format),
        DateFormat('yyyy-MM-dd HH:mm').format(r.timestamp)
      ])
    ];

    final csv = const ListToCsvConverter().convert(csvRows);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: 'scan_history_${DateTime.now().millisecondsSinceEpoch}.csv')],
      subject: 'Scan History Export',
    );
  }
  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear all data?'),
        content: Text('This will permanently delete all scan history.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScannedResultsCubit>().deleteAllResults();
              Navigator.of(context).pop();
            },
            child: Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PermissionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Permissions',
      icon: Icons.security,
      children: [
        _PermissionTile(permission: Permission.camera),
        _PermissionTile(permission: Permission.storage),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'About',
      icon: Icons.info,
      children: [
        ListTile(
          leading: Icon(Icons.description, color: AppColors.info),
          title: Text('Privacy Policy'),
          onTap: () => _launchUrl('https://example.com/privacy'),
        ),
        ListTile(
          leading: Icon(Icons.assignment, color: AppColors.info),
          title: Text('Terms of Service'),
          onTap: () => _launchUrl('https://example.com/terms'),
        ),
        ListTile(
          leading: Icon(Icons.code, color: AppColors.info),
          title: Text('App Version'),
          trailing: Text('1.0.0'),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _SwitchSetting extends StatefulWidget {
  final String title;
  final String prefKey;
  final IconData icon;
  final Function(bool)? onChanged;
  final bool initialValue;

  const _SwitchSetting({
    required this.title,
    required this.prefKey,
    required this.icon,
    this.onChanged,
    this.initialValue = false,
  });

  @override
  State<_SwitchSetting> createState() => _SwitchSettingState();
}

class _SwitchSettingState extends State<_SwitchSetting> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _value = prefs.getBool(widget.prefKey) ?? widget.initialValue;
    });
  }

  @override
  void didUpdateWidget(_SwitchSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      secondary: Icon(widget.icon, color: AppColors.info),
      value: widget.prefKey == 'auto_flash'
          ? context.watch<ScannedResultsCubit>().state.autoFlashEnabled
          : _value,
      onChanged: (value) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(widget.prefKey, value);

        if (widget.prefKey == 'dark_mode') {
          context.read<ThemeCubit>().toggleTheme(darkMode: value);
        } else if (widget.prefKey == 'auto_flash') {
          context.read<ScannedResultsCubit>().updateFlashState(value);
        }

        setState(() => _value = value);
        print('-----------------testing--------------------------');
      },
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onSelected,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: AppSpacing.medium),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Divider(height: AppSpacing.xlarge),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatefulWidget {
  final Permission permission;

  const _PermissionTile({required this.permission});

  @override
  State<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<_PermissionTile> {
  PermissionStatus _status = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await widget.permission.status;
    if (mounted) setState(() => _status = status);
  }

  Future<void> _requestPermission() async {
    final result = await widget.permission.request();
    if (mounted) {
      setState(() => _status = result);
      if (result.isPermanentlyDenied) {
        _showPermissionSettingsDialog();
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text('Please enable this permission in app settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _status.isGranted ? Icons.lock_open : Icons.lock_outline,
        color: _status.isGranted ? AppColors.success : AppColors.error,
      ),
      title: Text(_getPermissionName()),
      trailing: _status.isPermanentlyDenied
          ? TextButton(
        onPressed: openAppSettings,
        child: Text('Open Settings'),
      )
          : _status.isGranted
          ? null
          : TextButton(
        onPressed: () async {
          if (await widget.permission.shouldShowRequestRationale) {
            _showRationaleDialog();
          } else {
            _requestPermission();
          }
        },
        child: Text('Request'),
      ),
    );
  }

  String _getPermissionName() {
    switch (widget.permission) {
      case Permission.camera:
        return 'Camera Access';
      case Permission.storage:
        return 'File Storage';
      default:
        return widget.permission.toString().split('.').last;
    }
  }

  void _showRationaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Needed'),
        content: Text('This permission is required for ${_getPermissionName()} functionality'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
}