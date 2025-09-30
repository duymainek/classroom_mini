import 'package:classroom_mini/app/data/models/response/dashboard_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InstructorSummaryChart extends StatelessWidget {
  final DashboardStats stats;

  const InstructorSummaryChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String weekDay;
                    switch (group.x.toInt()) {
                      case 0:
                        weekDay = 'Courses';
                        break;
                      case 1:
                        weekDay = 'Groups';
                        break;
                      case 2:
                        weekDay = 'Students';
                        break;
                      case 3:
                        weekDay = 'Assignments';
                        break;
                      default:
                        throw Error();
                    }
                    return BarTooltipItem(
                      '$weekDay\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: (rod.toY - 1).toString(),
                          style: const TextStyle(color: Colors.yellow),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: getTitles,
                    reservedSize: 48,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: showingGroups(),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    final values = [
      stats.totalCourses,
      stats.totalGroups,
      stats.totalStudents,
      stats.totalAssignments,
      stats.totalQuizzes,
    ];
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.2) + 1; // Add some padding
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    Color barColor = Colors.blue,
    double width = 22,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: width,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  List<BarChartGroupData> showingGroups() => [
        makeGroupData(0, stats.totalCourses.toDouble() + 1,
            barColor: Colors.blue),
        makeGroupData(1, stats.totalGroups.toDouble() + 1,
            barColor: Colors.green),
        makeGroupData(2, stats.totalStudents.toDouble() + 1,
            barColor: Colors.orange),
        makeGroupData(3, stats.totalAssignments.toDouble() + 1,
            barColor: Colors.purple),
        makeGroupData(4, stats.totalQuizzes.toDouble() + 1,
            barColor: Colors.red),
      ];

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Courses', style: style);
        break;
      case 1:
        text = const Text('Groups', style: style);
        break;
      case 2:
        text = const Text('Students', style: style);
        break;
      case 3:
        text = const Text('Assign', style: style);
        break;
      case 4:
        text = const Text('Quizzes', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }
}
