import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../auth/login_screen.dart';
import '../../../core/theme/theme_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emergencyAlerts = true;
  bool _requestUpdates = true;
  bool _donationReminders = true;
  bool _shareLocation = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyAlerts = prefs.getBool('notif_emergency') ?? true;
      _requestUpdates = prefs.getBool('notif_requests') ?? true;
      _donationReminders = prefs.getBool('notif_reminders') ?? true;
      _shareLocation = prefs.getBool('privacy_location') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This will permanently delete your account and sign you out. Your donor profile and requests will remain but will no longer be linked to your login. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete my account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.deleteAccount();
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(authProvider.errorMessage ??
                'Could not delete account. Please log out and log back in, then try again.')));
      }
    }
  }

  Future<void> _showLanguagePicker() async {
    final localeProvider = Provider.of<AppLocaleProvider>(context, listen: false);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get(context, 'select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppStrings.get(context, 'english')),
              value: 'en',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) => Navigator.pop(ctx, value),
            ),
            RadioListTile<String>(
              title: Text(AppStrings.get(context, 'urdu')),
              value: 'ur',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) => Navigator.pop(ctx, value),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await localeProvider.setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<AppLocaleProvider>(context);
    final isUrdu = localeProvider.isUrdu;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.get(context, 'settings'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get(context, 'settings'))),
        body: ListView(
          children: [
            _SectionHeader(AppStrings.get(context, 'appearance')),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: Text(AppStrings.get(context, 'dark_mode')),
                  subtitle: const Text('Applies instantly'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.setDarkMode(value),
                );
              },
            ),
            const Divider(),

            _SectionHeader(AppStrings.get(context, 'notification_preferences')),
            SwitchListTile(
              secondary: const Icon(Icons.emergency),
              title: Text(AppStrings.get(context, 'emergency_alerts')),
              subtitle: Text(AppStrings.get(context, 'emergency_alerts_subtitle')),
              value: _emergencyAlerts,
              onChanged: (value) {
                setState(() => _emergencyAlerts = value);
                _setPref('notif_emergency', value);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.list_alt),
              title: Text(AppStrings.get(context, 'request_updates')),
              subtitle: Text(AppStrings.get(context, 'request_updates_subtitle')),
              value: _requestUpdates,
              onChanged: (value) {
                setState(() => _requestUpdates = value);
                _setPref('notif_requests', value);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.favorite),
              title: Text(AppStrings.get(context, 'donation_reminders')),
              subtitle: Text(AppStrings.get(context, 'donation_reminders_subtitle')),
              value: _donationReminders,
              onChanged: (value) {
                setState(() => _donationReminders = value);
                _setPref('notif_reminders', value);
              },
            ),
            const Divider(),

            _SectionHeader(AppStrings.get(context, 'privacy')),
            SwitchListTile(
              secondary: const Icon(Icons.location_on),
              title: Text(AppStrings.get(context, 'share_location')),
              subtitle: Text(AppStrings.get(context, 'share_location_subtitle')),
              value: _shareLocation,
              onChanged: (value) {
                setState(() => _shareLocation = value);
                _setPref('privacy_location', value);
              },
            ),
            const Divider(),

            _SectionHeader(AppStrings.get(context, 'account')),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              subtitle: const Text('Update your name and phone number'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppStrings.get(context, 'language')),
              subtitle: Text(isUrdu
                  ? AppStrings.get(context, 'urdu')
                  : AppStrings.get(context, 'english')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguagePicker,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(AppStrings.get(context, 'delete_account'),
                  style: const TextStyle(color: Colors.red)),
              subtitle: Text(AppStrings.get(context, 'delete_account_subtitle')),
              onTap: _confirmDeleteAccount,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}