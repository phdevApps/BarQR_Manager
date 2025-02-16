import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barqr_manager/app_theme.dart';
import 'package:barqr_manager/scanned_results_cubit.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:barqr_manager/saved_screen.dart';
import 'package:barqr_manager/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ScannedResultsCubit>().fetchResults(),
          ),
        ],
      ),
      body: BlocBuilder<ScannedResultsCubit, ScannedResultsState>(
        builder: (context, state) {
          if (state.results.isEmpty) {
            return _buildEmptyState(context);
          }

          final formatDistribution = _calculateFormatDistribution(state.results);
          final chartData = _prepareChartData(formatDistribution, context);

          return RefreshIndicator(
            onRefresh: () => context.read<ScannedResultsCubit>().fetchResults(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetricsGrid(state.results, formatDistribution, context),
                        const SizedBox(height: 16),
                        _buildFormatChart(chartData, context),
                        const SizedBox(height: 16),
                        _buildRecentActivity(state.results, context),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(height: AppSpacing.large),
          Text(
            'No scans yet!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            'Start scanning or creating codes to see statistics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
      List<ScannedResult> results,
      Map<BarcodeFormat, int> distribution,
      BuildContext context
      ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.38,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1, // Adjusted from 1.2
        mainAxisSpacing: 8,    // Reduced from 12
        crossAxisSpacing: 8,   // Reduced from 12
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _MetricCard(
            title: 'Total Scans',
            value: results.length.toString(),
            icon: Icons.scanner,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          _MetricCard(
            title: 'Formats Used',
            value: distribution.keys.length.toString(),
            icon: Icons.format_list_bulleted,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          _MetricCard(
            title: '7-Day Activity',
            value: _scansLast7Days(results).toString(),
            icon: Icons.timeline,
            color: Theme.of(context).colorScheme.tertiaryContainer,
          ),
          _MetricCard(
            title: 'Most Common',
            value: _getMostUsedFormat(distribution),
            icon: Icons.star,
            color: Theme.of(context).colorScheme.errorContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChart(List<PieChartSectionData> chartData, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Format Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.pie_chart_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: PieChart(
                PieChartData(
                  sections: chartData,
                  centerSpaceRadius: 42,
                  sectionsSpace: 4,
                  startDegreeOffset: 180,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(chartData, context),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(List<PieChartSectionData> chartData, BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: chartData.map((section) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: section.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              section.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  Widget _buildRecentActivity(List<ScannedResult> results, BuildContext context) {
    final recentScans = results.take(3).toList();

    return Card(

      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SavedScreen()),
                  ),
                ),
              ],
            ),
            ...recentScans.map((scan) => _ActivityItem(
              result: scan,
              onTap: () => _showDetails(context, scan),
            )),
            if (recentScans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No recent activity'),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, ScannedResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.title),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('Type: ${_formatName(result.format.name)}'),
            Text('Date: ${DateFormat.yMd().add_jm().format(result.timestamp)}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.small),
              ),
              child: Text(result.data),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<PieChartSectionData> _prepareChartData(
      Map<BarcodeFormat, int> distribution,
      BuildContext context
      ) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
    ];

    return distribution.entries.map((entry) {
      final index = distribution.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${_formatName(entry.key.name)}\n${entry.value}',
        radius: 28,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }).toList();
  }


  static String _formatName(String format) =>
      format[0].toUpperCase() + format.substring(1);

  static Map<BarcodeFormat, int> _calculateFormatDistribution(List<ScannedResult> results) {
    final Map<BarcodeFormat, int> distribution = {};
    for (final result in results) {
      distribution[result.format] = (distribution[result.format] ?? 0) + 1;
    }
    return distribution;
  }

  static String _getMostUsedFormat(Map<BarcodeFormat, int> distribution) {
    if (distribution.isEmpty) return '-';
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _formatName(sorted.first.key.name); // Now calling static method
  }

  static int _scansLast7Days(List<ScannedResult> results) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return results.where((r) => r.timestamp.isAfter(weekAgo)).length;
  }
}
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ActivityItem extends StatelessWidget {
  final ScannedResult result;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_formatIcon(result.format), color: Theme.of(context).primaryColor),
      ),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat.MMMd().add_jm().format(result.timestamp),
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  IconData _formatIcon(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return Icons.qr_code;
      case BarcodeFormat.ean13:
      case BarcodeFormat.ean8:
        return Icons.barcode_reader;
      case BarcodeFormat.code128:
        return Icons.view_week;
      case BarcodeFormat.dataMatrix:
        return Icons.grid_on;
      default:
        return Icons.tag;
    }
  }
}