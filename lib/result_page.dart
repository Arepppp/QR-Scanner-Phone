// result_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultPage extends StatelessWidget {
  final String result;
  final String placeName;
  final double? latitude;
  final double? longitude;

  ResultPage({
    required this.result,
    required this.placeName,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current date and time
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final formattedTime = DateFormat('HH:mm:ss').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Result'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Scan Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Result:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                result,
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (placeName.isNotEmpty)
                Text(
                  'Place: $placeName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              Text(
                'Date: $formattedDate',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Time: $formattedTime',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              if (latitude != null && longitude != null) ...[
                SizedBox(height: 20),
                Text(
                  'Location:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Lat: $latitude, Long: $longitude',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
