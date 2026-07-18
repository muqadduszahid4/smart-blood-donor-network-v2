import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/donor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/donor_model.dart';
import '../../../core/utils/blood_compatibility.dart';
import '../../../providers/report_provider.dart';
import '../../../data/models/report_model.dart';

enum _SortMode { alphabetical, mostDonations, recentlyJoined }

class NearbyDonorsScreen extends StatefulWidget {
  const NearbyDonorsScreen({super.key});

  @override
  State<NearbyDonorsScreen> createState() => _NearbyDonorsScreenState();
}

class _NearbyDonorsScreenState extends State<NearbyDonorsScreen> {
  static const List<String> _bloodGroups = [
    'All',
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  String _selectedBloodGroup = 'All';
  String _selectedCity = 'All cities';
  bool _includeCompatible = false;
  bool _favoritesOnly = false;
  _SortMode _sortMode = _SortMode.alphabetical;

  bool _isLoading = true;
  String? _errorMessage;

  List<DonorModel> _allDonors = [];
  List<String> _availableCities = ['All cities'];
  Set<String> _favoriteIds = {};
  Map<String, bool> _verifiedStatus = {};
  Map<String, int> _donationCounts = {};

  List<DonorModel> _filteredDonors = [];

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      final donors = await donorProvider.fetchAllDonors();
      final favoriteIds = user != null
          ? await donorProvider.fetchFavoriteDonorIds(user.uid)
          : <String>{};

      _allDonors = donors;
      _favoriteIds = favoriteIds;

      final cities = donors
          .where((d) => d.isActive)
          .map((d) => d.city.trim())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      cities.sort();
      _availableCities = ['All cities', ...cities];

      _applyFilters();
      await _loadBadgeDataForVisibleDonors();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBadgeDataForVisibleDonors() async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final futures = <Future>[];

    for (final donor in _filteredDonors) {
      if (!_verifiedStatus.containsKey(donor.uid)) {
        futures.add(donorProvider.fetchMedicalVerification(donor.uid).then((record) {
          _verifiedStatus[donor.uid] = record != null;
        }));
      }
      if (!_donationCounts.containsKey(donor.uid)) {
        futures.add(donorProvider.fetchDonationHistory(donor.uid).then((history) {
          _donationCounts[donor.uid] = history.length;
        }));
      }
    }

    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    List<String> allowedGroups;
    if (_selectedBloodGroup == 'All') {
      allowedGroups = _bloodGroups.skip(1).toList();
    } else if (_includeCompatible) {
      allowedGroups = BloodCompatibility.compatibleDonorGroupsFor(_selectedBloodGroup);
    } else {
      allowedGroups = [_selectedBloodGroup];
    }

    var results = _allDonors
        .where((d) => d.isActive && d.isAvailable)
        .where((d) => allowedGroups.contains(d.bloodGroup))
        .where((d) =>
    _selectedCity == 'All cities' ||
        d.city.trim().toLowerCase() == _selectedCity.toLowerCase())
        .toList();

    if (_favoritesOnly) {
      results = results.where((d) => _favoriteIds.contains(d.uid)).toList();
    }

    switch (_sortMode) {
      case _SortMode.alphabetical:
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortMode.mostDonations:
        results.sort((a, b) {
          final countA = _donationCounts[a.uid] ?? 0;
          final countB = _donationCounts[b.uid] ?? 0;
          return countB.compareTo(countA);
        });
        break;
      case _SortMode.recentlyJoined:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() => _filteredDonors = results);
    _loadBadgeDataForVisibleDonors();
  }

  Future<void> _toggleFavorite(DonorModel donor) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final isFav = _favoriteIds.contains(donor.uid);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(donor.uid);
      } else {
        _favoriteIds.add(donor.uid);
      }
    });

    bool success = isFav
        ? await donorProvider.removeFavoriteDonor(user.uid, donor.uid)
        : await donorProvider.addFavoriteDonor(user.uid, donor.uid);

    if (!success && mounted) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(donor.uid);
        } else {
          _favoriteIds.remove(donor.uid);
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not update favorite, try again')));
    }

    if (_favoritesOnly) _applyFilters();
  }

  Future<void> _reportDonor(DonorModel donor) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report ${donor.name}'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'What\'s wrong?', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (reasonController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please describe the issue')));
      }
      return;
    }

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    bool success = await reportProvider.submitReport(ReportModel(
      id: '',
      reporterId: user.uid,
      reporterName: user.displayName ?? user.email ?? 'Anonymous',
      targetType: 'donor',
      targetId: donor.uid,
      targetLabel: '${donor.name} (${donor.bloodGroup})',
      reason: reasonController.text.trim(),
      createdAt: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Report submitted' : 'Could not submit, try again')));
    }
  }

  Future<void> _callDonor(String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available for this donor')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _whatsAppDonor(DonorModel donor) async {
    if (donor.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available for this donor')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myName = authProvider.currentUser?.displayName ??
        authProvider.currentUser?.email ??
        'Someone';

    String phone = donor.phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    }

    final message = Uri.encodeComponent(
        'Hi ${donor.name}, this is $myName from Smart Blood Donor Network. '
            'I saw you\'re a ${donor.bloodGroup} donor in ${donor.city} — could you help with an urgent blood need?');

    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed on this device')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby donors'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEverything),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadEverything, child: const Text('Retry')),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBloodGroup,
                    decoration: InputDecoration(
                      labelText: 'Blood group',
                      border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _bloodGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _selectedBloodGroup = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _availableCities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _selectedCity = value;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedBloodGroup != 'All')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Include compatible donors'),
                        selected: _includeCompatible,
                        onSelected: (value) {
                          _includeCompatible = value;
                          _applyFilters();
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Favorites only'),
                      avatar: const Icon(Icons.favorite, size: 16),
                      selected: _favoritesOnly,
                      onSelected: (value) {
                        _favoritesOnly = value;
                        _applyFilters();
                      },
                    ),
                  ),
                  PopupMenuButton<_SortMode>(
                    initialValue: _sortMode,
                    onSelected: (value) {
                      _sortMode = value;
                      _applyFilters();
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                          value: _SortMode.alphabetical, child: Text('Name (A-Z)')),
                      PopupMenuItem(
                          value: _SortMode.mostDonations, child: Text('Most donations')),
                      PopupMenuItem(
                          value: _SortMode.recentlyJoined, child: Text('Recently joined')),
                    ],
                    child: const Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 16),
                          SizedBox(width: 4),
                          Text('Sort'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredDonors.isEmpty
                ? const Center(child: Text('No matching donors found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredDonors.length,
              itemBuilder: (context, index) {
                final donor = _filteredDonors[index];
                final isVerified = _verifiedStatus[donor.uid] ?? false;
                final donationCount = _donationCounts[donor.uid];
                final isFav = _favoriteIds.contains(donor.uid);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.red[700],
                              child: Text(
                                donor.bloodGroup,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    donor.name.isNotEmpty ? donor.name : 'Unnamed donor',
                                    style:
                                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          donor.address.isNotEmpty
                                              ? '${donor.address}, ${donor.city}'
                                              : donor.city,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(donor.phone,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (donor.bloodGroup != _selectedBloodGroup &&
                                          _selectedBloodGroup != 'All')
                                        Chip(
                                          label: const Text('Compatible',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.blue[50],
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (isVerified)
                                        Chip(
                                          avatar: const Icon(Icons.verified,
                                              size: 14, color: Colors.green),
                                          label: const Text('Info shared',
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.green[50],
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (donationCount != null && donationCount > 0)
                                        Chip(
                                          avatar: const Icon(Icons.favorite,
                                              size: 14, color: Colors.red),
                                          label: Text('$donationCount donation${donationCount == 1 ? "" : "s"}',
                                              style: const TextStyle(fontSize: 10)),
                                          backgroundColor: Colors.red[50],
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey),
                              onSelected: (value) {
                                if (value == 'favorite') _toggleFavorite(donor);
                                if (value == 'report') _reportDonor(donor);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'favorite',
                                  child: Text(isFav ? 'Remove favorite' : 'Add favorite'),
                                ),
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report this donor',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.call, size: 18, color: Colors.green),
                                label: const Text('Call'),
                                onPressed: () => _callDonor(donor.phone),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.chat, size: 18, color: Colors.teal),
                                label: const Text('WhatsApp'),
                                onPressed: () => _whatsAppDonor(donor),
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE0E0E0)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: const Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 80, color: const Color(0xFFEFEFEF)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}