import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A single plant location on the map.
class PlantSite {
  final String name;
  final LatLng position;
  final bool active;
  const PlantSite({required this.name, required this.position, this.active = true});
}

/// Known real coordinates for the Trackso sites (Bawal, Haryana). Matched by
/// name so the dashboard can place markers without a schema change.
LatLng? plantCoordinatesFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('hollister') || n.contains('alpha')) {
    return const LatLng(28.0965752, 76.6055277);
  }
  if (n.contains('caparo') || n.contains('beta')) {
    return const LatLng(28.0902152, 76.5808786);
  }
  return null;
}

const _teal = Color(0xFF2A8C6E);

/// Esri World Imagery — free satellite tiles, no API key required.
TileLayer _satelliteTiles() => TileLayer(
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.enercore.app',
      maxZoom: 19,
    );

List<Marker> _markers(List<PlantSite> sites, {double size = 44}) {
  return sites
      .map((s) => Marker(
            point: s.position,
            width: size,
            height: size,
            alignment: Alignment.topCenter,
            child: _PinMarker(active: s.active),
          ))
      .toList();
}

class _PinMarker extends StatelessWidget {
  final bool active;
  const _PinMarker({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? _teal : const Color(0xFFEF4444);
    return Icon(Icons.location_on, color: color, size: 40);
  }
}

LatLng _center(List<PlantSite> sites) {
  if (sites.isEmpty) return const LatLng(28.093, 76.593); // Bawal
  double lat = 0, lng = 0;
  for (final s in sites) {
    lat += s.position.latitude;
    lng += s.position.longitude;
  }
  return LatLng(lat / sites.length, lng / sites.length);
}

/// Compact, tappable satellite preview shown inside the dashboard card.
class PlantMapPreview extends StatelessWidget {
  final List<PlantSite> sites;
  final VoidCallback onTap;
  const PlantMapPreview({super.key, required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center(sites),
                  initialZoom: 12,
                  // Preview is non-interactive; tap opens the full map.
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  _satelliteTiles(),
                  MarkerLayer(markers: _markers(sites)),
                ],
              ),
              // "Tap to expand" affordance
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.open_in_full_rounded, size: 16, color: _slateDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _slateDark = Color(0xFF1E293B);

/// Full-screen interactive satellite map with zoom/pan and a Close button.
class PlantMapFullScreen extends StatefulWidget {
  final List<PlantSite> sites;
  const PlantMapFullScreen({super.key, required this.sites});

  @override
  State<PlantMapFullScreen> createState() => _PlantMapFullScreenState();
}

class _PlantMapFullScreenState extends State<PlantMapFullScreen> {
  final _controller = MapController();

  void _zoom(double delta) {
    final z = (_controller.camera.zoom + delta).clamp(3.0, 19.0);
    _controller.move(_controller.camera.center, z);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _center(widget.sites),
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              _satelliteTiles(),
              MarkerLayer(markers: _markers(widget.sites, size: 48)),
            ],
          ),
          // Site labels overlay (top)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Text('Sites Map View',
                        style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  _circleBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
          // Zoom controls (bottom-right)
          Positioned(
            right: 14,
            bottom: 30,
            child: Column(
              children: [
                _circleBtn(Icons.add_rounded, () => _zoom(1)),
                const SizedBox(height: 10),
                _circleBtn(Icons.remove_rounded, () => _zoom(-1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Icon(icon, color: _slateDark, size: 22),
        ),
      );
}
