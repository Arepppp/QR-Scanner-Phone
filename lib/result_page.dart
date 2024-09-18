import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultPage extends StatelessWidget {
  final String result;
  final String placename;
  final double? latitude;
  final double? longitude;
  final String mealscanned; // New parameter for mealscanned
  final String? empid; // empid is required

  const ResultPage({
    super.key,
    required this.result,
    required this.placename,
    this.latitude,
    this.longitude,
    required this.mealscanned,
    required this.empid, // Initialize empid
  });

  Future<Map<String, String?>> _fetchEmployeeDetails(String empId) async {
    final response = await Supabase.instance.client
        .from('employees')
        .select('name')
        .eq('empid', empId)
        .single();

    final data = response;
    return {'name': data['name'] as String?};
  }

  @override
  Widget build(BuildContext context) {
    // Get the current date and time
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final formattedTime = DateFormat('HH:mm:ss').format(now);

    return FutureBuilder<Map<String, String?>>(
      future: _fetchEmployeeDetails(empid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error fetching employee details.'));
        } else {
          final name = snapshot.data!['name'] ?? 'Unknown Name';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Scan Result'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan Successful!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Result: $result',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (placename.isNotEmpty)
                      Text(
                        'Place: $placename',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Date: $formattedDate',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Time: $formattedTime',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Location: Lat: $latitude, Long: $longitude',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Employee ID: $empid',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Employee Name: $name',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Meal Scanned: $mealscanned',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
