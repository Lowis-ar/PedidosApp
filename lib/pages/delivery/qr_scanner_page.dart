import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pedidosapp/utils/colors.dart';

/// Página fullscreen para escanear un código QR.
/// Devuelve el valor escaneado (String) al hacer pop, o null si se canceló.
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty) {
      _scanned = true;
      _scannerController.stop();
      Get.back(result: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear código QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Linterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista de cámara
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Overlay con guía visual
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Marco con esquinas decorativas
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.mainColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: _buildCorners(),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Apunta la cámara al QR del cliente',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double size = 26;
    const double thickness = 4;
    const Color color = Colors.white;
    return [
      Positioned(top: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
    ];
  }
}
