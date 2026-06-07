// lib/screens/verify_identity_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});
  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final _nikCtrl = TextEditingController();
  final _simCtrl = TextEditingController();
  int _step = 0; // 0=form, 1=loading, 2=success, 3=failed
  Map<String, dynamic> _result = {};
  String _currentStepText = '';

  @override
  void dispose() { _nikCtrl.dispose(); _simCtrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_nikCtrl.text.length != 16 || !RegExp(r'^\d{16}$').hasMatch(_nikCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('NIK harus 16 digit angka'), backgroundColor: AppTheme.danger));
      return;
    }
    if (!RegExp(r'^[A-D]-\d{7,12}$').hasMatch(_simCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Format SIM tidak valid (contoh: A-9876543210)'),
        backgroundColor: AppTheme.danger));
      return;
    }

    setState(() { _step = 1; _currentStepText = 'Menghubungi mock API Dukcapil...'; });
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _currentStepText = 'NIK ditemukan ✓');
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _currentStepText = 'Memvalidasi SIM ke Korlantas...');
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _currentStepText = 'SIM aktif ✓');
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _currentStepText = 'Menghitung Trust Score...');

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?['user_id'];
      if (userId == null) {
        setState(() => _step = 3);
        return;
      }
      final res = await ApiService.verifyIdentity(
        nik: _nikCtrl.text.trim(),
        nomorSim: _simCtrl.text.trim(),
        userId: userId,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        _result = res['data'] ?? {};
        auth.updateUser({'status_verifikasi': 'verified', 'trust_score': _result['trust_score']});
        setState(() => _step = 2);
      } else {
        setState(() { _step = 3; _result = res; });
      }
    } catch (e) {
      if (mounted) setState(() { _step = 3; _result = {'message': e.toString()}; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verifikasi Identitas')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: _step == 0 ? _buildForm()
           : _step == 1 ? _buildLoading()
           : _step == 2 ? _buildSuccess()
           : _buildFailed(),
    ),
  );

  Widget _buildForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.security_rounded, color: AppTheme.primary, size: 22),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Zero-Collateral Verification',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          SizedBox(height: 4),
          Text('NIK Anda diproses sebagai hash terenkripsi. '
              'Tidak ada data asli yang disimpan di server RentHub.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    ),
    const SizedBox(height: 24),
    const Text('Nomor NIK (16 digit)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    const SizedBox(height: 6),
    TextField(
      controller: _nikCtrl,
      keyboardType: TextInputType.number,
      maxLength: 16,
      decoration: const InputDecoration(hintText: '3273010101950001',
          prefixIcon: Icon(Icons.badge_outlined)),
    ),
    const SizedBox(height: 14),
    const Text('Nomor SIM', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    const SizedBox(height: 6),
    TextField(
      controller: _simCtrl,
      decoration: const InputDecoration(hintText: 'A-9876543210',
          prefixIcon: Icon(Icons.card_membership_outlined)),
    ),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, child: ElevatedButton.icon(
      onPressed: _verify,
      icon: const Icon(Icons.verified_user_rounded),
      label: const Text('Verifikasi Identitas'),
    )),
  ]);

  Widget _buildLoading() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const CircularProgressIndicator(color: AppTheme.primary),
    const SizedBox(height: 24),
    Text(_currentStepText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    const Text('Menghubungi Mock API Pemerintah...',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
  ]));

  Widget _buildSuccess() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80,
        decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 50)),
    const SizedBox(height: 20),
    const Text('Identitas Terverifikasi!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text('Trust Score: ${_result['trust_score'] ?? 0}',
        style: const TextStyle(fontSize: 28, color: AppTheme.primary, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text('${_result['delta'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    const SizedBox(height: 8),
    Text('SIM berlaku hingga: ${_result['sim_berlaku_hingga'] ?? '-'}',
        style: const TextStyle(color: AppTheme.textSecondary)),
    const SizedBox(height: 32),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Mulai Menyewa Kendaraan →'),
    )),
  ]));

  Widget _buildFailed() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80,
        decoration: const BoxDecoration(color: Color(0xFFFFE9E9), shape: BoxShape.circle),
        child: const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 50)),
    const SizedBox(height: 20),
    const Text('Verifikasi Gagal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(_result['message'] ?? 'Identitas tidak dapat diverifikasi',
        textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
    const SizedBox(height: 32),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: () => setState(() { _step = 0; _result = {}; }),
      child: const Text('Coba Lagi'),
    )),
  ]));
}
