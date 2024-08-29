import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScanHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History'),
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _fetchScanHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No scan history found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                ScanRecord record = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.placeName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 8),
                            Text(
                              record.scanDate,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_pin, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Latitude: ${record.latitude.toStringAsFixed(5)}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_pin, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Longitude: ${record.longitude.toStringAsFixed(5)}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<ScanRecord>> _fetchScanHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    List<ScanRecord> scanRecords = [];

    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .orderBy('scanDate', descending: true)
          .get();

      scanRecords = snapshot.docs.map((doc) {
        return ScanRecord(
          placeName: doc['placeName'],
          scanDate: doc['scanDate'],
          latitude: doc['latitude'],
          longitude: doc['longitude'],
        );
      }).toList();
    }

    return scanRecords;
  }
}

class ScanRecord {
  final String placeName;
  final String scanDate;
  final double latitude;
  final double longitude;

  ScanRecord({
    required this.placeName,
    required this.scanDate,
    required this.latitude,
    required this.longitude,
  });
}
