import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  String placeName = "";
  bool isScanningPaused = false;
  int frameCount = 0;

  final Map<String, String> qrCodePlaceMap = {
    "Canteen PG": "Canteen PG",
    "Canteen Langsat": "Canteen Langsat",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, '/login');
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
      final placeName = qrCodePlaceMap[scanResult] ?? "Unknown Place";

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
          // Breakfast time check: 6:00 AM - 8:30 AM
          if ((currentHour == 6) ||
              (currentHour == 7) ||
              (currentHour == 8 && currentMinute <= 30)) {
            _saveScanToSupabase(placeName, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Breakfast');

            // Stop scanning and navigate to result page
            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placeName: placeName,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealScanned: 'Breakfast',
                ),
              ),
            );
          }
          // Lunch time check: 11:30 AM - 2:00 PM
          else if ((currentHour == 11 && currentMinute >= 30) ||
              (currentHour == 12) ||
              (currentHour == 13) ||
              (currentHour == 14 && currentMinute == 0)) {
            _saveScanToSupabase(placeName, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Lunch');

            // Stop scanning and navigate to result page
            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placeName: placeName,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealScanned: 'Lunch',
                ),
              ),
            );
          }
          // Dinner time check: 6:00 PM - 7:00 PM
          else if ((currentHour == 18) ||
              (currentHour == 19 && currentMinute == 0)) {
            _saveScanToSupabase(placeName, formattedDate, formattedTime,
                userLatitude, userLongitude, 'Dinner');

            // Stop scanning and navigate to result page
            _stopScanning();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  result: scanResult,
                  placeName: placeName,
                  latitude: userLatitude,
                  longitude: userLongitude,
                  mealScanned: 'Dinner',
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

  // Initialize Supabase
  final supabase = Supabase.instance.client;

  void _saveScanToSupabase(String placeName, String date, String time,
      double latitude, double longitude, String mealScanned) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      String userID = user.id;

      final response = await supabase.from('scans').insert({
        'user_id': userID,
        'placeName': placeName,
        'scanDate': date,
        'scanTime': time,
        'latitude': latitude,
        'longitude': longitude,
        'mealScanned': mealScanned,
      });

      if (response.error != null) {
        print("Failed to save scan data: ${response.error!.message}");
      } else {
        print("Scan data saved");
      }
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
