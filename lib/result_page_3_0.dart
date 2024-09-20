import 'package:flutter/material.dart';

class ResultPage3_0 extends StatelessWidget {
  final DateTime timestamp;
  final String empid;
  final String? checkOutNotice;
  final String? checkOutLocation;

  ResultPage3_0({
    required this.timestamp,
    required this.empid,
    this.checkOutNotice,
    this.checkOutLocation,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1]}";

    return Scaffold(
      appBar: AppBar(title: Text('Check-Out Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100.0,
            ),
            SizedBox(height: 20),
            Text(
              'Check-Out Successful',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Timestamp: $formattedDate',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Employee ID: $empid',
              style: TextStyle(fontSize: 18),
            ),
            if (checkOutNotice != null)
              Text(
                'Check-Out Notice: $checkOutNotice',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            if (checkOutLocation != null)
              Text(
                'Location: $checkOutLocation',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text('Back to Scan Choosing Page'),
            ),
          ],
        ),
      ),
    );
  }
}
