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
                  child: ListTile(
                    title: Text(
                      record.placeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                        'Date: ${record.scanDate}\nLat: ${record.latitude.toStringAsFixed(5)}, Long: ${record.longitude.toStringAsFixed(5)}'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Scan Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Place: ${record.placeName}'),
                                Text('Date: ${record.scanDate}'),
                                Text('Latitude: ${record.latitude}'),
                                Text('Longitude: ${record.longitude}'),
                                Text('User ID: ${record.userId}'),
                                Text('Name: ${record.name}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
      // Fetch user details
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userId = userDoc['userId'] ?? 'Unknown';
      String name = userDoc['name'] ?? 'Unknown';

      // Fetch scan records
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
          userId: userId,
          name: name,
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
  final String userId;
  final String name;

  ScanRecord({
    required this.placeName,
    required this.scanDate,
    required this.latitude,
    required this.longitude,
    required this.userId,
    required this.name,
  });
}
