import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/medical_verification_model.dart';

class MedicalVerificationRequestsScreen extends StatefulWidget {
  const MedicalVerificationRequestsScreen({super.key});

  @override
  State<MedicalVerificationRequestsScreen> createState() =>
      _MedicalVerificationRequestsScreenState();
}

class _MedicalVerificationRequestsScreenState
    extends State<MedicalVerificationRequestsScreen> {
  List<MedicalVerificationModel> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    _pending = await donorProvider.fetchPendingVerifications();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approve(MedicalVerificationModel record) async {
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    bool success = await donorProvider.approveMedicalVerification(record.donorId);
    if (success && mounted) {
      setState(() => _pending.remove(record));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Approved')));
    }
  }

  Future<void> _reject(MedicalVerificationModel record) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject submission'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              labelText: 'Reason (shown to donor)', border: OutlineInputBorder()),
          maxLines: 2,
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

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    bool success = await donorProvider.rejectMedicalVerification(
        record.donorId, reasonController.text.trim());
    if (success && mounted) {
      setState(() => _pending.remove(record));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rejected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical verification requests'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
          ? const Center(child: Text('No pending medical verification submissions'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pending.length,
        itemBuilder: (context, index) {
          final record = _pending[index];
          final flaggedAnswers = record.healthAnswers.entries
              .where((e) => e.value)
              .map((e) => MedicalVerificationModel.healthQuestionLabels[e.key])
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weight: ${record.weight} kg  •  Height: ${record.height} cm',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Blood pressure: ${record.bloodPressure}',
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  if (flaggedAnswers.isEmpty)
                    const Text('No health concerns flagged',
                        style: TextStyle(color: Colors.green))
                  else
                    ...flaggedAnswers.map((q) => Text('⚠ $q',
                        style: const TextStyle(color: Colors.orange, fontSize: 12))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _reject(record),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white),
                          onPressed: () => _approve(record),
                          child: const Text('Approve'),
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