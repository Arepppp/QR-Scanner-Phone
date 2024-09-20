import 'package:flutter/material.dart';
import 'result_page_3_0.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'result_page_2_0.dart'; // Update with actual file name
import 'scan_failed_page_2_0.dart'; // Update with actual file name
import 'login.dart'; // Update with actual file name
import 'attendance_history.dart';

class AttendanceScanningPage extends StatefulWidget {
  @override
  _AttendanceScanningPageState createState() => _AttendanceScanningPageState();
}

class _AttendanceScanningPageState extends State<AttendanceScanningPage> {
  final GlobalKey qrKey = GlobalKey();
  QRViewController? qrController;
  bool isScanningPaused = false;
  String? action; // "check-in" or "check-out"

  // Add a debounce variable
  bool _isScanningAllowed = true; // Variable to control scan debouncing
  final Duration _debounceDuration =
      Duration(seconds: 5); // Set the debounce duration

  @override
  void initState() {
    super.initState();
    // Initialize Supabase and any other setups
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Scanning'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'attendance_history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttendanceHistoryPage(), // Navigate to attendance history page
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (BuildContext context) {
              return {'attendance_history', 'logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice == 'attendance_history' ? 'Attendance History' : 'Logout'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: action == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          action = 'check-in';
                        });
                        _startScanning();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(200, 60),
                        elevation: 5,
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.greenAccent;
                            }
                            return Colors.green;
                          },
                        ),
                      ),
                      child: Text('Check In'),
                    ),
                  ),
                  SizedBox(height: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          action = 'check-out';
                        });
                        _startScanning();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(200, 60),
                        elevation: 5,
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.redAccent;
                            }
                            return Colors.red;
                          },
                        ),
                      ),
                      child: Text('Check Out'),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: isScanningPaused
                        ? ElevatedButton(
                            onPressed: _resumeScanning,
                            child: Text('Resume Scanning'),
                          )
                        : Text('Scanning...'),
                  ),
                ),
              ],
            ),
    );
  }

  void _startScanning() {
    setState(() {
      action = action; // Maintain current action
    });
  }

  void _onQRViewCreated(QRViewController controller) async {
    qrController = controller;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('empid');

    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanningAllowed) return; // Ignore scans if not allowed

      _isScanningAllowed = false; // Disable further scans
      final scanResult = scanData.code ?? "No code found";
      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // Check if valid location and other conditions
      bool isValidLocation = await _checkValidLocation();

      if (isValidLocation) {
        if (action == 'check-in') {
          bool hasCheckedIn = await _hasCheckedIn(empid!, formattedDate);

          if (!hasCheckedIn) {
            bool isLate = now.hour > 8 || (now.hour == 8 && now.minute > 30);
            String checkInNotice = isLate ? 'Late In' : 'On Time';

            // Proceed with saving the attendance
            await _saveAttendance(
              empid,
              formattedDate,
              now,
              checkInNotice,
              scanResult,
            );

            // Navigate to ResultPage2_0
            _navigateToResultPage(
              context,
              true, // For check-in
              now, // timestamp
              empid: empid,
              checkInNotice: checkInNotice,
              checkInLocation:
                  scanResult, // Assuming scanResult is used as location
            );
          } else {
            DateTime checkInTime = await _getCheckInTime(empid, formattedDate);
            _showMessage("Already checked in at ${checkInTime}.");
          }
        } else if (action == 'check-out') {
          bool hasCheckedIn = await _hasCheckedIn(empid!, formattedDate);
          if (hasCheckedIn) {
            bool hasCheckedOut = await _hasCheckedOut(empid, formattedDate);
            if (!hasCheckedOut) {
              // Determine checkOutNotice based on check-out time
              bool isEarlyOut =
                  now.hour < 17 || (now.hour == 17 && now.minute < 30);
              String checkOutNotice = isEarlyOut ? 'Early Out' : 'On Time';

              await _saveAttendance2(
                empid,
                formattedDate,
                now,
                checkOutNotice,
                scanResult,
              );

              _navigateToResultPage(
                context,
                false, // For check-out
                now, // timestamp
                empid: empid,
                checkOutNotice: checkOutNotice,
                checkOutLocation:
                    scanResult, // Assuming scanResult is used as location
              );
            } else {
              DateTime checkOutTime =
                  await _getCheckOutTime(empid, formattedDate);
              _showMessage("Already checked out at ${checkOutTime}.");
            }
          } else {
            _showMessage("Please check in before checking out.");
          }
        }
      } else {
        _navigateToScanFailedPage(context, "Invalid location");
      }

      // After processing the scan, set a timer to re-enable scanning
      Future.delayed(_debounceDuration, () {
        _isScanningAllowed =
            true; // Allow scanning again after the debounce period
      });

      // Pause the scanner to prevent rapid scanning
      _stopScanning();
    });
  }

  Future<void> _saveAttendance(String empid, String date, DateTime? checkInTime,
      String? checkInNotice, String checkinlocation) async {
    await Supabase.instance.client.from('attendance').upsert({
      'empid': empid,
      'date': date,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_in_notice': checkInNotice,
      'check_in_location': checkinlocation,
      // Add other fields if necessary
    });
  }

  Future<void> _saveAttendance2(
      String empid,
      String date,
      DateTime? checkOutTime,
      String? checkOutNotice,
      String checkoutlocation) async {
    await Supabase.instance.client
        .from('attendance')
        .update({
          'check_out_time': checkOutTime?.toIso8601String(),
          'check_out_notice': checkOutNotice,
          'check_out_location': checkoutlocation,
          // Add other fields if necessary
        })
        .eq('empid', empid)
        .eq('date', date);
  }

  Future<void> _showMessage(String message) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Info'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkValidLocation() async {
    // Your location checking logic
    return true; // Placeholder
  }

  Future<DateTime> _getCheckInTime(String empid, String date) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('attendance')
          .select('check_in_time')
          .eq('empid', empid)
          .eq('date', date)
          .single();
      return DateTime.parse(response['check_in_time']);
    } catch (e) {
      print('Error fetching check-in time: $e');
      return DateTime.now();
    }
  }

  Future<DateTime> _getCheckOutTime(String empid, String date) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('attendance')
          .select('check_out_time')
          .eq('empid', empid)
          .eq('date', date)
          .single();
      return DateTime.parse(response['check_out_time']);
    } catch (e) {
      print('Error fetching check-out time: $e');
      return DateTime.now();
    }
  }

  Future<bool> _hasCheckedIn(String empid, String date) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .eq('empid', empid)
          .eq('date', date)
          .single();

      return response != null && response['check_in_time'] != null;
    } catch (e) {
      print('Error checking attendance: $e');
      return false;
    }
  }

  Future<bool> _hasCheckedOut(String empid, String date) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .eq('empid', empid)
          .eq('date', date)
          .single();

      return response != null && response['check_out_time'] != null;
    } catch (e) {
      print('Error checking attendance: $e');
      return false;
    }
  }

  void _navigateToResultPage(
      BuildContext context, bool isCheckIn, DateTime timestamp,
      {String? empid,
      String? checkInNotice,
      String? checkOutNotice,
      String? checkInLocation,
      String? checkOutLocation}) {
    if (isCheckIn) {
      // Navigate to ResultPage2_0 for check-in
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage2_0(
            timestamp: timestamp,
            empid: empid!,
            checkInNotice: checkInNotice,
            checkInLocation: checkInLocation,
          ),
        ),
      );
    } else {
      // Navigate to ResultPage3_0 for check-out
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage3_0(
            timestamp: timestamp,
            empid: empid!,
            checkOutNotice: checkOutNotice,
            checkOutLocation: checkOutLocation,
          ),
        ),
      );
    }
  }

  void _navigateToScanFailedPage(BuildContext context, String errorMessage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanFailedPage2_0(errorMessage: errorMessage),
      ),
    );
  }

  void _stopScanning() {
    qrController?.pauseCamera();
    setState(() {
      isScanningPaused = true;
    });
  }

  Future<void> _resumeScanning() async {
    await qrController?.resumeCamera();
    setState(() {
      isScanningPaused = false;
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logoutAndRedirect();
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _logoutAndRedirect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('empid');
    await prefs.setBool('isAuthenticated', false);

    // Log the values to ensure they are cleared
    print('empid removed: ${prefs.getString('empid')}');
    print('isAuthenticated set to false: ${prefs.getBool('isAuthenticated')}');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage(initialized: false)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isScanningPaused) {
      qrController?.resumeCamera();
    }
  }
}
