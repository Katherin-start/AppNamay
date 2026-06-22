import 'package:dental_namay_app/screens/login_page.dart';
import 'package:dental_namay_app/screens/register_page.dart';
import 'package:dental_namay_app/screens/security_policy_page.dart';
import 'package:dental_namay_app/screens/terms_page.dart';
import 'package:dental_namay_app/screens/home/home_screen.dart';
import 'package:dental_namay_app/screens/profile_photo_screen.dart';
import 'package:dental_namay_app/config/supabase_config.dart';
import 'package:dental_namay_app/providers/auth_provider.dart';
import 'package:dental_namay_app/providers/appointment_provider.dart';
import 'package:dental_namay_app/providers/chat_provider.dart';
import 'package:dental_namay_app/providers/theme_provider.dart';
import 'package:dental_namay_app/providers/assistant_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Paleta global ────────────────────────────────────────────────
const _kBluePrimary = Color(0xFF1D4ED8);
const _kBlueDeep    = Color(0xFF1E3A8A);
const _kBlueLight   = Color(0xFF3B82F6);
const _kRedPrimary  = Color(0xFFDC2626);
// ─────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dental Namay',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: _kBluePrimary,
                secondary: _kRedPrimary,
                surface: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF0F4FF),
              appBarTheme: const AppBarTheme(
                backgroundColor: _kBluePrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBluePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: _kBlueLight,
                secondary: Color(0xFFEF4444),
                surface: Color(0xFF111827),
              ),
              scaffoldBackgroundColor: const Color(0xFF080E1A),
              appBarTheme: const AppBarTheme(
                backgroundColor: _kBlueDeep,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlueLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              useMaterial3: true,
            ),
            home: const AuthGate(),
            routes: {
              '/register': (context) => const RegisterPage(),
              '/terms': (context) => const TermsPage(),
              '/security': (context) => const SecurityPolicyPage(),
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginPage(),
              '/profilePhoto': (context) => const ProfilePhotoScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.initialized) {
          return const Scaffold(
            backgroundColor: _kBlueDeep,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }
        return auth.isLoggedIn ? const HomeScreen() : const LoginPage();
      },
    );
  }
}
