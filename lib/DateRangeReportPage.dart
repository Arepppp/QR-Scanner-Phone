import 'package:flutter/material.dart';
import 'package:flutter_project_test/reportPage.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DateRangeReportPage extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  DateRangeReportPage({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Date Range Report'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: fetchMealReport(context, startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            int breakfastCount = data['breakfast'] ?? 0;
            int lunchCount = data['lunch'] ?? 0;
            int dinnerCount = data['dinner'] ?? 0;

            return Center(
              // Center the chart and title vertically and horizontally
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center content
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontally center content
                children: [
                  Text(
                    'Meal Report: ${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                    style: TextStyle(
                      fontSize: 20, // Make the title larger
                      fontWeight: FontWeight.bold, // Bold text
                      color: Colors.deepPurple, // Add some color
                    ),
                    textAlign: TextAlign.center, // Center the title
                  ),
                  SizedBox(
                      height: 20), // Add some space between the title and chart
                  CustomPaint(
                    painter: MealChartPainter(
                      breakfastCount,
                      lunchCount,
                      dinnerCount,
                    ),
                    child: Container(
                      width: 250,
                      height: 250,
                    ),
                  ),
                  SizedBox(height: 20), // Space between chart and legends
                  // Legends under the chart
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center the legends
                    children: [
                      LegendItem(
                        color: Colors.blue, // Color for breakfast
                        label: 'Breakfast',
                      ),
                      SizedBox(width: 10), // Space between legends
                      LegendItem(
                        color: Colors.green, // Color for lunch
                        label: 'Lunch',
                      ),
                      SizedBox(width: 10),
                      LegendItem(
                        color: Colors.red, // Color for dinner
                        label: 'Dinner',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, int>> fetchMealReport(
      BuildContext context, DateTime startDate, DateTime endDate) async {
    final formatter = DateFormat('yyyy-MM-dd');

    // Call the SQL function and pass start and end dates
    final response =
        await Supabase.instance.client.rpc('fetch_meal_counts', params: {
      'start_date': formatter.format(startDate),
      'end_date': formatter.format(endDate),
    });

    // Check for errors in the response
    if (response == null) {
      // Use a Snackbar to show the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Response is null')),
      );
      throw Exception('Failed to fetch meal report: Response is null');
    }

    // Extract the counts directly from the response
    List<dynamic> mealData = response as List<dynamic>;

    // Return the counts in a Map
    return {
      'breakfast':
          mealData.isNotEmpty ? mealData[0]['breakfast_count'] ?? 0 : 0,
      'lunch': mealData.isNotEmpty ? mealData[0]['lunch_count'] ?? 0 : 0,
      'dinner': mealData.isNotEmpty ? mealData[0]['dinner_count'] ?? 0 : 0,
    };
  }
}

// Widget to create a legend item
class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}