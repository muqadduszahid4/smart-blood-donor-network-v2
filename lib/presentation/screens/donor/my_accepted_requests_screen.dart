import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/request_model.dart';
import '../../../data/models/donation_model.dart';

class MyAcceptedRequestsScreen extends StatefulWidget {
  const MyAcceptedRequestsScreen({super.key});

  @override
  State<MyAcceptedRequestsScreen> createState() => _MyAcceptedRequestsScreenState();
}

class _MyAcceptedRequestsScreenState extends State<MyAcceptedRequestsScreen> {
  List<RequestModel> _accepted = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _accepted = await requestProvider.fetchMyAcceptedRequests(user.uid);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _callRequester(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available for this requester')));
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

  Future<void> _whatsAppRequester(RequestModel request) async {
    if (request.requesterPhone == null || request.requesterPhone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available for this requester')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myName = authProvider.currentUser?.displayName ??
        authProvider.currentUser?.email ??
        'A donor';

    String phone = request.requesterPhone!.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    }

    final message = Uri.encodeComponent(
        'Hi ${request.requesterName}, this is $myName. I\'ve accepted your ${request.bloodGroup} blood request at ${request.hospitalName}. Let\'s coordinate the details.');

    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed on this device')));
    }
  }

  Future<void> _confirmCompleted(RequestModel request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as completed?'),
        content: Text(
            'Confirm that you donated ${request.bloodGroup} blood for ${request.requesterName} at ${request.hospitalName}. This will be added to your donation history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, completed'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);

    bool statusUpdated = await requestProvider.markRequestCompleted(request.id);
    if (!statusUpdated) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not update request status')));
      }
      return;
    }

    final donation = DonationModel(
      id: '',
      donorId: user.uid,
      bloodGroup: request.bloodGroup,
      date: DateTime.now(),
      location: request.hospitalName,
      requestId: request.id,
      requesterId: request.requesterId,
    );
    bool logged = await donorProvider.logDonation(donation);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(logged
            ? 'Donation recorded — thank you!'
            : 'Request marked completed, but saving to your history failed')),
      );
      setState(() => _accepted.remove(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My accepted requests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accepted.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'You have no accepted requests waiting to be completed.',
              textAlign: TextAlign.center),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _accepted.length,
        itemBuilder: (context, index) {
          final request = _accepted[index];
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
                            Text(
                                '${request.hospitalName} • ${request.units} units',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('For ${request.requesterName}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                            if (request.requesterPhone != null &&
                                request.requesterPhone!.isNotEmpty)
                              Text(request.requesterPhone!,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 11)),
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
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call, size: 18, color: Colors.green),
                          label: const Text('Call'),
                          onPressed: () => _callRequester(request.requesterPhone),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat, size: 18, color: Colors.teal),
                          label: const Text('WhatsApp'),
                          onPressed: () => _whatsAppRequester(request),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as completed'),
                      onPressed: () => _confirmCompleted(request),
                    ),
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