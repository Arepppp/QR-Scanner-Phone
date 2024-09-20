import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _fetchAttendanceHistory(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance history found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final record = snapshot.data![index];
                return ExpansionTile(
                  title: Text('Date: ${record.date}'),
                  subtitle: Text('Check In: ${record.checkInTime}'),
                  children: [
                    ListTile(
                      title: const Text('Check Out'),
                      subtitle: Text(record.checkOutTime),
                    ),
                    ListTile(
                      title: const Text('Location In'),
                      subtitle: Text(record.checkInLocation),
                    ),
                    ListTile(
                      title: const Text('Location Out'),
                      subtitle: Text(record.checkOutLocation),
                    ),
                    ListTile(
                      title: const Text('Notice'),
                      subtitle: Text(record.notice.isNotEmpty ? record.notice : 'N/A'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<AttendanceRecord>> _fetchAttendanceHistory(BuildContext context) async {
    final supabase = Supabase.instance.client;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('empid');

    List<AttendanceRecord> attendanceRecords = [];

    if (empid != null) {
      // Fetch attendance records
      final attendanceResponse = await supabase
          .from('attendance')
          .select()
          .eq('empid', empid)
          .order('date', ascending: false);

      final attendanceData = attendanceResponse as List<dynamic>;

      attendanceRecords = attendanceData.map((doc) {
        return AttendanceRecord(
          date: doc['date'],
          checkInTime: doc['check_in_time'] != null ? DateTime.parse(doc['check_in_time']).toLocal().toString() : 'Not Checked In',
          checkOutTime: doc['check_out_time'] != null ? DateTime.parse(doc['check_out_time']).toLocal().toString() : 'Not Checked Out',
          checkInLocation: doc['check_in_location'] ?? 'N/A',
          checkOutLocation: doc['check_out_location'] ?? 'N/A',
          notice: _getNotice(doc),
        );
      }).toList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Employee ID not found in SharedPreferences.")),
      );
    }

    return attendanceRecords;
  }

  String _getNotice(Map<String, dynamic> doc) {
    // Logic for determining notice based on conditions
    bool lateCheckIn = (doc['check_in_time'] != null && DateTime.parse(doc['check_in_time']).isAfter(DateTime.parse('${doc['date']} 08:30:00')));
    bool earlyCheckOut = (doc['check_out_time'] != null && DateTime.parse(doc['check_out_time']).isBefore(DateTime.parse('${doc['date']} 17:30:00')));

    if (lateCheckIn && earlyCheckOut) return 'Late In / Early Out';
    if (lateCheckIn) return 'Late In';
    if (earlyCheckOut) return 'Early Out';
    return '';
  }
}

class AttendanceRecord {
  final String date;
  final String checkInTime;
  final String checkOutTime;
  final String checkInLocation;
  final String checkOutLocation;
  final String notice;

  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInLocation,
    required this.checkOutLocation,
    required this.notice,
  });
}