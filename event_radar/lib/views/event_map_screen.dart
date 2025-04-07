import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/viewmodels/event_map_viewmodel.dart';
import '../core/models/event.dart';
import '../core/utils/initials_helper.dart';

class EventMapScreen extends StatefulWidget {
  const EventMapScreen({Key? key}) : super(key: key);

  @override
  _EventMapScreenState createState() => _EventMapScreenState();
}

// TODO: Grouping of events when zoomed out with a number would be important

class _EventMapScreenState extends State<EventMapScreen> {
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

  Set<Marker> _createMarkers(List<Event> events) {
    return events.map((event) {
      final markerColor = event.promoted
          ? BitmapDescriptor.hueYellow
          : BitmapDescriptor.hueAzure;

      return Marker(
        markerId: MarkerId(event.title), // TODO: Change that to event ID
        position: LatLng(event.location.latitude, event.location.longitude),
        // TODO: Make a custom marker to have logo. If no logo is there then normal marker
        // TODO: Make custom cool markers for promoted events
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.description ?? '',
          onTap: () {
            _showEventDetails(event);
          },
        ),
      );
    }).toSet();
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: (event.image.isNotEmpty && event.image.startsWith('http'))
                      ? NetworkImage(event.image)
                      : null,
                  child: (event.image.isEmpty || !event.image.startsWith('http'))
                      ? Text(getInitials(event.title))
                      : null,
                ),
                title: Text(event.title),
                subtitle: Text(event.description ?? 'Keine Beschreibung'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Join Event needs to be implemented
                },
                child: const Text("Join Event"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<EventMapViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: _initialPosition,
            markers: _createMarkers(viewModel.events),
            myLocationEnabled: true,
            zoomControlsEnabled: true,
          );
        },
      ),
    );
  }
}
