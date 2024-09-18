import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'result_page.dart';
import 'scan_failed_page.dart';
import 'scan_history.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey qrKey = GlobalKey();
  QRViewController? qrController;
  String result = "Scan a QR code";
  String placename = "";
  bool isScanningPaused = false;
  int frameCount = 0;

  final Map<String, String> qrCodePlaceMap = {
    "Canteen Pasir Gudang": "Canteen Pasir Gudang",
    "Canteen Tanjung Langsat": "Canteen Tanjung Langsat",
  };

  @override
  void initState() {
    super.initState();
    checkUserSession(); // Check user session on init
    // Show initialization status using ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supabase = Supabase.instance.client;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supabase != null
                ? 'Supabase initialized successfully!'
                : 'Failed to initialize Supabase!',
          ),
          backgroundColor: supabase != null ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> checkUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    // If no valid session is found, redirect to login
    if (!isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Fetch empid from user metadata
    String? empid = prefs.getString('empid');

    // If empid is not available, handle the case
    if (empid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee ID not found in SharedPreferences"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Display a welcome message with empid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Welcome'),
            content: Text('Welcome, $empid!'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen Scan Page'),
        leading: null, // Remove the default back button
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'Scan History') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanHistoryPage()),
                );
              } else if (value == 'Logout') {
                _showLogoutConfirmation(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Scan History',
                  child: Text('Scan History'),
                ),
                const PopupMenuItem<String>(
                  value: 'Logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
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
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              'Frames: $frameCount',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          if (isScanningPaused)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _resumeScanning,
                  child: const Text('Resume Scanning'),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _takeSnapshot,
                child: const Text('Take Snapshot'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                // Clear session variable on Supabase server side
                try {
                  await Supabase.instance.client.rpc('reset_config', params: {
                    'key': 'myapp.user_id',
                  });
                } catch (e) {
                  // Handle potential errors when clearing session variable
                  print('Error clearing session variable: $e');
                }

                // Clear all stored preferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to login page and remove all previous routes from the stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(initialized: true),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) async {
    qrController = controller;

    Location location = Location();
    LocationData? userLocation;

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Fetch empid from user metadata
    String? empid = prefs.getString('empid');

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _navigateToScanFailedPage(
            context, "Scanning failed: Location services disabled");
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _navigateToScanFailedPage(
            context, "Scanning failed: Permission denied");
        return;
      }
    }

    userLocation = await location.getLocation();

    controller.scannedDataStream.listen((scanData) async {
      frameCount++; // Increment the frame count on each scan attempt

      final scanResult = scanData.code ?? "No code found";
      final placename = qrCodePlaceMap[scanResult] ?? "Unknown Place";

      if (userLocation != null) {
        double userLatitude = userLocation.latitude!;
        double userLongitude = userLocation.longitude!;

        double minLatitude = 1.444482;
        double maxLatitude = 1.44747;
        double minLongitude = 103.89266;
        double maxLongitude = 103.896326;

        bool isValidLocation = userLatitude >= minLatitude &&
            userLatitude <= maxLatitude &&
            userLongitude >= minLongitude &&
            userLongitude <= maxLongitude;

        DateTime now = DateTime.now();
        int currentHour = now.hour;
        int currentMinute = now.minute;
        String formattedDate = DateFormat('yyyy-MM-dd').format(now);
        String formattedTime = DateFormat('HH:mm:ss').format(now);

        if (isValidLocation) {
          if ((currentHour == 6) ||
              (currentHour == 7) ||
              (currentHour == 8 && currentMinute <= 30)) {
            _saveScanToSupabase(placename, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Breakfast');

            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placename: placename,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealscanned: 'Breakfast',
                  empid: empid ??
                      'Unknown ID', // Pass empid from SharedPreferences or default to 'Unknown ID'
                ),
              ),
            );
          } else if ((currentHour == 11 && currentMinute >= 30) ||
              (currentHour == 12) ||
              (currentHour == 13) ||
              (currentHour == 14)) {
            _saveScanToSupabase(placename, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Lunch');

            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placename: placename,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealscanned: 'Lunch',
                  empid: empid ??
                      'Unknown ID', // Pass empid from SharedPreferences or default to 'Unknown ID'
                ),
              ),
            );
          } else if ((currentHour == 18) ||
              (currentHour == 19 && currentMinute == 0)) {
            _saveScanToSupabase(placename, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Dinner');

            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placename: placename,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealscanned: 'Dinner',
                  empid: empid ??
                      'Unknown ID', // Pass empid from SharedPreferences or default to 'Unknown ID'
                ),
              ),
            );
          } else {
            _stopScanning();
            _navigateToScanFailedPage(context, 'Outside valid time range');
          }
        } else {
          _stopScanning();
          _navigateToScanFailedPage(context, 'Outside valid location');
        }
      } else {
        _stopScanning();
        _navigateToScanFailedPage(
            context, "Scanning failed: Location not found");
      }
    });
  }

  Future<bool> _hasMealAlreadyBeenScanned(
      String empid, String mealscanned, String formattedDate) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('scans')
          .select()
          .eq('empid', empid)
          .eq('mealscanned', mealscanned)
          .eq('date', formattedDate)
          .single();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No records found.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      } else {
        return true; // Returns true if a record exists
      }
    } catch (e) {
      print('Exception occurred while checking meal scan status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check meal scan status.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _saveScanToSupabase(String placename, String date, String time,
      double latitude, double longitude, String mealscanned) async {
    final supabase = Supabase.instance.client;

    // Debug: Check if Supabase is initialized
    if (supabase == null) {
      print('Supabase instance is not initialized.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Supabase instance is not initialized."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Retrieve empid from SharedPreferences or another source
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('empid');

    if (empid == null) {
      // Handle missing empid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee ID not found"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Construct DateTime object directly from date and time strings
    DateTime scanDateTime = DateTime.parse('$date $time');

    // Convert DateTime to ISO 8601 string
    String scanDateTimeStr = scanDateTime.toIso8601String();

// Check if the meal has already been scanned
    bool isMealScanned =
        await _hasMealAlreadyBeenScanned(empid, mealscanned, date);
    if (isMealScanned == true) {
      _navigateToScanFailedPage(
          context, 'The $mealscanned is already scanned.');
      return;
    } else {
      // Save scan data to Supabase

      await supabase.from('scans').insert({
        'empid': empid,
        'placename': placename,
        'scandate': scanDateTimeStr, // Use ISO 8601 string for timestamp
        'latitude': latitude,
        'longitude': longitude,
        'mealscanned': mealscanned,
        'date': date,
      });
    }
  }

  void _navigateToScanFailedPage(BuildContext context, String errorMessage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanFailedPage(errorMessage: errorMessage),
      ),
    );
  }

  void _stopScanning() {
    qrController?.pauseCamera();
    setState(() {
      isScanningPaused = true;
    });
  }

  void _resumeScanning() async {
    await qrController?.resumeCamera();
    setState(() {
      isScanningPaused = false;
    });
  }

  void _takeSnapshot() async {
    await qrController?.pauseCamera();

    // Implement actual snapshot functionality if needed

    await qrController?.resumeCamera();
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    qrController?.resumeCamera();
  }
}
