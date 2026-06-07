import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class ReturnScreen extends StatefulWidget {
  final String bookingId;
  final String? geofenceId;
  final String vehicleName;
  final double depositVirtual;
  const ReturnScreen({super.key, required this.bookingId, required this.geofenceId,
      required this.vehicleName, required this.depositVirtual});
  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  bool _loading = false;
  bool _done = false;
  bool _geofenceChecked = false;
  bool _geofenceOk = false;
  Map<String, dynamic> _result = {};

  @override
  void initState() {
    super.initState();
    _checkGeofence();
  }

  // Simulasi cek posisi geofence (dalam demo pakai koordinat dummy yang selalu OK)
  Future<void> _checkGeofence() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _geofenceChecked = true;
        _geofenceOk = true;
      });
    }
  }

  Future<void> _processReturn() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.returnVehicle(widget.bookingId,
          lat: -7.7600, lng: 110.3800);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() { _result = res['data'] ?? {}; _done = true; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Gagal'), backgroundColor: AppTheme.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengembalian Kendaraan')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: _done ? _doneView() : _readyView(),
    ),
  );

  Widget _readyView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Info kendaraan
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kendaraan', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(widget.vehicleName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Deposit ditahan: ${_fmt(widget.depositVirtual)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    ),
    const SizedBox(height: 16),

    // Status geofence
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _geofenceChecked
            ? (_geofenceOk ? AppTheme.primaryLight : const Color(0xFFFEE2E2))
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _geofenceChecked
              ? (_geofenceOk ? AppTheme.primary : AppTheme.danger)
              : Colors.black12,
        ),
      ),
      child: Row(children: [
        if (!_geofenceChecked)
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(_geofenceOk ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: _geofenceOk ? AppTheme.primary : AppTheme.danger),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            !_geofenceChecked ? 'Mendeteksi lokasi...' :
            _geofenceOk ? 'Lokasi terdeteksi dalam radius' : 'Di luar titik pengembalian',
            style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: _geofenceChecked
                  ? (_geofenceOk ? AppTheme.primary : AppTheme.danger)
                  : AppTheme.textPrimary,
            ),
          ),
          Text(
            _geofenceChecked && _geofenceOk
                ? 'Anda sudah berada di titik pengembalian yang benar'
                : 'Pastikan kendaraan dikembalikan di titik yang ditentukan',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ])),
      ]),
    ),
    const SizedBox(height: 16),

    // Peringatan denda
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Denda overtime dihitung 1.5x tarif per jam. Deposit dikembalikan setelah pengurangan denda.',
          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
        )),
      ]),
    ),

    const Spacer(),

    // Tombol konfirmasi eksplisit
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_loading || !_geofenceChecked) ? null : _processReturn,
        icon: _loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.flag_rounded),
        label: Text(_loading ? 'Memproses...' : 'Saya Sudah di Titik Kembali'),
      ),
    ),
    const SizedBox(height: 12),
  ]);

  Widget _doneView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(child: Container(width: 80, height: 80,
        decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 48))),
    const SizedBox(height: 16),
    const Center(child: Text('Pengembalian Berhasil!',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12)),
      child: Column(children: [
        _row('Durasi aktual', (_result['overtime_menit'] ?? 0) == 0
            ? 'Tepat waktu' : 'Overtime ${_result['overtime_menit']} menit'),
        _row('Denda overtime', _fmt(_result['penalty_amount']),
            valueColor: (_result['penalty_amount'] ?? 0) > 0 ? AppTheme.danger : AppTheme.primary),
        _row('Deposit dikembalikan', _fmt(_result['deposit_dikembalikan']),
            valueColor: AppTheme.primary),
        _row('Geofence', _result['geofence_valid'] == true ? 'Valid' : 'Di luar radius',
            valueColor: _result['geofence_valid'] == true ? AppTheme.primary : AppTheme.danger),
        _row('Trust Score baru', '${_result['trust_score_baru'] ?? '-'}',
            valueColor: (_result['trust_delta'] ?? 0) >= 0 ? AppTheme.primary : AppTheme.danger),
        _row('Perubahan Skor',
            '${(_result['trust_delta'] ?? 0) >= 0 ? '+' : ''}${_result['trust_delta'] ?? 0}',
            valueColor: (_result['trust_delta'] ?? 0) >= 0 ? AppTheme.primary : AppTheme.danger),
      ]),
    ),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: () => Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
      child: const Text('Kembali ke Beranda'),
    )),
  ]);

  Widget _row(String l, String v, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );
}
