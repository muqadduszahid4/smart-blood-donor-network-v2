import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/donor_model.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedGender;
  DateTime? _lastDonationDate;
  bool _isAvailable = true;
  bool _isMedicallyEligible = true;
  bool _isFetchingLocation = false;
  bool _isLoadingProfile = true;
  bool _hasExistingProfile = false;
  double? _existingLat;
  double? _existingLng;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      final donor = await donorProvider.fetchDonorProfile(user.uid);
      if (donor != null && mounted) {
        setState(() {
          _hasExistingProfile = true;
          _selectedBloodGroup = donor.bloodGroup;
          _ageController.text = donor.age.toString();
          _selectedGender = donor.gender;
          _cityController.text = donor.city;
          _phoneController.text = donor.phone;
          _lastDonationDate = donor.lastDonationDate;
          _isAvailable = donor.isAvailable;
          _isMedicallyEligible = donor.isMedicallyEligible;
          _existingLat = donor.latitude;
          _existingLng = donor.longitude;
        });
      }
    }
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<Position?> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enable location services in device settings')));
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location permission is required')));
          }
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission permanently denied. Enable it in app settings.')));
        }
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not get location. Try again outdoors or check GPS.')));
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete donor profile?'),
        content: const Text('This will remove you from the donor list. You can register again anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      bool success = await donorProvider.deleteDonorProfile(user.uid);
      if (success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Donor profile deleted')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context);

    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donor profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasExistingProfile ? 'Edit donor profile' : 'Become a donor'),
        actions: [
          if (_hasExistingProfile)
            IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_hasExistingProfile ? 'Update your details' : 'Donor details',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                    labelText: 'Blood group', border: OutlineInputBorder()),
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBloodGroup = value),
                validator: (value) => value == null ? 'Select blood group' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter your age';
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 65) {
                    return 'Age must be between 18 and 65';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Select gender' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Enter your city' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_lastDonationDate == null
                    ? 'Last donation date (optional)'
                    : 'Last donation: ${_lastDonationDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _lastDonationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _lastDonationDate = picked);
                },
              ),
              const Divider(),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available to donate now'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Medically eligible to donate'),
                value: _isMedicallyEligible,
                onChanged: (value) => setState(() => _isMedicallyEligible = value),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: donorProvider.isLoading || _isFetchingLocation
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;

                    double lat;
                    double lng;

                    if (_hasExistingProfile && _existingLat != null && _existingLng != null) {
                      lat = _existingLat!;
                      lng = _existingLng!;
                    } else {
                      final position = await _getCurrentLocation();
                      if (position == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Location is required to register')));
                        }
                        return;
                      }
                      lat = position.latitude;
                      lng = position.longitude;
                    }

                    final user = authProvider.currentUser;
                    if (user == null) return;

                    final donor = DonorModel(
                      uid: user.uid,
                      name: user.displayName ?? 'Donor',
                      bloodGroup: _selectedBloodGroup!,
                      age: int.parse(_ageController.text),
                      gender: _selectedGender!,
                      city: _cityController.text.trim(),
                      latitude: lat,
                      longitude: lng,
                      phone: _phoneController.text.trim(),
                      lastDonationDate: _lastDonationDate,
                      isAvailable: _isAvailable,
                      isMedicallyEligible: _isMedicallyEligible,
                      createdAt: DateTime.now(),
                    );

                    bool success = await donorProvider.registerDonor(donor);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(_hasExistingProfile
                              ? 'Donor profile updated ✅'
                              : 'Donor profile saved ✅')));
                      Navigator.pop(context);
                    }
                  },
                  child: (donorProvider.isLoading || _isFetchingLocation)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_hasExistingProfile ? 'Update profile' : 'Save donor profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}