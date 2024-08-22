import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final scanResult = scanData.code ?? "No code found";
      final placeName = qrCodePlaceMap[scanResult] ?? "Unknown Place";

      if (userLocation != null) {
        double userLatitude = userLocation.latitude!;
        double userLongitude = userLocation.longitude!;

       // Example coordinates for Canteen PG
        double minLatitude = 1.444482; // Replace with actual values
        double maxLatitude = 1.44747;  // Replace with actual values
        double minLongitude = 103.89266; // Replace with actual values
        double maxLongitude = 103.896326; // Replace with actual values

        if (userLatitude >= minLatitude &&
            userLatitude <= maxLatitude &&
            userLongitude >= minLongitude &&
            userLongitude <= maxLongitude) {
          // Location is valid
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
          // Location is invalid
          _stopScanning(); // Stop scanning after an unsuccessful scan
          _navigateToScanFailedPage(
              context, "Scanning failed: Out of allowed area");
        }
      } else {
        // Handle location not found
        _stopScanning(); // Stop scanning after an unsuccessful scan
        _navigateToScanFailedPage(
            context, "Scanning failed: Location not found");
      }
    });
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
    qrController?.pauseCamera(); // Pause the camera after a successful scan
  }

  void _takeSnapshot() async {
    // Pause scanning to take a snapshot
    await qrController?.pauseCamera();

    // Implement actual snapshot functionality if needed
    // This might involve using a different package like `camera` to capture an image.

    // Resume scanning after taking a snapshot (if required)
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

  void didChangeDependencies() {
    super.didChangeDependencies();
    qrController
        ?.resumeCamera(); // Resume scanning when the user returns to this page
  }
}
