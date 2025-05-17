import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:event_radar/widgets/avatar_or_placeholder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/models/event.dart';
import '../core/providers/location_provider.dart';
import '../core/viewmodels/event_map_viewmodel.dart';

class EventMapScreen extends StatefulWidget {
  const EventMapScreen({super.key});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  Set<Marker> _markers = {};
  Map<String, LatLng> _clusterCenters = {}; // Cluster-Zentren
  Map<String, List<Event>> clusteredEvents = {};

  static const Map<int, double> zoomToClusterRadius = {
    17: 0.001,
    16: 0.005,
    15: 0.01,
    14: 0.1,
    13: 0.5,
    12: 1,
    11: 2.5,
    10: 5,
    9: 10,
    8: 15,
    7: 33,
    6: 66,
    5: 150,
    4: 300,
    3: 600,
  };
  Double? zoomState;
  Timer? _debounce;

  void _onCameraMove(CameraPosition position) {
    print(position.zoom);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateMarkers(
        context.read<EventMapViewModel>().events,
        context,
        position.zoom,
      );
    });
  }

  void _updateMarkers(
    List<Event> events,
    BuildContext context,
    double zoomLevel,
  ) async {
    clusteredEvents = {};
    _clusterCenters = {};

    for (var event in events) {
      _addEventToCluster(event, zoomLevel);
    }

    final List<Marker> newMarkerList = await Future.wait(
      clusteredEvents.entries.map((entry) async {
        final clusterKey = entry.key;
        final clusterEvents = entry.value;
        final clusterCenter = _clusterCenters[clusterKey]!;

        if (clusterEvents.length > 1) {
          final icon = await _createClusterIcon(clusterEvents.length);
          return Marker(
            markerId: MarkerId('cluster_$clusterKey'),
            position: clusterCenter,
            icon: icon,
            onTap: () => _showClusterDetails(context, clusterEvents),
          );
        } else {
          final event = clusterEvents.first;
          final user = FirebaseAuth.instance.currentUser;
          final uid = user?.uid;
          final isMember = uid != null && event.participants.contains(uid);
          final hue =
              isMember
                  ? BitmapDescriptor.hueGreen
                  : event.promoted
                  ? BitmapDescriptor.hueYellow
                  : BitmapDescriptor.hueBlue;

          return Marker(
            markerId: MarkerId(event.id ?? event.title),
            position: LatLng(event.location.latitude, event.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () => _showEventDetails(context, event),
          );
        }
      }),
    );

    if (mounted) {
      setState(() {
        _markers = newMarkerList.toSet();
      });
    }
  }

  void _addEventToCluster(Event event, double zoomLevel) {
    final eventPosition = LatLng(
      event.location.latitude,
      event.location.longitude,
    );
    String? closestClusterKey;
    var allDistances = [];
    double closestDistance = double.infinity;

    for (var entry in _clusterCenters.entries) {
      final clusterKey = entry.key;
      final clusterCenter = entry.value;
      final currentClusterRadius = getClusterRadius(zoomLevel);
      final distance = _calculateDistance(eventPosition, clusterCenter);
      allDistances.add(distance);
      if (distance < closestDistance && distance < currentClusterRadius!) {
        closestClusterKey = clusterKey;
        closestDistance = distance;
      }
    }
    if (closestClusterKey == null) {
      final newKey = event.id!;
      _clusterCenters[newKey] = eventPosition;
      clusteredEvents[newKey] = [event];
    } else {
      clusteredEvents[closestClusterKey]?.add(event);
    }
  }

  double? getClusterRadius(double zoomLevel) {
    int roundedZoomLevel = zoomLevel.round();
    int minZoomLevel = zoomToClusterRadius.keys.reduce((a, b) => a < b ? a : b);
    int maxZoomLevel = zoomToClusterRadius.keys.reduce((a, b) => a > b ? a : b);
    if (roundedZoomLevel > maxZoomLevel) {
      return zoomToClusterRadius.values.reduce(
        (a, b) => a > b ? a : b,
      ); // Max radius
    } else if (roundedZoomLevel < minZoomLevel) {
      return zoomToClusterRadius.values.reduce(
        (a, b) => a < b ? a : b,
      ); // Min radius
    }
    return zoomToClusterRadius[roundedZoomLevel]; // Normal case
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadiusKm = 6371.0;
    final lat1Rad = p1.latitude * (pi / 180);
    final lat2Rad = p2.latitude * (pi / 180);
    final deltaLat = (p2.latitude - p1.latitude) * (pi / 180);
    final deltaLon = (p2.longitude - p1.longitude) * (pi / 180);
    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<BitmapDescriptor> _createClusterIcon(int count) async {
    const size = 70.0;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size / 2, size / 2);

    // Schatten als separater Kreis (ohne .withOpacity)
    final shadowPaint =
        Paint()
          ..color = const Color.fromARGB(50, 0, 0, 0) // 50 = ca. 20% deckend
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(1.5, 2.5), size / 2.2, shadowPaint);

    // Dunkelroter Rand
    final borderPaint =
        Paint()
          ..color = const Color(0xFF7B1C1C)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 2.2, borderPaint);

    // Innerer Kreis mit Verlauf
    final fillPaint =
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, 0), Offset(size, size), [
            Colors.redAccent.shade200,
            Colors.red.shade800,
          ]);
    canvas.drawCircle(center, size / 2.2 - 2, fillPaint);

    // Weißer Mittelkreis
    const innerCircleRadius = 11.0;
    final whiteCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, innerCircleRadius, whiteCirclePaint);

    // Zahl
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Icon erzeugen
    final image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  void _showClusterDetails(BuildContext context, List<Event> events) {
    // Events in promoted und andere aufteilen
    final promotedEvents = events.where((e) => e.promoted == true).toList();
    final otherEvents = events.where((e) => e.promoted != true).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  if (promotedEvents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "✨ Promoted Events",
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ...promotedEvents.map(
                    (event) =>
                        _buildEventTile(context, event, isPromoted: true),
                  ),
                  if (otherEvents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Weitere Events",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ...otherEvents.map(
                    (event) => _buildEventTile(context, event),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    Event event, {
    bool isPromoted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPromoted ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isPromoted
                ? [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 212, 121),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
                : [],
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            AvatarOrPlaceholder(imageUrl: event.image, name: event.title),
            if (isPromoted)
              const Icon(Icons.star, color: Colors.amber, size: 18),
          ],
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPromoted ? Colors.orange[900] : null,
          ),
        ),
        subtitle: Text(
          event.description ?? "Keine Beschreibung vorhanden",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => context.push("/event-overview/${event.id}"),
      ),
    );
  }

  //show single event details in a dialog
  void _showEventDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: AvatarOrPlaceholder(
                    imageUrl: event.image,
                    name: event.title,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    event.description ?? "Keine Beschreibung vorhanden",
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push("/event-overview/${event.id}"),
                  child: const Text("Zum Event"),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPosition = Provider.of<LocationProvider>(context).currentPosition;
    if (userPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Consumer<EventMapViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userPosition.latitude, userPosition.longitude),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            onCameraMove: _onCameraMove,
          );
        },
      ),
    );
  }
}
