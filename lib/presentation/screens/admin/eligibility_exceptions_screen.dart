import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/eligibility_exception_provider.dart';
import '../../../data/models/eligibility_exception_model.dart';

class EligibilityExceptionsScreen extends StatefulWidget {
  const EligibilityExceptionsScreen({super.key});

  @override
  State<EligibilityExceptionsScreen> createState() => _EligibilityExceptionsScreenState();
}

class _EligibilityExceptionsScreenState extends State<EligibilityExceptionsScreen> {
  List<EligibilityExceptionModel> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<EligibilityExceptionProvider>(context, listen: false);
    _pending = await provider.fetchPending();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approve(EligibilityExceptionModel exception) async {
    final provider = Provider.of<EligibilityExceptionProvider>(context, listen: false);
    bool success = await provider.approve(exception.id);
    if (success && mounted) {
      setState(() => _pending.remove(exception));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Early donation approved')));
    }
  }

  Future<void> _reject(EligibilityExceptionModel exception) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject this request'),
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

    final provider = Provider.of<EligibilityExceptionProvider>(context, listen: false);
    bool success = await provider.reject(exception.id, reasonController.text.trim());
    if (success && mounted) {
      setState(() => _pending.remove(exception));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rejected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Early donation requests'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
          ? const Center(child: Text('No pending early-donation requests'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pending.length,
        itemBuilder: (context, index) {
          final exception = _pending[index];
          final daysEarly = exception.nextEligibleDate
              .difference(DateTime.now())
              .inDays;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exception.donorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                      'Last donation: ${exception.lastDonationDate.toLocal().toString().split(' ')[0]}'),
                  Text(
                      'Next eligible date: ${exception.nextEligibleDate.toLocal().toString().split(' ')[0]}'),
                  if (daysEarly > 0)
                    Text('Requesting ${daysEarly} day${daysEarly == 1 ? "" : "s"} early',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Text('Donor\'s reason: ${exception.reason}'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _reject(exception),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                          onPressed: () => _approve(exception),
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