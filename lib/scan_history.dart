import 'package:flutter/material.dart';
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
        future: _fetchScanHistory(),
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
                      record.placeName,
                      style: const TextStyle(
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
                            title: const Text('Scan Details'),
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

  Future<List<ScanRecord>> _fetchScanHistory() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    List<ScanRecord> scanRecords = [];

    if (user != null) {
      // Fetch user details
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      if (userResponse.error == null) {
        final userData = userResponse.data as Map<String, dynamic>;
        String userId = userData['userId'] ?? 'Unknown';
        String name = userData['name'] ?? 'Unknown';

        // Fetch scan records
        final scanResponse = await supabase
            .from('scans')
            .select()
            .eq('user_id', user.id)
            .order('scanDate', ascending: false);

        if (scanResponse.error == null) {
          final scanData = scanResponse.data as List<dynamic>;

          scanRecords = scanData.map((doc) {
            return ScanRecord(
              placeName: doc['placeName'],
              scanDate: doc['scanDate'],
              latitude: doc['latitude'],
              longitude: doc['longitude'],
              userId: userId,
              name: name,
            );
          }).toList();
        } else {
          print("Failed to fetch scan records: ${scanResponse.error!.message}");
        }
      } else {
        print("Failed to fetch user details: ${userResponse.error!.message}");
      }
    }

    return scanRecords;
  }
}

extension on PostgrestList {
  get error => null;
  
  get data => null;
}

extension on PostgrestMap {
  get error => null;
  
  get data => null;
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
