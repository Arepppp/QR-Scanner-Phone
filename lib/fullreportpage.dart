import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:ui' as ui;

class FullReportPage extends StatelessWidget {
  final String type;

  const FullReportPage({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime startDate = getStartDateForType(type);
    DateTime endDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('${type.capitalize()} Meal Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, Map<String, int>>>(
          future: fetchMealReport(context, startDate, endDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final mealCounts = snapshot.data ?? {};
            final breakfastCount = mealCounts[type]!['breakfast'] ?? 0;
            final lunchCount = mealCounts[type]!['lunch'] ?? 0;
            final dinnerCount = mealCounts[type]!['dinner'] ?? 0;

            return Column(
              children: [
                MealChartWidget(
                  breakfastCount: breakfastCount,
                  lunchCount: lunchCount,
                  dinnerCount: dinnerCount,
                  period: type.capitalize(),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Breakfast'),
                          trailing: Text(breakfastCount.toString()),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Lunch'),
                          trailing: Text(lunchCount.toString()),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Dinner'),
                          trailing: Text(dinnerCount.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, Map<String, int>>> fetchMealReport(
      BuildContext context, DateTime startDate, DateTime endDate) async {
    final client = Supabase.instance.client;
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    Map<String, Map<String, int>> mealCounts = {
      'today': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
      'week': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
      'month': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
    };

    try {
      final todayResponse = await client
          .from('scans')
          .select('mealscanned')
          .eq('date', formatter.format(DateTime.now()));

      for (var meal in todayResponse) {
        String mealType = meal['mealscanned'] as String;
        mealCounts['today']![mealType.toLowerCase()] =
            (mealCounts['today']![mealType.toLowerCase()] ?? 0) + 1;
      }

      final rangeResponse = await client
          .from('scans')
          .select('mealscanned')
          .gte('date', formatter.format(startDate))
          .lte('date', formatter.format(endDate));

      for (var meal in rangeResponse) {
        String mealType = meal['mealscanned'] as String;
        if (startDate.isAfter(DateTime.now().subtract(Duration(days: 7)))) {
          mealCounts['week']![mealType.toLowerCase()] =
              (mealCounts['week']![mealType.toLowerCase()] ?? 0) + 1;
        }
        if (startDate.month == DateTime.now().month) {
          mealCounts['month']![mealType.toLowerCase()] =
              (mealCounts['month']![mealType.toLowerCase()] ?? 0) + 1;
        }
      }

      return mealCounts;
    } catch (e) {
      return mealCounts;
    }
  }

  DateTime getStartDateForType(String type) {
    DateTime now = DateTime.now();
    if (type == 'today') {
      return DateTime(now.year, now.month, now.day);
    } else if (type == 'week') {
      return now.subtract(Duration(days: now.weekday - 1));
    } else {
      return DateTime(now.year, now.month, 1);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

class MealChartPainter extends CustomPainter {
  final int totalBreakfastCount;
  final int totalLunchCount;
  final int totalDinnerCount;

  MealChartPainter(
      this.totalBreakfastCount, this.totalLunchCount, this.totalDinnerCount);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final Paint breakfastPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final Paint lunchPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final Paint dinnerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    double startAngle = -pi / 2;

    int totalScans = totalBreakfastCount + totalLunchCount + totalDinnerCount;
    if (totalScans == 0) return;

    double breakfastSweepAngle = 2 * pi * (totalBreakfastCount / totalScans);
    double lunchSweepAngle = 2 * pi * (totalLunchCount / totalScans);
    double dinnerSweepAngle = 2 * pi * (totalDinnerCount / totalScans);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        breakfastSweepAngle, true, breakfastPaint);
    startAngle += breakfastSweepAngle;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        lunchSweepAngle, true, lunchPaint);
    startAngle += lunchSweepAngle;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        dinnerSweepAngle, true, dinnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MealChartWidget extends StatelessWidget {
  final int breakfastCount;
  final int lunchCount;
  final int dinnerCount;
  final String period;

  const MealChartWidget({
    required this.breakfastCount,
    required this.lunchCount,
    required this.dinnerCount,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    int totalScans = breakfastCount + lunchCount + dinnerCount;

    if (totalScans == 0) {
      return Center(child: Text("No data available for $period."));
    }

    return Column(
      children: [
        Text(period,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Container(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: MealChartPainter(breakfastCount, lunchCount, dinnerCount),
          ),
        ),
        SizedBox(height: 16),
        Text('B: $breakfastCount, L: $lunchCount, D: $dinnerCount',
            style: TextStyle(fontSize: 16)),
      ],
    );
  }
}