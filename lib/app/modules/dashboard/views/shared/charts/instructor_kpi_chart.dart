import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InstructorKPIChart extends StatelessWidget {
  final DashboardStats stats;

  const InstructorKPIChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final kpis = _buildKpis(stats);
    final maxVal = kpis.map((e) => e.value).fold<double>(0, (p, c) => c > p ? c : p);
    final double maxY = (maxVal * 1.2) + 1; // ensure some headroom and >= 1

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
                    Icons.stacked_bar_chart,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'KPI lớp học',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.8,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final kpi = kpis[group.x.toInt()];
                        return BarTooltipItem(
                          '${kpi.label}\n',
                          const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: kpi.value.toStringAsFixed(1),
                              style: TextStyle(
                                color: kpi.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= kpis.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Transform.rotate(
                              angle: -0.5, // ~-28.6 degrees for readability
                              child: Text(
                                kpis[idx].shortLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(kpis.length, (i) {
                    final k = kpis[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: k.value,
                          color: k.color,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_KPI> _buildKpis(DashboardStats s) {
    final safeCourses = s.totalCourses == 0 ? 1 : s.totalCourses;
    final safeGroups = s.totalGroups == 0 ? 1 : s.totalGroups;

    return [
      _KPI('Students per Course', 'Stud/Crs', s.totalStudents / safeCourses, Colors.orange),
      _KPI('Students per Group', 'Stud/Grp', s.totalStudents / safeGroups, Colors.green),
      _KPI('Assignments per Course', 'Assign/Crs', s.totalAssignments / safeCourses, Colors.purple),
      _KPI('Quizzes per Course', 'Quiz/Crs', s.totalQuizzes / safeCourses, Colors.red),
      _KPI('Announcements per Course', 'Ann/Crs', s.totalAnnouncements / safeCourses, Colors.teal),
    ];
  }
}

class _KPI {
  final String label;
  final String shortLabel;
  final double value;
  final Color color;
  _KPI(this.label, this.shortLabel, this.value, this.color);
}


