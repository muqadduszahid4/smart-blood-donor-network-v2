import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../providers/request_provider.dart';
import '../auth/login_screen.dart';
import '../donor/donor_registration_screen.dart';
import '../request/emergency_request_screen.dart';
import '../donor/nearby_donors_screen.dart';
import '../hospital/hospital_directory_screen.dart';
import '../request/my_requests_screen.dart';
import '../request/active_requests_screen.dart';
import '../donor/donation_history_screen.dart';
import '../donor/my_accepted_requests_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../settings/settings_screen.dart';
import '../donor/medical_verification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDonor = false;
  bool _isAvailable = false;
  int _activeRequestCount = 0;
  bool _isLoading = true;
  String _role = 'donor';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      final role = await authProvider.fetchUserRole(user.uid);
      _role = role ?? 'donor';

      final donor = await donorProvider.fetchDonorProfile(user.uid);
      if (donor != null) {
        _isDonor = true;
        _isAvailable = donor.isAvailable;
      }
      final activeRequests = await requestProvider.fetchActiveRequests();
      _activeRequestCount = activeRequests.length;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleAvailability(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isAvailable = value);
    await donorProvider.toggleAvailability(user.uid, value);
  }

  String _roleLabel() {
    switch (_role) {
      case 'requester':
        return 'Requester';
      case 'admin':
        return 'Admin';
      default:
        return 'Donor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_roleLabel()} dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user?.displayName ?? user?.email ?? "there"} 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ===== ADMIN VIEW =====
              if (_role == 'admin') ...[
                _NavCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin panel',
                  subtitle: 'Manage users, hospitals, and reports',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                ),
              ]

              // ===== DONOR VIEW =====
              else if (_role == 'donor') ...[
                Card(
                  color: _isAvailable ? Colors.green[50] : Colors.grey[200],
                  child: SwitchListTile(
                    title: const Text('Available to donate'),
                    subtitle: Text(_isAvailable
                        ? 'Donors can see you as available'
                        : 'You are hidden from donor search'),
                    value: _isAvailable,
                    activeColor: Colors.green[700],
                    onChanged: _toggleAvailability,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.emergency,
                        label: 'Active emergencies',
                        value: '$_activeRequestCount',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: _isDonor ? Icons.verified_user : Icons.person_add,
                        label: 'Donor status',
                        value: _isDonor ? 'Registered' : 'Not registered',
                        color: _isDonor ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Quick actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _NavCard(
                  icon: Icons.bloodtype,
                  title: _isDonor ? 'Edit donor profile' : 'Become a donor',
                  subtitle: 'Register or update your donor details',
                  color: Colors.red,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DonorRegistrationScreen()));
                    _loadSummary();
                  },
                ),
                _NavCard(
                  icon: Icons.volunteer_activism,
                  title: 'View emergency requests',
                  subtitle: 'Help someone nearby right now',
                  color: Colors.green[700]!,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ActiveRequestsScreen())),
                ),
                _NavCard(
                  icon: Icons.pending_actions,
                  title: 'My accepted requests',
                  subtitle: 'Confirm donations you\'ve completed',
                  color: Colors.deepOrange,
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyAcceptedRequestsScreen()));
                    _loadSummary();
                  },
                ),
                _NavCard(
                  icon: Icons.history,
                  title: 'Donation history',
                  subtitle: 'Your past donations and eligibility',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
                ),
                _NavCard(
                  icon: Icons.local_hospital,
                  title: 'Hospitals & blood banks',
                  subtitle: 'Directory with contact and map',
                  color: Colors.blue,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HospitalDirectoryScreen())),
                ),
                _NavCard(
                  icon: Icons.health_and_safety,
                  title: 'Medical verification',
                  subtitle: 'Submit health details for admin review',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MedicalVerificationScreen())),
                ),
              ]

              // ===== REQUESTER VIEW =====
              else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.emergency,
                          label: 'Active emergencies',
                          value: '$_activeRequestCount',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _NavCard(
                    icon: Icons.emergency,
                    title: 'Request blood urgently',
                    subtitle: 'Create a new emergency request',
                    color: Colors.red[700]!,
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EmergencyRequestScreen()));
                      _loadSummary();
                    },
                  ),
                  _NavCard(
                    icon: Icons.list_alt,
                    title: 'My requests',
                    subtitle: 'Track and manage your requests',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
                  ),
                  _NavCard(
                    icon: Icons.person_search,
                    title: 'Find nearby donors',
                    subtitle: 'Search donors by blood group and distance',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NearbyDonorsScreen())),
                  ),
                  _NavCard(
                    icon: Icons.local_hospital,
                    title: 'Hospitals & blood banks',
                    subtitle: 'Directory with contact and map',
                    color: Colors.blue,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HospitalDirectoryScreen())),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}