import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../providers/eligibility_exception_provider.dart';
import '../../../data/models/donor_model.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/models/eligibility_exception_model.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  DonorModel? _donor;
  List<DonationModel> _history = [];
  EligibilityExceptionModel? _latestException;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final exceptionProvider =
    Provider.of<EligibilityExceptionProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _donor = await donorProvider.fetchDonorProfile(user.uid);
      if (_donor != null) {
        _history = await donorProvider.fetchDonationHistory(user.uid);
        if (_donor!.daysUntilEligible() > 0) {
          _latestException = await exceptionProvider.fetchLatestForDonor(user.uid);
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmDeleteDonation(DonationModel donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text(
            'This will permanently remove the ${donation.bloodGroup} donation from ${donation.date.toLocal().toString().split(' ')[0]}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || _donor == null) return;

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    bool success = await donorProvider.deleteDonation(donation.id, _donor!.uid);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Deleted' : 'Could not delete, try again')));
      if (success) _loadData();
    }
  }

  String _badge(int totalDonations) {
    if (totalDonations >= 10) return '🏆 Gold donor';
    if (totalDonations >= 5) return '🥈 Silver donor';
    if (totalDonations >= 1) return '🥉 Bronze donor';
    return 'New donor';
  }

  Widget _eligibilitySection() {
    if (_donor!.lastDonationDate == null) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('No previous donations — eligible now'),
        ],
      );
    }

    final nextEligibleDate = _donor!.lastDonationDate!.add(const Duration(days: 56));
    final daysLeft = _donor!.daysUntilEligible();

    if (daysLeft <= 0) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Eligible to donate now'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_bottom, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Next eligible on ${nextEligibleDate.toLocal().toString().split(' ')[0]} ($daysLeft days left)'),
            ),
          ],
        ),
        if (_latestException != null) ...[
          const SizedBox(height: 10),
          _exceptionStatusBanner(_latestException!),
        ],
      ],
    );
  }

  Widget _exceptionStatusBanner(EligibilityExceptionModel exception) {
    switch (exception.status) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration:
          BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.hourglass_bottom, color: Colors.orange, size: 16),
              SizedBox(width: 6),
              Expanded(
                  child: Text('Early donation request pending admin review',
                      style: TextStyle(color: Colors.orange, fontSize: 12))),
            ],
          ),
        );
      case 'approved':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration:
          BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Expanded(
                  child: Text('Early donation approved — you can accept requests now',
                      style: TextStyle(color: Colors.green, fontSize: 12))),
            ],
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration:
          BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text('Early donation request rejected',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (exception.adminRejectionReason != null) ...[
                const SizedBox(height: 4),
                Text('Reason: ${exception.adminRejectionReason}',
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation history'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donor == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'You have not registered as a donor yet. Register to start tracking donations.',
              textAlign: TextAlign.center),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.red[700],
                        child: Text(_donor!.bloodGroup,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_donor!.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_badge(_history.length)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite,
                      label: 'Total donations',
                      value: '${_history.length}',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.circle,
                      label: 'Status',
                      value: _donor!.isAvailable ? 'Available' : 'Not available',
                      color: _donor!.isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Eligibility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_donor!.lastDonationDate != null)
                        Text(
                            'Last donation: ${_donor!.lastDonationDate!.toLocal().toString().split(' ')[0]}'),
                      const SizedBox(height: 8),
                      _eligibilitySection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _history.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                    'No donation records yet. Complete an accepted request to add one automatically.'),
              )
                  : Column(
                children: _history.map((donation) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.bloodtype, color: Colors.red[700]),
                      title: Text(donation.bloodGroup),
                      subtitle: Text(
                        donation.location != null
                            ? '${donation.date.toLocal().toString().split(' ')[0]} • ${donation.location}'
                            : donation.date.toLocal().toString().split(' ')[0],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _confirmDeleteDonation(donation),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}