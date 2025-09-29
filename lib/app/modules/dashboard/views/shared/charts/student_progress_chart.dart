import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StudentProgressChart extends StatelessWidget {
  // TODO: Replace with actual data from the controller
  final int completed;
  final int pending;

  const StudentProgressChart({
    super.key,
    required this.completed,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed + pending;
    final percentage = total == 0 ? 0.0 : (completed / total) * 100;

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: showingSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Optional: Handle touch events
                },
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const Text('Completed'),
            ],
          )
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final total = completed + pending;
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade200,
          value: 100,
          title: '',
          radius: 20,
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.green,
        value: completed.toDouble(),
        title: '',
        radius: 25,
      ),
      PieChartSectionData(
        color: Colors.grey.shade300,
        value: pending.toDouble(),
        title: '',
        radius: 20,
      ),
    ];
  }
}
