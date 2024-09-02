import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'result_page.dart';
import 'scan_failed_page.dart';
import 'scan_history.dart';

class HomePage extends StatefulWidget {
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
        title: Text('Home Page'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu),
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
                PopupMenuItem<String>(
                  value: 'Scan History',
                  child: Text('Scan History'),
                ),
                PopupMenuItem<String>(
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
              style: TextStyle(
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
                  child: Text('Resume Scanning'),
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
                child: Text('Take Snapshot'),
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
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
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

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        _navigateToScanFailedPage(
            context, "Scanning failed: Location services disabled");
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
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

        if (isValidLocation && (currentHour >= 8 && currentHour < 10)) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(now);
          String formattedTime = DateFormat('HH:mm:ss').format(now);

          // Save the scan to Firestore
          _saveScanToFirestore(placeName, formattedDate, formattedTime, userLatitude, userLongitude);

          // Stop scanning and navigate to result page
          _stopScanning(); // Stop scanning after a successful scan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                result: scanResult,
                placeName: placeName,
                latitude: userLatitude,
                longitude: userLongitude,
              ),
            ),
          );
        } else {
          _stopScanning();
          _navigateToScanFailedPage(
              context, isValidLocation ? 'Outside valid time range' : 'Outside valid location');
        }
      } else {
        _stopScanning();
        _navigateToScanFailedPage(
            context, "Scanning failed: Location not found");
      }
    });
  }

  void _saveScanToFirestore(
      String placeName, String date, String time, double latitude, double longitude) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userID = user.uid;

      FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('scans')
          .add({
            'placeName': placeName,
            'scanDate': date,
            'scanTime': time,
            'latitude': latitude,
            'longitude': longitude,
          })
          .then((value) => print("Scan data saved"))
          .catchError((error) => print("Failed to save scan data: $error"));
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
