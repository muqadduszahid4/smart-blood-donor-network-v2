import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/hospital_provider.dart';
import '../../../data/models/hospital_model.dart';

class HospitalDirectoryScreen extends StatefulWidget {
  const HospitalDirectoryScreen({super.key});

  @override
  State<HospitalDirectoryScreen> createState() => _HospitalDirectoryScreenState();
}

class _HospitalDirectoryScreenState extends State<HospitalDirectoryScreen> {
  List<HospitalModel> _allPlaces = [];
  Set<String> _favorites = {};
  String _filter = 'All';
  bool _isLoading = true;

  final TextEditingController _citySearchController = TextEditingController();
  String _citySearch = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _citySearchController.addListener(() {
      setState(() => _citySearch = _citySearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    _allPlaces = await hospitalProvider.fetchAllHospitals();
    await _loadFavorites();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = (prefs.getStringList('favorite_hospitals') ?? []).toSet();
  }

  Future<void> _toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    await prefs.setStringList('favorite_hospitals', _favorites.toList());
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(HospitalModel place) async {
    final rawNumber = (place.whatsapp?.isNotEmpty == true) ? place.whatsapp! : place.phone;
    String digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = '92${digits.substring(1)}';
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<HospitalModel> get _filteredPlaces {
    List<HospitalModel> base;
    if (_filter == 'All') {
      base = _allPlaces;
    } else if (_filter == 'Favorites') {
      base = _allPlaces.where((p) => _favorites.contains(p.id)).toList();
    } else {
      final typeFilter = _filter == 'Hospitals' ? 'hospital' : 'blood_bank';
      base = _allPlaces.where((p) => p.type == typeFilter).toList();
    }
    if (_citySearch.isEmpty) return base;
    return base.where((p) => p.city.toLowerCase().contains(_citySearch)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitals & blood banks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _citySearchController,
              decoration: InputDecoration(
                hintText: 'Search by city',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Hospitals', 'Blood banks', 'Favorites'].map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredPlaces.isEmpty
                ? const Center(child: Text('No places found'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                final isFav = _favorites.contains(place.id);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              place.type == 'hospital'
                                  ? Icons.local_hospital
                                  : Icons.bloodtype,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(place.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(place.city,
                                      style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  Text(place.address,
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 12)),
                                  Text(place.phone,
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey, size: 22),
                              onPressed: () => _toggleFavorite(place.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.call, size: 16, color: Colors.green),
                                label: const Text('Call', style: TextStyle(fontSize: 12)),
                                onPressed: () => _callNumber(place.phone),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat, size: 16, color: Colors.teal),
                                label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                                onPressed: () => _openWhatsApp(place),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.map, size: 16, color: Colors.blue),
                                label: const Text('Map', style: TextStyle(fontSize: 12)),
                                onPressed: () =>
                                    _openMap(place.latitude, place.longitude),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}