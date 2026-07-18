import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../providers/eligibility_exception_provider.dart';
import '../../../data/models/request_model.dart';
import '../../../data/models/eligibility_exception_model.dart';
import '../../../core/utils/blood_compatibility.dart';

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  List<RequestModel> _activeRequests = [];
  bool _isLoading = true;
  String? _myBloodGroup;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;

    final allActive = await requestProvider.fetchActiveRequests();

    if (user != null) {
      final donorProfile = await donorProvider.fetchDonorProfile(user.uid);
      _myBloodGroup = donorProfile?.bloodGroup;
    }

    if (_myBloodGroup == null) {
      _activeRequests = [];
    } else {
      _activeRequests = allActive.where((request) {
        final compatibleDonors =
        BloodCompatibility.compatibleDonorGroupsFor(request.bloodGroup);
        return compatibleDonors.contains(_myBloodGroup);
      }).toList();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _proceedWithAccept(RequestModel request, String? donorPhone) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept this request?'),
        content: Text(
            'You are confirming you will help with the ${request.bloodGroup} request at ${request.hospitalName}. The requester will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I\'ll help', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      final donorName = user.displayName ?? user.email ?? 'A donor';

      bool success =
      await requestProvider.acceptRequest(request.id, user.uid, donorName, donorPhone);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you! The requester has been notified.')));
        _loadRequests();
      }
    }
  }

  Future<void> _requestEarlyEligibilityException(
      RequestModel request, DateTime lastDonationDate, DateTime nextEligibleDate) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You\'re not yet eligible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Your last donation was on ${lastDonationDate.toLocal().toString().split(' ')[0]}. '
                    'You are eligible again on ${nextEligibleDate.toLocal().toString().split(' ')[0]}.'),
            const SizedBox(height: 12),
            const Text(
                'If you have a valid medical reason to donate early, explain it below and admin will review it.'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Reason for early donation request',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit for admin review'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (reasonController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please provide a reason')));
      }
      return;
    }

    final exceptionProvider =
    Provider.of<EligibilityExceptionProvider>(context, listen: false);
    bool success = await exceptionProvider.submitRequest(EligibilityExceptionModel(
      id: '',
      donorId: user.uid,
      donorName: user.displayName ?? user.email ?? 'Donor',
      lastDonationDate: lastDonationDate,
      nextEligibleDate: nextEligibleDate,
      reason: reasonController.text.trim(),
      createdAt: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Sent to admin for review. You\'ll be notified once decided.'
              : 'Could not submit, try again')));
    }
  }

  Future<void> _confirmAccept(RequestModel request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final exceptionProvider =
    Provider.of<EligibilityExceptionProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final donorProfile = await donorProvider.fetchDonorProfile(user.uid);
    final donorPhone = donorProfile?.phone;

    if (donorProfile == null) {
      await _proceedWithAccept(request, donorPhone);
      return;
    }

    final daysUntilEligible = donorProfile.daysUntilEligible();

    if (daysUntilEligible <= 0) {
      await _proceedWithAccept(request, donorPhone);
      return;
    }

    final existingException = await exceptionProvider.fetchLatestForDonor(user.uid);

    if (existingException != null && existingException.status == 'approved') {
      await _proceedWithAccept(request, donorPhone);
      return;
    }

    if (existingException != null && existingException.status == 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Your early-donation request is still pending admin review.')));
      }
      return;
    }

    final lastDonationDate = donorProfile.lastDonationDate!;
    final nextEligibleDate = lastDonationDate.add(const Duration(days: 56));

    if (existingException != null && existingException.status == 'rejected') {
      if (mounted) {
        final resubmit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Previous request was rejected'),
            content: Text(existingException.adminRejectionReason != null
                ? 'Admin\'s reason: ${existingException.adminRejectionReason}\n\nSubmit a new request?'
                : 'Submit a new request?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit new request')),
            ],
          ),
        );
        if (resubmit == true) {
          await _requestEarlyEligibilityException(request, lastDonationDate, nextEligibleDate);
        }
      }
      return;
    }

    await _requestEarlyEligibilityException(request, lastDonationDate, nextEligibleDate);
  }

  void _declineRequest(RequestModel request) {
    setState(() => _activeRequests.remove(request));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Request hidden from your list')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active emergency requests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myBloodGroup == null
          ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'Register as a donor first to see requests compatible with your blood group.',
                textAlign: TextAlign.center),
          ))
          : _activeRequests.isEmpty
          ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
                'No active requests currently match your blood group ($_myBloodGroup).',
                textAlign: TextAlign.center),
          ))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _activeRequests.length,
        itemBuilder: (context, index) {
          final request = _activeRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red[700],
                        child: Text(request.bloodGroup,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${request.hospitalName} • ${request.units} units',
                                style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Requested by ${request.requesterName}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      if (request.bloodGroup != _myBloodGroup)
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Compatible',
                              style: TextStyle(fontSize: 10, color: Colors.blue)),
                        ),
                    ],
                  ),
                  if (request.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(request.notes, style: TextStyle(color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700]),
                          onPressed: () => _declineRequest(request),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.volunteer_activism),
                          label: const Text('I\'ll help'),
                          onPressed: () => _confirmAccept(request),
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
    );
  }
}