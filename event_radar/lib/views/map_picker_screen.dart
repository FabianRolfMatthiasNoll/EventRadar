import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/providers/location_provider.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late CameraPosition _initialPosition;
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    final currentPosition =
        Provider.of<LocationProvider>(context, listen: false).currentPosition;
    _initialPosition = CameraPosition(
      target: currentPosition != null
          ? LatLng(currentPosition.latitude, currentPosition.longitude)
          : const LatLng(52.5200, 13.4050), // fallback
      zoom: currentPosition != null ? 15.0 : 12.0,
    );
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _pickedLocation = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ort auswählen'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onTap: _onMapTap,
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
