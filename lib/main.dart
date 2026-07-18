import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/request_provider.dart';
import 'providers/hospital_provider.dart';
import 'providers/report_provider.dart';
import 'providers/eligibility_exception_provider.dart';
import 'core/localization/app_locale_provider.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();
  await NotificationService.initFCM();

  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedTheme();

  final localeProvider = AppLocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(MyApp(themeProvider: themeProvider, localeProvider: localeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AppLocaleProvider localeProvider;
  const MyApp({super.key, required this.themeProvider, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DonorProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => EligibilityExceptionProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Smart Blood Donor Network',
            theme: ThemeData(
              colorSchemeSeed: Colors.red,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.red,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: theme.themeMode,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}