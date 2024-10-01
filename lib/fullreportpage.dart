import 'package:flutter/material.dart';

class FullReportPage extends StatelessWidget {
  final String type;

  const FullReportPage({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for demonstration
    Map<String, List<Map<String, dynamic>>> reportData = {
      'today': [
        {'meal': 'Breakfast', 'count': 10},
        {'meal': 'Lunch', 'count': 15},
        {'meal': 'Dinner', 'count': 8},
      ],
      'week': [
        {'meal': 'Breakfast', 'count': 50},
        {'meal': 'Lunch', 'count': 60},
        {'meal': 'Dinner', 'count': 30},
      ],
      'month': [
        {'meal': 'Breakfast', 'count': 200},
        {'meal': 'Lunch', 'count': 250},
        {'meal': 'Dinner', 'count': 150},
      ],
    };

    List<Map<String, dynamic>> data = reportData[type] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${type.capitalize()} Meal Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final meal = data[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(meal['meal']),
                trailing: Text(meal['count'].toString()),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}