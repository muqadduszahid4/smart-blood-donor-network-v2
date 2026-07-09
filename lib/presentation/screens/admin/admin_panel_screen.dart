import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/request_model.dart';
import '../../../data/models/donor_model.dart';
import 'manage_hospitals_screen.dart';
import 'medical_verification_requests_screen.dart';
import '../../../providers/report_provider.dart';
import '../../../data/models/report_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _totalUsers = 0;
  int _totalDonors = 0;
  int _activeRequests = 0;
  bool _isLoading = true;

  List<RequestModel> _pendingRequests = [];

  List<DonorModel> _allDonors = [];
  List<DonorModel> _filteredDonors = [];
  final TextEditingController _donorSearchController = TextEditingController();

  List<Map<String, dynamic>> _requesters = [];
  List<Map<String, dynamic>> _filteredRequesters = [];
  final TextEditingController _requesterSearchController = TextEditingController();

  Map<String, int> _bloodGroupCounts = {};

  List<ReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _donorSearchController.addListener(_filterDonors);
    _requesterSearchController.addListener(_filterRequesters);
  }

  @override
  void dispose() {
    _donorSearchController.dispose();
    _requesterSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    final requests = await requestProvider.fetchActiveRequests();
    final pending = await requestProvider.fetchPendingRequests();
    final donors = await donorProvider.fetchAllDonors();
    final requesters = await authProvider.fetchUsersByRole('requester');
    final reports = await reportProvider.fetchPendingReports();

    final Map<String, int> counts = {};
    for (final donor in donors) {
      if (!donor.isActive) continue;
      final group = donor.bloodGroup.isEmpty ? 'Unknown' : donor.bloodGroup;
      counts[group] = (counts[group] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _activeRequests = requests.length;
        _pendingRequests = pending;
        _allDonors = donors;
        _filteredDonors = donors;
        _totalDonors = donors.length;
        _requesters = requesters;
        _filteredRequesters = requesters;
        _bloodGroupCounts = counts;
        _totalUsers = donors.length + requesters.length;
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  void _filterDonors() {
    final query = _donorSearchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDonors = _allDonors;
      } else {
        _filteredDonors = _allDonors.where((d) {
          return d.name.toLowerCase().contains(query) ||
              d.bloodGroup.toLowerCase().contains(query) ||
              d.city.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _filterRequesters() {
    final query = _requesterSearchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRequesters = _requesters;
      } else {
        _filteredRequesters = _requesters.where((r) {
          final name = (r['name'] as String).toLowerCase();
          final email = (r['email'] as String).toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(RequestModel request) async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    bool success = await requestProvider.approveRequest(request.id);
    if (success) {
      setState(() => _pendingRequests.remove(request));
      _showSnack('Request approved and now visible to donors');
    }
  }

  Future<void> _reject(RequestModel request) async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    bool success = await requestProvider.rejectRequest(request.id);
    if (success) {
      setState(() => _pendingRequests.remove(request));
      _showSnack('Request rejected');
    }
  }

  Future<void> _toggleDonorActive(DonorModel donor) async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final newStatus = !donor.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? 'Activate donor?' : 'Deactivate donor?'),
        content: Text(newStatus
            ? '${donor.name} will be visible again in donor search results.'
            : '${donor.name} will be hidden from donor search results and cannot be contacted for requests.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate',
                style: TextStyle(color: newStatus ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool success = await donorProvider.toggleDonorActiveStatus(donor.uid, newStatus);
    if (success && mounted) {
      setState(() {
        final index = _allDonors.indexWhere((d) => d.uid == donor.uid);
        if (index != -1) {
          _allDonors[index] = donor.copyWith(isActive: newStatus);
        }
        _filterDonors();
        final Map<String, int> counts = {};
        for (final d in _allDonors) {
          if (!d.isActive) continue;
          final group = d.bloodGroup.isEmpty ? 'Unknown' : d.bloodGroup;
          counts[group] = (counts[group] ?? 0) + 1;
        }
        _bloodGroupCounts = counts;
      });
      _showSnack(newStatus ? 'Donor activated' : 'Donor deactivated');
    }
  }

  Future<void> _toggleRequesterActive(Map<String, dynamic> requester) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentStatus = requester['isActive'] as bool;
    final newStatus = !currentStatus;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? 'Reinstate account?' : 'Suspend this account?'),
        content: Text(newStatus
            ? '${requester['name']} will be able to create requests again.'
            : '${requester['name']} will be blocked from creating new requests.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Reinstate' : 'Suspend',
                style: TextStyle(color: newStatus ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    bool success = await authProvider.toggleUserActiveStatus(
        requester['uid'] as String, newStatus);
    if (success && mounted) {
      setState(() {
        final index = _requesters.indexWhere((r) => r['uid'] == requester['uid']);
        if (index != -1) {
          _requesters[index] = {..._requesters[index], 'isActive': newStatus};
        }
        _filterRequesters();
      });
      _showSnack(newStatus ? 'Account reinstated' : 'Account suspended');
    }
  }

  Future<void> _dismissReport(ReportModel report) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    bool success = await reportProvider.dismissReport(report.id);
    if (success && mounted) {
      setState(() => _reports.remove(report));
      _showSnack('Report dismissed');
    }
  }

  Future<void> _actionReport(ReportModel report) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (report.targetType == 'donor') {
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      await donorProvider.toggleDonorActiveStatus(report.targetId, false);
    } else if (report.targetType == 'request') {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      await requestProvider.rejectRequest(report.targetId);
    }

    bool success = await reportProvider.markActioned(report.id);
    if (success && mounted) {
      setState(() => _reports.remove(report));
      _showSnack(report.targetType == 'donor'
          ? 'Donor deactivated'
          : 'Request rejected');
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin panel')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatBox(
                        label: 'Total users', value: '$_totalUsers', icon: Icons.people)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        label: 'Registered donors',
                        value: '$_totalDonors',
                        icon: Icons.bloodtype)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        label: 'Active requests',
                        value: '$_activeRequests',
                        icon: Icons.emergency)),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Blood group availability',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Active donors only, grouped by blood type',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            if (_bloodGroupCounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No donor data available yet'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (_bloodGroupCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((entry) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Column(
                        children: [
                          Text(entry.key,
                              style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${entry.value} donor${entry.value == 1 ? "" : "s"}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 11)),
                        ],
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            const Text('Pending request approvals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_pendingRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No requests waiting for approval'),
              )
            else
              ..._pendingRequests.map((request) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${request.bloodGroup} • ${request.hospitalName}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('By ${request.requesterName} • ${request.units} units',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () => _reject(request),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white),
                              onPressed: () => _approve(request),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.health_and_safety, color: Colors.purple),
                title: const Text('Medical verification requests'),
                subtitle: const Text('Review donor health submissions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MedicalVerificationRequestsScreen())),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Manage donors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _donorSearchController,
              decoration: InputDecoration(
                hintText: 'Search by name, blood group, or city',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredDonors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No donors found'),
              )
            else
              ..._filteredDonors.map((donor) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: donor.isActive ? Colors.red[700] : Colors.grey,
                    child: Text(donor.bloodGroup,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(donor.name.isNotEmpty ? donor.name : 'Unnamed donor'),
                  subtitle: Text(
                      '${donor.city} • ${donor.isAvailable ? "Available" : "Unavailable"} • ${donor.isActive ? "Active" : "Deactivated"}'),
                  trailing: Switch(
                    value: donor.isActive,
                    activeColor: Colors.green,
                    onChanged: (_) => _toggleDonorActive(donor),
                  ),
                ),
              )),
            const SizedBox(height: 24),

            const Text('Manage requesters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Suspending blocks in-app access; it does not delete their Firebase login (requires a backend)',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: _requesterSearchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredRequesters.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No requesters found'),
              )
            else
              ..._filteredRequesters.map((requester) {
                final isActive = requester['isActive'] as bool;
                final name = requester['name'] as String;
                final email = requester['email'] as String;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.indigo : Colors.grey,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(name),
                    subtitle: Text(email.isEmpty
                        ? (isActive ? 'Active' : 'Suspended')
                        : '$email • ${isActive ? "Active" : "Suspended"}'),
                    trailing: Switch(
                      value: isActive,
                      activeColor: Colors.green,
                      onChanged: (_) => _toggleRequesterActive(requester),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            const Text('Reported content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._reports.map((report) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                            report.targetType == 'donor'
                                ? Icons.person
                                : Icons.emergency,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(report.targetLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Reason: ${report.reason}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    Text('Reported by ${report.reporterName}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _dismissReport(report),
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white),
                            onPressed: () => _actionReport(report),
                            child: Text(report.targetType == 'donor'
                                ? 'Deactivate donor'
                                : 'Reject request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            if (_reports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No pending reports'),
              ),
            const SizedBox(height: 24),

            const Text('Hospitals & blood banks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.blue),
                title: const Text('Manage hospitals & blood banks'),
                subtitle: const Text('Add, edit, or remove directory entries'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ManageHospitalsScreen())),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.red[700]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}