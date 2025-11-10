import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ContentDistributionChart extends StatelessWidget {
  final DashboardStats stats;

  const ContentDistributionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalAssignments + stats.totalQuizzes + stats.totalAnnouncements;
    final items = [
      _Slice('Assignments', stats.totalAssignments, Colors.purple),
      _Slice('Quizzes', stats.totalQuizzes, Colors.red),
      _Slice('Announcements', stats.totalAnnouncements, Colors.teal),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Phân bố nội dung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: _sections(items, total),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: items
                  .map((e) => _Legend(color: e.color, label: '${e.label}: ${e.value}'))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _sections(List<_Slice> items, int total) {
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade200,
          value: 1,
          title: '',
          radius: 40,
        ),
      ];
    }

    return items.map((s) {
      final value = s.value.toDouble();
      final pct = total == 0 ? 0.0 : (value / total) * 100;
      return PieChartSectionData(
        color: s.color,
        value: value,
        title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 45,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }
}

class _Slice {
  final String label;
  final int value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}


