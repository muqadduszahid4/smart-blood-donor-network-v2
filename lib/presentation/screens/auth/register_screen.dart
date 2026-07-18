import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'donor';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Smart Blood Network',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your details help save lives faster',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                const Text('I am registering as a:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Donor'),
                      selected: _selectedRole == 'donor',
                      onSelected: (_) => setState(() => _selectedRole = 'donor'),
                    ),
                    ChoiceChip(
                      label: const Text('Requester'),
                      selected: _selectedRole == 'requester',
                      onSelected: (_) => setState(() => _selectedRole = 'requester'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [],
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (authProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        bool success = await authProvider.register(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );

                        if (success) {
                          final uid = authProvider.currentUser?.uid;
                          if (uid != null) {
                            try {
                              await authProvider.saveUserProfile(
                                uid,
                                _nameController.text.trim(),
                                _emailController.text.trim(),
                                _selectedRole,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'Account created, but saving your profile details failed: $e')));
                              }
                            }
                          }

                          // Sign the new account out immediately, so the user
                          // must log in fresh rather than being auto-dropped
                          // into their dashboard.
                          await authProvider.logout();

                          if (context.mounted) {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Account created 🎉'),
                                content: const Text(
                                    'Please log in with your new email and password to continue.'),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Go to login'),
                                  ),
                                ],
                              ),
                            );
                            if (context.mounted) {
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()));
                            }
                          }
                        }
                      }
                    },
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}