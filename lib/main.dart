import 'package:dental_namay_app/screens/login_page.dart';
import 'package:dental_namay_app/screens/register_page.dart';
import 'package:dental_namay_app/screens/security_policy_page.dart';
import 'package:dental_namay_app/screens/terms_page.dart';
import 'package:dental_namay_app/screens/home/home_screen.dart';
import 'package:dental_namay_app/screens/profile_photo_screen.dart';
import 'package:dental_namay_app/config/supabase_config.dart';
import 'package:dental_namay_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dental Namay',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1e3a8a)),
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
          return Scaffold(
            backgroundColor: const Color(0xFF1e3a8a),
            body: const Center(
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
