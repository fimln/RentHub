import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'smart_access_screen.dart';
import 'home_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String bookingId;
  final String unlockToken;
  final String vehicleId;
  final String vehicleName;
  final String platNomor;
  final DateTime waktuSelesai;
  final double depositVirtual;
  final String? geofenceId;
  final double biayaSewa;
  final double pickupFee;
  final double totalBayar;
  final double saldoSetelah;

  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    required this.unlockToken,
    required this.vehicleId,
    required this.vehicleName,
    required this.platNomor,
    required this.waktuSelesai,
    required this.depositVirtual,
    required this.geofenceId,
    required this.biayaSewa,
    required this.pickupFee,
    required this.totalBayar,
    required this.saldoSetelah,
  });

  String _fmt(double v) => 'Rp${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),

            // Ikon sukses
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 56),
            ),
            const SizedBox(height: 20),
            const Text('Booking Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kendaraan siap, silakan buka via Smart Access',
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),

            const SizedBox(height: 32),

            // Ringkasan booking
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ringkasan Booking',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                _row('Kendaraan', vehicleName),
                _row('Plat', platNomor),
                _row('Biaya Sewa', _fmt(biayaSewa)),
                if (pickupFee > 0) _row('Pickup Fee', _fmt(pickupFee)),
                _row('Deposit (pre-auth)', _fmt(depositVirtual),
                    valueColor: AppTheme.warning),
                const Divider(height: 20),
                _row('Total Dibayar', _fmt(totalBayar), bold: true),
                _row('Sisa Saldo', _fmt(saldoSetelah),
                    valueColor: AppTheme.textSecondary),
              ]),
            ),

            const SizedBox(height: 16),

            // Info pre-auth
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Deposit ditahan. Kendaraan hanya bisa dibuka via tombol di bawah.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                )),
              ]),
            ),

            const Spacer(),

            // CTA utama
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => SmartAccessScreen(
                    bookingId: bookingId,
                    unlockToken: unlockToken,
                    vehicleId: vehicleId,
                    vehicleName: vehicleName,
                    platNomor: platNomor,
                    waktuSelesai: waktuSelesai,
                    depositVirtual: depositVirtual,
                    geofenceId: geofenceId,
                  ),
                )),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Buka Kendaraan'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
              child: const Text('Kembali ke Beranda'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          )),
        ]),
      );
}
