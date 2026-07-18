import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/request_model.dart';
import '../../../data/models/medical_verification_model.dart';

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

  /// Shared dialog form used by both "Edit" (existing pending/active request)
  /// and "Request again" (creates a brand new request from an old template).
  /// Returns the entered values as a map, or null if cancelled.
  Future<Map<String, dynamic>?> _showRequestFormDialog({
    required String title,
    required String confirmLabel,
    required String initialBloodGroup,
    required int initialUnits,
    required String initialHospital,
    required String initialCity,
    required String initialPhone,
    required String initialNotes,
  }) async {
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    String selectedBloodGroup = initialBloodGroup;
    final unitsController = TextEditingController(text: '$initialUnits');
    final hospitalController = TextEditingController(text: initialHospital);
    final cityController = TextEditingController(text: initialCity);
    final phoneController = TextEditingController(text: initialPhone);
    final notesController = TextEditingController(text: initialNotes);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedBloodGroup,
                  decoration: const InputDecoration(
                      labelText: 'Blood group', border: OutlineInputBorder()),
                  items: bloodGroups
                      .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedBloodGroup = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Units required', border: OutlineInputBorder()),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                      labelText: 'Hospital name', border: OutlineInputBorder()),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter hospital name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                      labelText: 'City', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Your contact number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notes (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (saved != true) return null;

    return {
      'bloodGroup': selectedBloodGroup,
      'units': int.parse(unitsController.text),
      'hospitalName': hospitalController.text.trim(),
      'city': cityController.text.trim(),
      'phone': phoneController.text.trim(),
      'notes': notesController.text.trim(),
    };
  }

  Future<void> _editRequest(RequestModel request) async {
    final values = await _showRequestFormDialog(
      title: 'Edit request',
      confirmLabel: 'Save',
      initialBloodGroup: request.bloodGroup,
      initialUnits: request.units,
      initialHospital: request.hospitalName,
      initialCity: request.city ?? '',
      initialPhone: request.requesterPhone ?? '',
      initialNotes: request.notes,
    );

    if (values == null || !mounted) return;

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    bool success = await requestProvider.updateRequest(
      requestId: request.id,
      bloodGroup: values['bloodGroup'],
      units: values['units'],
      hospitalName: values['hospitalName'],
      city: values['city'],
      requesterPhone: values['phone'],
      notes: values['notes'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Request updated' : 'Could not update, try again')));
      if (success) _loadRequests();
    }
  }

  /// For an already accepted/completed/fulfilled request: opens the same
  /// form pre-filled with the old details, but submits it as a brand new
  /// pending request instead of modifying the original (which stays as
  /// completed history).
  Future<void> _requestAgain(RequestModel oldRequest) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final values = await _showRequestFormDialog(
      title: 'Request again',
      confirmLabel: 'Submit new request',
      initialBloodGroup: oldRequest.bloodGroup,
      initialUnits: oldRequest.units,
      initialHospital: oldRequest.hospitalName,
      initialCity: oldRequest.city ?? '',
      initialPhone: oldRequest.requesterPhone ?? '',
      initialNotes: '',
    );

    if (values == null || !mounted) return;

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final newRequest = RequestModel(
      id: '',
      requesterId: user.uid,
      requesterName: user.displayName ?? user.email ?? 'Anonymous',
      requesterPhone: values['phone'],
      bloodGroup: values['bloodGroup'],
      units: values['units'],
      hospitalName: values['hospitalName'],
      city: values['city'],
      notes: values['notes'],
      latitude: oldRequest.latitude,
      longitude: oldRequest.longitude,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    bool success = await requestProvider.createRequest(newRequest);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'New request submitted ✅'
              : 'Could not submit, try again')));
      if (success) _loadRequests();
    }
  }

  Future<void> _callDonor(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _rejectMedical(RequestModel request) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject medical report'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Reason (shown to donor)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
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

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    bool success = await requestProvider.rejectMedicalByRequester(
        request.id, reasonController.text.trim());
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rejection sent to donor')));
      _loadRequests();
    }
  }

  Future<void> _approveMedical(RequestModel request) async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    bool success = await requestProvider.approveMedicalByRequester(request.id);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Medical report approved')));
      _loadRequests();
    }
  }

  Future<void> _viewMedicalReport(RequestModel request) async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);

    if (request.donorId == null) return;

    final record = await donorProvider.fetchMedicalVerification(request.donorId!);

    if (!mounted) return;

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This donor has not submitted their health info yet')));
      return;
    }

    final flaggedAnswers = record.healthAnswers.entries
        .where((e) => e.value)
        .map((e) => MedicalVerificationModel.healthQuestionLabels[e.key])
        .toList();

    final isDecided = request.requesterMedicalStatus == 'approved' ||
        request.requesterMedicalStatus == 'rejected';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${request.acceptedByName ?? "Donor"}\'s health info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight: ${record.weight} kg'),
              Text('Height: ${record.height} cm'),
              Text('Blood pressure: ${record.bloodPressure}'),
              const SizedBox(height: 12),
              const Text('Health screening', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (flaggedAnswers.isEmpty)
                const Text('No health concerns flagged', style: TextStyle(color: Colors.green))
              else
                ...flaggedAnswers.map((q) => Text('⚠ $q',
                    style: const TextStyle(color: Colors.orange, fontSize: 13))),
              const SizedBox(height: 16),
              if (request.requesterMedicalStatus == 'approved')
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('You approved this', style: TextStyle(color: Colors.green)),
                  ],
                )
              else if (request.requesterMedicalStatus == 'rejected')
                Text(
                  'You rejected this${request.requesterMedicalRejectionReason != null ? ": ${request.requesterMedicalRejectionReason}" : ""}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        actions: [
          if (!isDecided) ...[
            TextButton(
              onPressed: () => _rejectMedical(request),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], foregroundColor: Colors.white),
              onPressed: () => _approveMedical(request),
              child: const Text('Approve'),
            ),
          ] else
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
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
          final canEdit = request.status == 'active' || request.status == 'pending';
          final canRequestAgain = request.status == 'accepted' ||
              request.status == 'completed' ||
              request.status == 'fulfilled';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Requested by ${request.requesterName}',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${request.bloodGroup} • ${request.units} units needed',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.local_hospital, size: 13, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    request.city != null && request.city!.isNotEmpty
                                        ? '${request.hospitalName}, ${request.city}'
                                        : request.hospitalName,
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
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
                          if (canEdit) ...[
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              tooltip: 'Edit',
                              onPressed: () => _editRequest(request),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.cancel, color: Colors.orange, size: 20),
                              tooltip: 'Cancel',
                              onPressed: () => _confirmCancel(request),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (canRequestAgain) ...[
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.replay, color: Colors.purple, size: 20),
                              tooltip: 'Request again',
                              onPressed: () => _requestAgain(request),
                            ),
                            const SizedBox(height: 8),
                          ],
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

                  if (canRequestAgain)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.replay, size: 18, color: Colors.purple),
                          label: const Text('Request again'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                          onPressed: () => _requestAgain(request),
                        ),
                      ),
                    ),

                  if (request.status == 'accepted' && request.donorId != null) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, size: 16, color: Colors.purple[700]),
                        const SizedBox(width: 6),
                        const Text('Donor\'s health info',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        if (request.requesterMedicalStatus == 'approved')
                          const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        else if (request.requesterMedicalStatus == 'rejected')
                          const Icon(Icons.cancel, color: Colors.red, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _viewMedicalReport(request),
                        child: Text(request.requesterMedicalStatus == 'approved'
                            ? 'View (approved)'
                            : request.requesterMedicalStatus == 'rejected'
                            ? 'View (rejected)'
                            : 'View & decide'),
                      ),
                    ),
                    if (request.requesterMedicalStatus == 'rejected' &&
                        request.requesterMedicalRejectionReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Your reason: ${request.requesterMedicalRejectionReason}',
                          style: const TextStyle(color: Colors.red, fontSize: 11),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}