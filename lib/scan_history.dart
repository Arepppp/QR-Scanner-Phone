import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanHistoryPage extends StatelessWidget {
  const ScanHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _fetchScanHistory(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No scan history found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                ScanRecord record = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      record.placename,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                        'Date: ${record.scandate.toLocal()}\nLat: ${record.latitude.toStringAsFixed(5)}, Long: ${record.longitude.toStringAsFixed(5)}'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Scan Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Place: ${record.placename}'),
                                Text('Date: ${record.scandate.toLocal()}'),
                                Text('Latitude: ${record.latitude}'),
                                Text('Longitude: ${record.longitude}'),
                                Text('User ID: ${record.empid}'),
                                Text('Name: ${record.name}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
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

  Future<List<ScanRecord>> _fetchScanHistory(BuildContext context) async {
    final supabase = Supabase.instance.client;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('empid');

    List<ScanRecord> scanRecords = [];

    if (empid != null) {
      // Fetch user details
      final userResponse = await supabase
          .from('employees')
          .select()
          .eq('empid', empid)
          .single();

      final userData = userResponse as Map<String, dynamic>;
      String name = userData['name'] ?? 'Unknown';

      // Fetch scan records
      final scanResponse = await supabase
          .from('scans')
          .select()
          .eq('empid', empid)
          .order('scandate', ascending: false);

      final scanData = scanResponse as List<dynamic>;

      scanRecords = scanData.map((doc) {
        return ScanRecord(
          placename: doc['placename'] ?? 'Unknown',
          scandate: DateTime.parse(doc['scandate']),
          latitude: doc['latitude'] ?? 0.0,
          longitude: doc['longitude'] ?? 0.0,
          empid: empid,
          name: name,
        );
      }).toList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Employee ID not found in SharedPreferences.")),
      );
    }

    return scanRecords;
  }
}

class ScanRecord {
  final String placename;
  final DateTime scandate;
  final double latitude;
  final double longitude;
  final String empid;
  final String name;

  ScanRecord({
    required this.placename,
    required this.scandate,
    required this.latitude,
    required this.longitude,
    required this.empid,
    required this.name,
  });
}
