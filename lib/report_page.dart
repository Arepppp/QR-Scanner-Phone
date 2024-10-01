import 'package:flutter/material.dart';
import 'package:flutter_project_test/login.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'fullreportpage.dart';

class CanteenReportPage extends StatefulWidget {
  @override
  _CanteenReportPageState createState() => _CanteenReportPageState();
}

class _CanteenReportPageState extends State<CanteenReportPage>
    with TickerProviderStateMixin {
  // Animation variables
  late AnimationController _controller;
  late Animation<double> _animation;

// Meal counts (integer values for total counts)
  int totalBreakfastCount = 0; // Total count of breakfast
  int totalLunchCount = 0; // Total count of lunch
  int totalDinnerCount = 0; // Total count of dinner

// Today's meal counts
  int todayBreakfastCount = 0; // For today's breakfast count
  int todayLunchCount = 0; // For today's lunch count
  int todayDinnerCount = 0; // For today's dinner count

// This week's meal counts
  int weekBreakfastCount = 0; // For this week's breakfast count
  int weekLunchCount = 0; // For this week's lunch count
  int weekDinnerCount = 0; // For this week's dinner count

// This month's meal counts
  int monthBreakfastCount = 0; // For this month's breakfast count
  int monthLunchCount = 0; // For this month's lunch count
  int monthDinnerCount = 0; // For this month's dinner count

// (Optional) Meal percentages (if needed for specific calculations)
  double totalBreakfastPercentage = 0; // Percentage of total breakfast
  double totalLunchPercentage = 0; // Percentage of total lunch
  double totalDinnerPercentage = 0; // Percentage of total dinner
  double todayBreakfastPercentage = 0; // Percentage of today's breakfast
  double todayLunchPercentage = 0; // Percentage of today's lunch
  double todayDinnerPercentage = 0; // Percentage of today's dinner
  double weekBreakfastPercentage = 0; // Percentage of this week's breakfast
  double weekLunchPercentage = 0; // Percentage of this week's lunch
  double weekDinnerPercentage = 0; // Percentage of this week's dinner
  double monthBreakfastPercentage = 0; // Percentage of this month's breakfast
  double monthLunchPercentage = 0; // Percentage of this month's lunch
  double monthDinnerPercentage = 0; // Percentage of this month's dinner

// Flags
  bool isLoading = true; // Flag for loading state
  bool noScansPresent = false; // Flag for no scans present

// Date range for reports
  DateTime startDate = DateTime.now(); // Start date for fetching data
  DateTime endDate = DateTime.now(); // End date for fetching data

// Calculate total scans based on the counts
  int get totalScans =>
      totalBreakfastCount + totalLunchCount + totalDinnerCount;

  Map<String, Map<String, int>> mealCounts = {
    'today': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
    'week': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
    'month': {'breakfast': 0, 'lunch': 0, 'dinner': 0},
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // Duration for the animation
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _fetchMealData(); // Fetch data for the current date by default
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  Future<void> _fetchMealData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetching meal data from $startDate to $endDate'),
          duration: Duration(seconds: 3),
        ),
      );

// Initialize the mealCounts map if it’s not already initialized
      mealCounts['today'] ??= {
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
      };

      mealCounts['week'] ??= {
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
      };

      mealCounts['month'] ??= {
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
      };

      // Fetch all-time data
      final allTimeCounts = await fetchMealReport(
        context,
        DateTime(2000, 1, 1), // Start date (adjust as necessary)
        DateTime.now(), // End date is now
      );

      // Process all-time data
      totalBreakfastCount = allTimeCounts['today']!['breakfast'] ?? 0;
      totalLunchCount = allTimeCounts['today']!['lunch'] ?? 0;
      totalDinnerCount = allTimeCounts['today']!['dinner'] ?? 0;

      // Show fetched all-time counts
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All-time meal scan counts: $allTimeCounts'),
          duration: Duration(seconds: 3),
        ),
      );

      // Calculate total scans and percentages for all-time data
      int totalScans = totalBreakfastCount + totalLunchCount + totalDinnerCount;
      // Set noScansPresent based on totalScans
      noScansPresent = totalScans == 0;

      if (totalScans == 0) {
        DateTime firstDayOfMonth =
            DateTime.now().subtract(Duration(days: DateTime.now().day - 1));
        DateTime lastDayOfMonth =
            DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fetching monthly data from $firstDayOfMonth to $lastDayOfMonth'),
            duration: Duration(seconds: 3),
          ),
        );

        final monthlyScanCounts =
            await fetchMealReport(context, firstDayOfMonth, lastDayOfMonth);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monthly meal scan counts: $monthlyScanCounts'),
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          totalBreakfastCount = monthlyScanCounts['today']!['breakfast'] ?? 0;
          totalLunchCount = monthlyScanCounts['today']!['lunch'] ?? 0;
          totalDinnerCount = monthlyScanCounts['today']!['dinner'] ?? 0;
        });
      }

      // Update totalScans after fetching monthly data if necessary
      totalScans = totalBreakfastCount + totalLunchCount + totalDinnerCount;

      // Update the state for pie charts
      setState(() {
        // Update total counts for the pie chart indicators
        isLoading = false;
      });

      // Fetch today's counts
      final todayCounts =
          await fetchMealReport(context, DateTime.now(), DateTime.now());

      setState(() {
        todayBreakfastPercentage =
            (todayCounts['today']?['breakfast'] as num?)?.toDouble() ?? 0.0;
        todayLunchPercentage =
            (todayCounts['today']?['lunch'] as num?)?.toDouble() ?? 0.0;
        todayDinnerPercentage =
            (todayCounts['today']?['dinner'] as num?)?.toDouble() ?? 0.0;

        // Use the null-aware operator to assign values
        mealCounts['today']!['breakfast'] =
            (todayCounts['today']?['breakfast'] as num?)?.toInt() ?? 0;
        mealCounts['today']!['lunch'] =
            (todayCounts['today']?['lunch'] as num?)?.toInt() ?? 0;
        mealCounts['today']!['dinner'] =
            (todayCounts['today']?['dinner'] as num?)?.toInt() ?? 0;
      });

      // Fetch meal data for this week
      DateTime startOfWeek =
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final weekCounts =
          await fetchMealReport(context, startOfWeek, DateTime.now());

      setState(() {
        weekBreakfastPercentage =
            (weekCounts['week']?['breakfast'] as num?)?.toDouble() ?? 0.0;
        weekLunchPercentage =
            (weekCounts['week']?['lunch'] as num?)?.toDouble() ?? 0.0;
        weekDinnerPercentage =
            (weekCounts['week']?['dinner'] as num?)?.toDouble() ?? 0.0;

        // Update mealCounts for this week
        mealCounts['week']!['breakfast'] = weekBreakfastPercentage.toInt();
        mealCounts['week']!['lunch'] = weekLunchPercentage.toInt();
        mealCounts['week']!['dinner'] = weekDinnerPercentage.toInt();
      });

      // Fetch meal data for this month
      DateTime firstDayOfMonth =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      final monthCounts =
          await fetchMealReport(context, firstDayOfMonth, DateTime.now());

      setState(() {
        monthBreakfastPercentage =
            (monthCounts['month']?['breakfast'] as num?)?.toDouble() ?? 0.0;
        monthLunchPercentage =
            (monthCounts['month']?['lunch'] as num?)?.toDouble() ?? 0.0;
        monthDinnerPercentage =
            (monthCounts['month']?['dinner'] as num?)?.toDouble() ?? 0.0;

        // Update mealCounts for this month
        mealCounts['month']!['breakfast'] = monthBreakfastPercentage.toInt();
        mealCounts['month']!['lunch'] = monthLunchPercentage.toInt();
        mealCounts['month']!['dinner'] = monthDinnerPercentage.toInt();
      });

      // Display a message if no meal data is available
      if (totalScans == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No meal data available.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          // Update any state variables related to displaying data in pie charts here
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch data: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Date selection for start and end dates
  // Allow the user to select a date range for the report
  Future<void> _selectDateRange() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening date range picker...'),
          duration: Duration(seconds: 2),
        ),
      );
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024, 8, 1),
        lastDate: DateTime.now(),
      );
      if (pickedRange != null) {
        setState(() {
          startDate = pickedRange.start;
          endDate = pickedRange.end;
        });
        _fetchMealData(); // Fetch meal data for the selected date range
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting date range: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear SharedPreferences to log out
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) =>
                LoginPage(initialized: true)), // Redirect to LoginPage
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canteen Report'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _selectDateRange,
              child: Text('Select Date Range'),
            ),
            SizedBox(height: 20),
            // Existing chart for the selected date range
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (noScansPresent)
              Column(
                children: [
                  Text("TEST Scans"),
                  SizedBox(height: 100),
                  Center(
                    child: CustomPaint(
                      painter: MealChartPainter(0, 0, 0),
                      child: Container(
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                  Text('No scans recorded'),
                ],
              )
            else
              Column(
                children: [
                  Text("Test SCANS"),
                  SizedBox(height: 20),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: MealChartPainter(
                            totalBreakfastCount,
                            totalLunchCount,
                            totalDinnerCount,
                          ),
                          child: Container(
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // New section for today, this week, and this month pie charts
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPieChartBox(
                            mealCounts['today']!['breakfast'] ??
                                0, // Today's breakfast count
                            mealCounts['today']!['lunch'] ??
                                0, // Today's lunch count
                            mealCounts['today']!['dinner'] ??
                                0, // Today's dinner count
                            "Today's Meals",
                            "today",
                          ),
                          
                          SizedBox(height: 20),
                          _buildPieChartBox(
                            mealCounts['week']!['breakfast'] ??
                                0, // This week's breakfast count
                            mealCounts['week']!['lunch'] ??
                                0, // This week's lunch count
                            mealCounts['week']!['dinner'] ??
                                0, // This week's dinner count
                            "This Week's Meals",
                            "week",
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildPieChartBox(
                        mealCounts['month']!['breakfast'] ??
                            0, // This month's breakfast count
                        mealCounts['month']!['lunch'] ??
                            0, // This month's lunch count
                        mealCounts['month']!['dinner'] ??
                            0, // This month's dinner count
                        "This Month's Meals",
                        "month",
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartBox(
    int breakfastCount, int lunchCount, int dinnerCount, String title, String type) {
  return Container(
    width: 150,
    height: 150,
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
}

class MealChartPainter extends CustomPainter {
  final int totalBreakfastCount;
  final int totalLunchCount;
  final int totalDinnerCount;

  MealChartPainter(
    this.totalBreakfastCount,
    this.totalLunchCount,
    this.totalDinnerCount,
  );

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
      double breakfastMidAngle = -pi / 2 + breakfastSweepAngle / 2;
      _drawTextAtAngle(canvas, 'B: $totalBreakfastCount', center,
          breakfastMidAngle, radius * 0.7);
    }

    if (totalLunchCount > 0) {
      double lunchMidAngle =
          -pi / 2 + breakfastSweepAngle + lunchSweepAngle / 2;
      _drawTextAtAngle(
          canvas, 'L: $totalLunchCount', center, lunchMidAngle, radius * 0.7);
    }

    if (totalDinnerCount > 0) {
      double dinnerMidAngle = -pi / 2 +
          breakfastSweepAngle +
          lunchSweepAngle +
          dinnerSweepAngle / 2;
      _drawTextAtAngle(
          canvas, 'D: $totalDinnerCount', center, dinnerMidAngle, radius * 0.7);
    }

    // Optionally draw the total scans in the center of the chart
    _drawTotalScans(canvas, totalScans, center);
  }

  // Helper method to draw text at a specified angle and distance from the center
  void _drawTextAtAngle(
      Canvas canvas, String text, Offset center, double angle, double radius) {
    double x = center.dx + radius * cos(angle);
    double y = center.dy + radius * sin(angle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black, fontSize: 14),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  // Helper method to draw the total scans in the center of the pie chart
  void _drawTotalScans(Canvas canvas, int totalScans, Offset center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$totalScans',
        style: TextStyle(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MealChartWidget extends StatelessWidget {
  final double breakfastPercentage;
  final double lunchPercentage;
  final double dinnerPercentage;
  final int totalBreakfastCount;
  final int totalLunchCount;
  final int totalDinnerCount;
  final String period;

  MealChartWidget({
    required this.breakfastPercentage,
    required this.lunchPercentage,
    required this.dinnerPercentage,
    required this.totalBreakfastCount,
    required this.totalLunchCount,
    required this.totalDinnerCount,
    required this.period, // today/this week/this month
  });

  @override
  Widget build(BuildContext context) {
    bool hasScans =
        totalBreakfastCount > 0 || totalLunchCount > 0 || totalDinnerCount > 0;

    return Container(
      height: 200, // Adjust based on your layout
      width: 200, // Adjust based on your layout
      child: hasScans
          ? CustomPaint(
              painter: MealChartPainter(
                totalBreakfastCount,
                totalLunchCount,
                totalDinnerCount,
              ),
            )
          : Center(
              child: Text(
                'No scans for $period.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
    );
  }
}
