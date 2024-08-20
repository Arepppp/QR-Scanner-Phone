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

  // Map the QR code contents to their respective place names
  final Map<String, String> qrCodePlaceMap = {
    "Canteen PG": "Canteen PG", 
    "Canteen Langsat": "Canteen Langsat",
  };

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                if (placeName.isNotEmpty)
                  Text(
                    "Place: $placeName",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
              ],
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
    setState(() {
      result = scanData.code ?? "No code found";
      placeName = qrCodePlaceMap[result] ?? "Unknown Place";

      // Include location info if available
      if (userLocation != null) {
        result += "\nLocation: Lat ${userLocation.latitude}, Long ${userLocation.longitude}";
      }
    });
  });
}


  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }
}