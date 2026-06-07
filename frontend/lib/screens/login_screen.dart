import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'vendor/vendor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _vendorMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool ok;
    if (_vendorMode) {
      ok = await auth.loginVendor(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => _vendorMode ? const VendorHomeScreen() : const HomeScreen(),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login gagal'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.two_wheeler,
                          color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 16),
                    const Text('RentHub',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Platform Rental Kendaraan Cerdas',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 32),

                // Mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vendorMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_vendorMode ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Penyewa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_vendorMode ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vendorMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _vendorMode ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Vendor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _vendorMode ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Zero collateral info (penyewa only)
                if (!_vendorMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.security_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Zero-Collateral Verification',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryDark, fontSize: 12)),
                        Text('Tidak perlu menyerahkan KTP fisik',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: _vendorMode ? 'email@vendor.id' : 'email@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 14),

                // Password field
                const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_vendorMode ? 'Masuk sebagai Vendor' : 'Masuk'),
                  ),
                ),
                const SizedBox(height: 16),

                // Demo credentials
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Demo Credentials:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF92400E))),
                    const SizedBox(height: 4),
                    if (!_vendorMode) ...[
                      const Text('demo@renthub.id  /  demo1234',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      const Text('poor@renthub.id  /  demo1234  (saldo rendah)',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                    ] else ...[
                      const Text('pakhaji@rental.id  /  vendor@123',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      const Text('motorku@rental.id  /  vendor@123',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),

                if (!_vendorMode)
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: RichText(text: const TextSpan(
                        text: 'Belum punya akun? ',
                        style: TextStyle(color: Color(0xFF6B7A8D), fontSize: 13),
                        children: [TextSpan(text: 'Daftar sekarang',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))],
                      )),
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
