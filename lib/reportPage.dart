import 'dart:math';
import 'package:flutter/material.dart';
import 'login.dart'; // Keep for navigation
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fullreportpage.dart';
import 'DateRangeReportPage.dart';
import 'dart:ui' as ui;

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool isLoading = true;
  bool noScansPresent = false;

  // Total counts for today, this week, and this month
  int todayBreakfastCount = 0;
  int todayLunchCount = 0;
  int todayDinnerCount = 0;

  int weekBreakfastCount = 0;
  int weekLunchCount = 0;
  int weekDinnerCount = 0;

  int monthBreakfastCount = 0;
  int monthLunchCount = 0;
  int monthDinnerCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMealData(); // Fetch data when the page loads
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1), // Adjust this as needed
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      // Fetch meal data for the selected date range
      final selectedRangeData =
          await fetchMealReport(context, pickedRange.start, pickedRange.end);

      setState(() {
        monthBreakfastCount = selectedRangeData['month']?['breakfast'] ?? 0;
        monthLunchCount = selectedRangeData['month']?['lunch'] ?? 0;
        monthDinnerCount = selectedRangeData['month']?['dinner'] ?? 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Data updated for range: ${DateFormat('yyyy-MM-dd').format(pickedRange.start)} - ${DateFormat('yyyy-MM-dd').format(pickedRange.end)}'),
        ),
      );
    }
  }

  Future<void> _fetchMealData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch meal data for today
      final todayCounts =
          await fetchMealReport(context, DateTime.now(), DateTime.now());
      setState(() {
        todayBreakfastCount = todayCounts['today']?['breakfast'] ?? 0;
        todayLunchCount = todayCounts['today']?['lunch'] ?? 0;
        todayDinnerCount = todayCounts['today']?['dinner'] ?? 0;

        // Check if no scans are present
        noScansPresent = todayBreakfastCount == 0 &&
            todayLunchCount == 0 &&
            todayDinnerCount == 0;
      });

      // Fetch meal data for this week
      DateTime startOfWeek =
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final weekCounts =
          await fetchMealReport(context, startOfWeek, DateTime.now());
      setState(() {
        weekBreakfastCount = weekCounts['week']?['breakfast'] ?? 0;
        weekLunchCount = weekCounts['week']?['lunch'] ?? 0;
        weekDinnerCount = weekCounts['week']?['dinner'] ?? 0;
      });

      // Fetch meal data for this month
      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      final monthCounts =
          await fetchMealReport(context, firstDayOfMonth, DateTime.now());
      setState(() {
        monthBreakfastCount = monthCounts['month']?['breakfast'] ?? 0;
        monthLunchCount = monthCounts['month']?['lunch'] ?? 0;
        monthDinnerCount = monthCounts['month']?['dinner'] ?? 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch data: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, Map<String, int>>> fetchMealReport(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final client = Supabase.instance.client;
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    // Initialize meal counts
    Map<String, Map<String, int>> mealCounts = {
      'today': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
      'week': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
      'month': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
    };

    try {
      // Fetch Today's Meals
      final todayResponse = await client
          .from('scans')
          .select('mealscanned')
          .eq('date', formatter.format(DateTime.now())); // Fetch today's meals
      for (var meal in todayResponse) {
        String mealType = meal['mealscanned'] as String;
        mealCounts['today']![mealType.toLowerCase()] =
            (mealCounts['today']![mealType.toLowerCase()] ?? 0) + 1;
      }

      // Fetch Meals within the provided date range
      final rangeResponse = await client
          .from('scans')
          .select('mealscanned')
          .gte('date',
              formatter.format(startDate)) // Start from the provided startDate
          .lte('date', formatter.format(endDate)); // Up to the provided endDate
      for (var meal in rangeResponse) {
        String mealType = meal['mealscanned'] as String;
        // Count meals based on the date range
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
      return mealCounts; // Return zeros if an error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canteen Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Two charts at the top (Today and This Week)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Use Supabase data and increase chart size
                _buildPieChartBox(
                  todayBreakfastCount,
                  todayLunchCount,
                  todayDinnerCount,
                  'Today\'s Report',
                  'today',
                ),
                _buildPieChartBox(
                  weekBreakfastCount,
                  weekLunchCount,
                  weekDinnerCount,
                  'This Week\'s Report',
                  'week',
                ),
              ],
            ),
            SizedBox(height: 20),
            // One chart at the bottom (This Month)
            Center(
              child: Column(
                children: [
                  _buildPieChartBox(
                    monthBreakfastCount,
                    monthLunchCount,
                    monthDinnerCount,
                    'This Month\'s Report',
                    'month',
                  ),
                  SizedBox(height: 16), // Space between the chart and button
                  ElevatedButton(
                    onPressed:
                        _navigateToDateRangeReport, // Call the correct method here
                    child: Text('Select Date Range for Analysis'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDateRangeReport() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 9),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      // Debug output to verify the date range
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Selected range: ${pickedRange.start} to ${pickedRange.end}')),
      );

      // Navigate to the DateRangeReportPage with the selected date range
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DateRangeReportPage(
            startDate: pickedRange.start,
            endDate: pickedRange.end,
          ),
        ),
      );
    }
  }

  Widget _buildPieChartBox(int breakfastCount, int lunchCount, int dinnerCount,
      String title, String type) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Expanded(
            child: CustomPaint(
              painter: MealChartPainter(
                breakfastCount,
                lunchCount,
                dinnerCount,
              ),
              child: Container(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullReportPage(type: type),
                ),
              );
            },
            child: Text('See Full Report'),
          ),
        ],
      ),
    );
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

    double startAngle = -pi / 2; // Start from the top

    // Calculate the total number of scans
    int totalScans = totalBreakfastCount + totalLunchCount + totalDinnerCount;
    if (totalScans == 0) return; // If no scans, don't paint the chart

    // Calculate sweep angles based on the proportion of each meal's total scans
    double breakfastSweepAngle = 2 * pi * (totalBreakfastCount / totalScans);
    double lunchSweepAngle = 2 * pi * (totalLunchCount / totalScans);
    double dinnerSweepAngle = 2 * pi * (totalDinnerCount / totalScans);

    // Draw breakfast segment
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        breakfastSweepAngle, true, breakfastPaint);
    startAngle += breakfastSweepAngle;

    // Draw lunch segment
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        lunchSweepAngle, true, lunchPaint);
    startAngle += lunchSweepAngle;

    // Draw dinner segment
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        dinnerSweepAngle, true, dinnerPaint);

    // Draw indicators inside the pie chart for each meal
    if (totalBreakfastCount > 0) {
      double breakfastMidAngle = -pi / 2 + (breakfastSweepAngle / 2);
      _drawIndicatorText(
          canvas, center, 'B:$totalBreakfastCount', breakfastMidAngle, radius);
    }
    if (totalLunchCount > 0) {
      double lunchMidAngle =
          -pi / 2 + breakfastSweepAngle + (lunchSweepAngle / 2);
      _drawIndicatorText(
          canvas, center, 'L:$totalLunchCount', lunchMidAngle, radius);
    }
    if (totalDinnerCount > 0) {
      double dinnerMidAngle = -pi / 2 +
          breakfastSweepAngle +
          lunchSweepAngle +
          (dinnerSweepAngle / 2);
      _drawIndicatorText(
          canvas, center, 'D:$totalDinnerCount', dinnerMidAngle, radius);
    }
  }

  void _drawIndicatorText(
      Canvas canvas, Offset center, String text, double angle, double radius) {
    final textStyle = TextStyle(color: Colors.black, fontSize: 14);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    // Adjust the radius factor for better positioning
    final offsetX =
        center.dx + cos(angle) * radius * 0.5 - (textPainter.width / 2);
    final offsetY =
        center.dy + sin(angle) * radius * 0.5 - (textPainter.height / 2);

    // Draw the text at the calculated position
    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Update when needed
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

    // Don't draw the chart if there are no scans
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
        Text('D: $dinnerCount, L: $lunchCount, B: $breakfastCount',
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 32),
      ],
    );
  }
}
