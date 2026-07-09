import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/request_model.dart';
import '../../../providers/report_provider.dart';
import '../../../data/models/report_model.dart';

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  List<RequestModel> _activeRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    _activeRequests = await requestProvider.fetchActiveRequests();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmAccept(RequestModel request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
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

      final donorProfile = await donorProvider.fetchDonorProfile(user.uid);
      final donorPhone = donorProfile?.phone;

      bool success =
      await requestProvider.acceptRequest(request.id, user.uid, donorName, donorPhone);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you! The requester has been notified.')));
        _loadRequests();
      }
    }
  }

  Future<void> _reportRequest(RequestModel request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this request'),
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
      targetType: 'request',
      targetId: request.id,
      targetLabel: '${request.bloodGroup} request at ${request.hospitalName}',
      reason: reasonController.text.trim(),
      createdAt: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Report submitted to admin' : 'Could not submit, try again')));
    }
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
          : _activeRequests.isEmpty
          ? const Center(child: Text('No active emergency requests right now'))
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
                    ],
                  ),
                  if (request.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(request.notes, style: TextStyle(color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                        tooltip: 'Report',
                        onPressed: () => _reportRequest(request),
                      ),
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