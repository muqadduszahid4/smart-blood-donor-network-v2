import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../data/models/request_model.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<RequestModel> _myRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _myRequests = await requestProvider.fetchMyRequests(user.uid);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmCancel(RequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: Text(
            'Request for ${request.bloodGroup} at ${request.hospitalName} will be marked as cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      bool success = await requestProvider.cancelRequest(request.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request cancelled')));
        _loadRequests();
      }
    }
  }

  Future<void> _confirmDelete(RequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this request?'),
        content: Text(
            'This will permanently remove the ${request.bloodGroup} request at ${request.hospitalName}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final requestProvider = Provider.of<RequestProvider>(context, listen: false);
      bool success = await requestProvider.deleteRequest(request.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request deleted')));
        _loadRequests();
      }
    }
  }

  Future<void> _callDonor(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber[800]!;
      case 'active':
        return Colors.red;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue[800]!;
      case 'fulfilled':
        return Colors.blue;
      case 'rejected':
        return Colors.red[900]!;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My requests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myRequests.isEmpty
          ? const Center(child: Text('You have not made any requests yet'))
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final request = _myRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red[700],
                    child: Text(request.bloodGroup,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${request.hospitalName} • ${request.units} units',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(request.notes.isEmpty ? 'No notes' : request.notes,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        Text(
                          request.createdAt.toLocal().toString().split('.')[0],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                              color: _statusColor(request.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                        if ((request.status == 'accepted' || request.status == 'completed') &&
                            request.acceptedByName != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Accepted by ${request.acceptedByName}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (request.status == 'accepted')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Donor is on the way — contact them if needed',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                            ),
                          if (request.donorPhone != null &&
                              request.donorPhone!.isNotEmpty &&
                              request.status == 'accepted')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: () => _callDonor(request.donorPhone!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.call, color: Colors.green[700], size: 16),
                                    const SizedBox(width: 4),
                                    Text('Call ${request.donorPhone}',
                                        style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                        if (request.status == 'rejected')
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Not approved. Check details and submit a new request.',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request.status == 'active' || request.status == 'pending')
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.cancel, color: Colors.orange, size: 20),
                          tooltip: 'Cancel',
                          onPressed: () => _confirmCancel(request),
                        ),
                      const SizedBox(height: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(request),
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