import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../../../data/models/medical_verification_model.dart';

class MedicalVerificationScreen extends StatefulWidget {
  const MedicalVerificationScreen({super.key});

  @override
  State<MedicalVerificationScreen> createState() => _MedicalVerificationScreenState();
}

class _MedicalVerificationScreenState extends State<MedicalVerificationScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bpController = TextEditingController();
  final Map<String, bool> _answers = {
    for (final key in MedicalVerificationModel.healthQuestionKeys) key: false
  };

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasExisting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      final existing = await donorProvider.fetchMedicalVerification(user.uid);
      if (existing != null) {
        _hasExisting = true;
        _weightController.text = existing.weight.toString();
        _heightController.text = existing.height.toString();
        _bpController.text = existing.bloodPressure;
        for (final key in MedicalVerificationModel.healthQuestionKeys) {
          _answers[key] = existing.healthAnswers[key] ?? false;
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (weight == null || height == null || _bpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in weight, height, and blood pressure')));
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final record = MedicalVerificationModel(
      donorId: user.uid,
      weight: weight,
      height: height,
      bloodPressure: _bpController.text.trim(),
      healthAnswers: _answers,
      submittedAt: DateTime.now(),
    );

    bool success = await donorProvider.submitMedicalVerification(record);
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Saved — requesters will see this after you accept their request'
              : 'Something went wrong, please try again')));
      if (success) {
        setState(() => _hasExisting = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasExisting
                          ? 'This is visible to requesters after you accept their blood request.'
                          : 'Fill this in so requesters can review your health info once you accept their request.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Personal information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Weight (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Height (cm)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bpController,
              decoration: const InputDecoration(
                  labelText: 'Blood pressure (e.g. 120/80)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Health questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Answer honestly — this helps keep every donation safe',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 8),
            ...MedicalVerificationModel.healthQuestionKeys.map((key) {
              return SwitchListTile(
                title: Text(MedicalVerificationModel.healthQuestionLabels[key]!),
                value: _answers[key] ?? false,
                onChanged: (value) => setState(() => _answers[key] = value),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_hasExisting ? 'Update' : 'Save'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}