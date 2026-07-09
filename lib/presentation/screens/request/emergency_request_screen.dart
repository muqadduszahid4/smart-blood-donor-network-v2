import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../data/models/request_model.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController(text: '1');
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedBloodGroup;
  bool _isFetchingLocation = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  Future<Position?> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enable location services')));
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not get location. Try again.')));
        }
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency blood request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emergency, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  const Text('Request blood urgently',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Nearby donors will be notified instantly',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                    labelText: 'Blood group needed', border: OutlineInputBorder()),
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBloodGroup = value),
                validator: (value) => value == null ? 'Select blood group' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Units required', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter units required';
                  final units = int.tryParse(value);
                  if (units == null || units < 1) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                    labelText: 'Hospital name', border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter hospital name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Your contact number',
                  hintText: 'e.g. 03001234567',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a contact number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Emergency notes (optional)',
                  hintText: 'e.g. Emergency surgery, patient critical',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              if (requestProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    requestProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                  onPressed: (requestProvider.isLoading || _isFetchingLocation)
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;

                    final position = await _getCurrentLocation();
                    if (position == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Location is required to submit a request')));
                      }
                      return;
                    }

                    final user = authProvider.currentUser;
                    if (user == null) return;

                    final request = RequestModel(
                      id: '',
                      requesterId: user.uid,
                      requesterName: user.displayName ?? user.email ?? 'Anonymous',
                      requesterPhone: _phoneController.text.trim(),
                      bloodGroup: _selectedBloodGroup!,
                      units: int.parse(_unitsController.text),
                      hospitalName: _hospitalController.text.trim(),
                      notes: _notesController.text.trim(),
                      latitude: position.latitude,
                      longitude: position.longitude,
                      status: 'pending',
                      createdAt: DateTime.now(),
                    );

                    bool success = await requestProvider.createRequest(request);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency request sent ✅')));
                      Navigator.pop(context);
                    }
                  },
                  label: (requestProvider.isLoading || _isFetchingLocation)
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send emergency request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}