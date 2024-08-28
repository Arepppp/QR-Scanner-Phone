import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'result_page.dart';
import 'scan_failed_page.dart';

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
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
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

    controller.scannedDataStream.listen((scanData) {
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

        if (userLatitude >= minLatitude &&
            userLatitude <= maxLatitude &&
            userLongitude >= minLongitude &&
            userLongitude <= maxLongitude) {
          // Save the scan to Firestore
          _saveScanToFirestore(placeName, userLatitude, userLongitude);

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
              context, "Scanning failed: Out of allowed area");
        }
      } else {
        _stopScanning();
        _navigateToScanFailedPage(
            context, "Scanning failed: Location not found");
      }
    });
  }

  void _saveScanToFirestore(
      String placeName, double latitude, double longitude) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userID = user.uid;
      String scanDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('scans')
          .add({
            'placeName': placeName,
            'scanDate': scanDate,
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

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
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
