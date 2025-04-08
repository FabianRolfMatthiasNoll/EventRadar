import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class StaticMapSnippet extends StatelessWidget {
  final LatLng location;
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final int width;
  final int height;
  final int zoom;

  StaticMapSnippet({
    super.key,
    required this.location,
    this.width = 600,
    this.height = 300,
    this.zoom = 15,
  });

  @override
  Widget build(BuildContext context) {
    final url =
        'https://maps.googleapis.com/maps/api/staticmap?center=${location.latitude},${location.longitude}'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=color:red%7Clabel:A%7C${location.latitude},${location.longitude}'
        '&key=$apiKey';

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Text("Map snippet unavailable"));
      },
    );
  }
}
