// live_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';

class LiveMap extends StatefulWidget {
  const LiveMap({super.key});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  LatLng _currentPosition = const LatLng(28.6139, 77.2090); // Default Delhi
  Timer? _timer;
  final MapController _mapController = MapController();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initLocationFlow(); // ask permission first, then start updates
  }

  Future<void> _initLocationFlow() async {
    // 1) Ensure location services are on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Try to prompt the user to enable location services (Android shows a system dialog)
      await Geolocator.openLocationSettings();
      // Re-check
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
    }

    // 2) Request permission if needed
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permission not granted, keep _hasPermission = false
        return;
      }
    }

    setState(() => _hasPermission = true);

    // 3) Get initial fix and start 2s updates
    await _updateLocation(moveMap: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateLocation(moveMap: false);
    });
  }

  Future<void> _updateLocation({bool moveMap = false}) async {
    if (!_hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(position.latitude, position.longitude);

      // Avoid rebuilding/moving if no significant change
      final d = const Distance();
      final meters = d.as(LengthUnit.Meter, _currentPosition, target);
      final movedEnough = meters > 1.0; // update when moved >1m

      if (movedEnough || moveMap) {
        setState(() => _currentPosition = target);
        if (moveMap) {
          _mapController.move(target, 18.0);
        }
      }
    } catch (_) {
      // Swallow errors; can log if needed
    }
  }

  Future<void> _centerOnMe() async {
    if (!_hasPermission) {
      await _initLocationFlow();
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = target);
      _mapController.move(target, 18.0);
    } catch (_) {}
  }

  Future<void> _shareLocationWhatsApp() async {
    final lat = _currentPosition.latitude;
    final lng = _currentPosition.longitude;

    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final text = Uri.encodeComponent('My location: $mapsUrl');

    final waUrl = 'https://api.whatsapp.com/send?text=$text';

    await launchUrlString(
      waUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey,
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(center: _currentPosition, zoom: 15),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _currentPosition,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // Right-bottom: center-on-me
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              onPressed: _centerOnMe,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // Left-bottom: share to WhatsApp
          Positioned(
            left: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'share_whatsapp',
              onPressed: _shareLocationWhatsApp,
              backgroundColor: Colors.white,
              child: Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
              tooltip: 'Share via WhatsApp',
            ),
          ),
        ],
      ),
    );
  }
}