import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class MapPinPickerView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPinPickerView({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPinPickerView> createState() => _MapPinPickerViewState();
}

class _MapPinPickerViewState extends State<MapPinPickerView> {
  late CameraPosition _initialPosition;
  LatLng _currentCameraPosition = const LatLng(0, 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentCameraPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _initialPosition = CameraPosition(target: _currentCameraPosition, zoom: 16);
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallback();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallback();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallback();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _currentCameraPosition = LatLng(position.latitude, position.longitude);
      _initialPosition = CameraPosition(target: _currentCameraPosition, zoom: 16);
    } catch (e) {
      _setFallback();
    }

    setState(() => _isLoading = false);
  }

  void _setFallback() {
    // Default fallback position
    _currentCameraPosition = const LatLng(14.6349, -90.5069); // Guatemala City approx
    _initialPosition = CameraPosition(target: _currentCameraPosition, zoom: 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fijar ubicación de entrega'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onCameraMove: (position) {
                    _currentCameraPosition = position.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                // Custom Pin in the center of the screen
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35.0),
                    child: Icon(Icons.location_on, size: 50, color: Colors.red),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Get.back(result: _currentCameraPosition);
                    },
                    child: const Text('Fijar Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
    );
  }
}
