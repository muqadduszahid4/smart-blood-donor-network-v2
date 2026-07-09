import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/hospital_provider.dart';
import '../../../data/models/hospital_model.dart';

class ManageHospitalsScreen extends StatefulWidget {
  const ManageHospitalsScreen({super.key});

  @override
  State<ManageHospitalsScreen> createState() => _ManageHospitalsScreenState();
}

class _ManageHospitalsScreenState extends State<ManageHospitalsScreen> {
  List<HospitalModel> _hospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    _hospitals = await hospitalProvider.fetchAllHospitals();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStarterData() async {
    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    bool added = await hospitalProvider.seedStarterHospitalsIfEmpty();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(added
              ? 'Starter hospitals added'
              : 'List already has entries — nothing added to avoid duplicates')));
      _load();
    }
  }

  Future<void> _showForm({HospitalModel? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final latController =
    TextEditingController(text: existing?.latitude.toString() ?? '');
    final lngController =
    TextEditingController(text: existing?.longitude.toString() ?? '');
    String type = existing?.type ?? 'hospital';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add hospital / blood bank' : 'Edit entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Hospital'),
                      selected: type == 'hospital',
                      onSelected: (_) => setDialogState(() => type = 'hospital'),
                    ),
                    ChoiceChip(
                      label: const Text('Blood bank'),
                      selected: type == 'blood_bank',
                      onSelected: (_) => setDialogState(() => type = 'blood_bank'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (e.g. 0419210099)'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tip: open the location in Google Maps, long-press the pin, and copy the coordinates shown.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    if (nameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Name, address, and phone are required')));
      }
      return;
    }

    final lat = double.tryParse(latController.text.trim()) ?? 0;
    final lng = double.tryParse(lngController.text.trim()) ?? 0;

    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    bool success;

    if (existing == null) {
      success = await hospitalProvider.addHospital(HospitalModel(
        id: '',
        name: nameController.text.trim(),
        type: type,
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        latitude: lat,
        longitude: lng,
        createdAt: DateTime.now(),
      ));
    } else {
      success = await hospitalProvider.updateHospital(HospitalModel(
        id: existing.id,
        name: nameController.text.trim(),
        type: type,
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        latitude: lat,
        longitude: lng,
        createdAt: existing.createdAt,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Saved' : 'Something went wrong, try again')));
      if (success) _load();
    }
  }

  Future<void> _confirmDelete(HospitalModel hospital) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('${hospital.name} will be permanently removed from the directory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
    bool success = await hospitalProvider.deleteHospital(hospital.id);
    if (success && mounted) {
      setState(() => _hospitals.remove(hospital));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage hospitals & blood banks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hospitals.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hospitals or blood banks added yet.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('Load starter list (6 real entries)'),
                onPressed: _loadStarterData,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                hospital.type == 'hospital' ? Icons.local_hospital : Icons.bloodtype,
                color: Colors.red[700],
              ),
              title: Text(hospital.name),
              subtitle: Text('${hospital.address}\n${hospital.phone}'),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _showForm(existing: hospital),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(hospital),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}