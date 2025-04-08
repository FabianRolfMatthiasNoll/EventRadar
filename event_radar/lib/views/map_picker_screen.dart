import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late CameraPosition _initialPosition;
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Random Fallback value wenn man GPS nicht aktivieren will
      _initialPosition = const CameraPosition(
        target: LatLng(52.5200, 13.4050),
        zoom: 12,
      );
      _loading = false;
      setState(() {});
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _initialPosition = const CameraPosition(
          target: LatLng(52.5200, 13.4050),
          zoom: 12,
        );
        _loading = false;
        setState(() {});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _initialPosition = const CameraPosition(
        target: LatLng(52.5200, 13.4050),
        zoom: 12,
      );
      _loading = false;
      setState(() {});
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    _initialPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    );
    _loading = false;
    setState(() {});
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ort auswählen'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onTap: _onMapTap,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _pickedLocation != null
                ? {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _pickedLocation!,
              ),
            }
                : {},
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _pickedLocation == null
                  ? null
                  : () {
                Navigator.pop(context, _pickedLocation);
              },
              child: const Text('Auswahl bestätigen'),
            ),
          ),
        ],
      ),
    );
  }
}
