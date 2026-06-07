import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'return_screen.dart';

class SmartAccessScreen extends StatefulWidget {
  final String bookingId, vehicleId, vehicleName, platNomor;
  final String unlockToken;
  final DateTime waktuSelesai;
  final double depositVirtual;
  final String? geofenceId;

  const SmartAccessScreen({
    super.key,
    required this.bookingId,
    required this.unlockToken,
    required this.vehicleId,
    required this.vehicleName,
    required this.platNomor,
    required this.waktuSelesai,
    required this.depositVirtual,
    required this.geofenceId,
  });
  @override
  State<SmartAccessScreen> createState() => _SmartAccessScreenState();
}

class _SmartAccessScreenState extends State<SmartAccessScreen>
    with TickerProviderStateMixin {
  bool _isUnlocked = false;
  bool _loading = false;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  Map<String, dynamic> _iotStatus = {};
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _remaining = widget.waktuSelesai.difference(DateTime.now());
    _startTimer();
    _loadIotStatus();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = widget.waktuSelesai.difference(DateTime.now());
      if (mounted) setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
    });
  }

  Future<void> _loadIotStatus() async {
    try {
      final result = await ApiService.getIotStatus(widget.vehicleId);
      if (result['success'] == true && mounted) {
        setState(() => _iotStatus = result['data'] ?? {});
      }
    } catch (_) {}
  }

  Future<void> _toggleLock() async {
    setState(() => _loading = true);
    try {
      final aksi = _isUnlocked ? 'lock' : 'unlock';
      final result = await ApiService.unlockVehicle(
        widget.bookingId, aksi,
        unlockToken: aksi == 'unlock' ? widget.unlockToken : null,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _isUnlocked = !_isUnlocked;
          _iotStatus = result['data'] ?? _iotStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isUnlocked ? '🔓 Kendaraan berhasil dibuka' : '🔒 Kendaraan dikunci'),
          backgroundColor: _isUnlocked ? AppTheme.primary : AppTheme.textSecondary,
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Gagal'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppTheme.danger,
      ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
  String get _timerStr {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
  }

  Color get _timerColor {
    final total = widget.waktuSelesai.difference(
        widget.waktuSelesai.subtract(const Duration(hours: 4)));
    final pct = _remaining.inSeconds / 14400;
    if (pct > 0.6) return AppTheme.primary;
    if (pct > 0.3) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Kendaraan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Timer card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(children: [
              const Text('Waktu Tersisa',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(_timerStr,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
                      color: _timerColor, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _remaining.inSeconds / 14400,
                  color: _timerColor,
                  backgroundColor: Colors.black12,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Berakhir: ${widget.waktuSelesai.hour}:${_pad(widget.waktuSelesai.minute)} WIB',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Unlock button card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(children: [
              Text(
                _isUnlocked
                    ? 'Kendaraan terbuka. Selamat berkendara!'
                    : 'Kendaraan terkunci. Tekan untuk membuka.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: _isUnlocked ? 1.0 + _pulseCtrl.value * 0.05 : 1.0,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: _loading ? null : _toggleLock,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isUnlocked ? AppTheme.primary : AppTheme.primaryLight,
                      border: Border.all(color: AppTheme.primary, width: 4),
                      boxShadow: _isUnlocked
                          ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 20, spreadRadius: 4)]
                          : [],
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: AppTheme.primary)
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(
                              _isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                              color: _isUnlocked ? Colors.white : AppTheme.primary,
                              size: 40,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isUnlocked ? 'KUNCI' : 'BUKA',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold,
                                color: _isUnlocked ? Colors.white : AppTheme.primary,
                              ),
                            ),
                          ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Smart unlock via IoT Gateway',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ),
          const SizedBox(height: 16),

          // GPS status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('📍 Lokasi Kendaraan (GPS)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadIotStatus),
              ]),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  _iotRow('Koordinat',
                    '${(_iotStatus['lokasi_lat'] ?? -7.7972).toStringAsFixed(4)}°S, '
                    '${(_iotStatus['lokasi_lng'] ?? 110.3688).toStringAsFixed(4)}°E'),
                  _iotRow('Kecepatan', '${_iotStatus['kecepatan'] ?? 0} km/h'),
                  _iotRow('Status Mesin',
                    _iotStatus['status_mesin'] ?? 'off',
                    valueColor: _iotStatus['status_mesin'] == 'on'
                        ? AppTheme.primary : AppTheme.danger),
                  _iotRow('Status Kunci',
                    _isUnlocked ? 'unlocked' : 'locked',
                    valueColor: _isUnlocked ? AppTheme.primary : AppTheme.warning),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Vehicle info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.map_outlined, color: AppTheme.warning),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Titik Pengembalian',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: Color(0xFF92400E))),
                Text('Radius geofence: 100m • Deposit: '
                    'Rp${widget.depositVirtual.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF78350F))),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menghubungi vendor...'))),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Bantuan'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReturnScreen(
                    bookingId: widget.bookingId,
                    geofenceId: widget.geofenceId,
                    vehicleName: widget.vehicleName,
                    depositVirtual: widget.depositVirtual,
                  ),
                )),
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: const Text('Kembalikan'),
              ),
            ),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _iotRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );
}
