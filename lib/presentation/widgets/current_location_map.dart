import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CurrentLocationMap extends StatefulWidget {
  const CurrentLocationMap({super.key});

  @override
  State<CurrentLocationMap> createState() => _CurrentLocationMapState();
}

class _CurrentLocationMapState extends State<CurrentLocationMap> {
  Position? _position;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          setState(() {
            _error = 'Could not get your location';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not get your location';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(Icons.my_location, color: Colors.red[700], size: 18),
                const SizedBox(width: 6),
                const Text('Your current location',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadLocation,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                child: Text(_error!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)))
                : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_position!.latitude, _position!.longitude),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.teyzixcore.smart_blood_donor_network',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_position!.latitude, _position!.longitude),
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_pin, color: Colors.red[700], size: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}