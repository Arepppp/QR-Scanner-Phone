import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    userLocation = await location.getLocation();

    controller.scannedDataStream.listen((scanData) {
      final scanResult = scanData.code ?? "No code found";
      final placeName = qrCodePlaceMap[scanResult] ?? "Unknown Place";

      if (userLocation != null) {
        final locationInfo = "\nLocation: Lat ${userLocation.latitude}, Long ${userLocation.longitude}";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              result: scanResult + locationInfo,
              placeName: placeName,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              result: scanResult,
              placeName: placeName,
            ),
          ),
        );
      }
    });
  }

  void _takeSnapshot() {
    // Implement the snapshot feature here
    // For example, you could pause scanning, capture the current frame, and then process it.
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
}

class ResultPage extends StatelessWidget {
  final String result;
  final String placeName;

  ResultPage({required this.result, required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Result: $result',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Place: $placeName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
