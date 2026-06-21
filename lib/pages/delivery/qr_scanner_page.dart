import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pedidosapp/utils/colors.dart';

/// Página fullscreen para escanear un código QR o ingresar OTP manualmente en Web.
/// Devuelve el valor escaneado o ingresado (String) al hacer pop, o null si se canceló.
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController? _scannerController;
  bool _scanned = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty) {
      _scanned = true;
      _scannerController?.stop();
      Get.back(result: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          title: const Text(
            'Confirmación de Entrega',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_rounded, size: 64, color: AppColors.mainColor),
                      const SizedBox(height: 20),
                      const Text(
                        'Código de Entrega',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Por favor, ingrese el código de entrega proporcionado por el cliente para completar el pedido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                        decoration: InputDecoration(
                          hintText: 'Código OTP',
                          hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0, fontSize: 18),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final code = _otpController.text.trim();
                            if (code.isNotEmpty) {
                              Get.back(result: code);
                            } else {
                              Get.snackbar(
                                'Aviso', 
                                'Por favor, ingrese el código de entrega.',
                                backgroundColor: Colors.orange.shade50,
                                colorText: Colors.black87,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirmar Entrega',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

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
            onPressed: () => _scannerController?.toggleTorch(),
            tooltip: 'Linterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista de cámara
          if (_scannerController != null)
            MobileScanner(
              controller: _scannerController!,
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
