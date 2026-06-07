import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'vendor/vendor_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    Widget dest;
    if (auth.isLoggedIn && auth.isVendor) {
      dest = const VendorHomeScreen();
    } else if (auth.isLoggedIn) {
      dest = const HomeScreen();
    } else {
      dest = const LoginScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.two_wheeler, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 20),
              const Text('RentHub',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('Platform Rental Kendaraan Cerdas',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
