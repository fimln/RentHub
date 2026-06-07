import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class VendorVehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VendorVehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VendorVehicleDetailScreen> createState() => _VendorVehicleDetailScreenState();
}

class _VendorVehicleDetailScreenState extends State<VendorVehicleDetailScreen> {
  Map<String, dynamic>? _iotData;
  bool _iotLoading = true;

  List<dynamic> _bookings = [];
  bool _bookingsLoading = true;
  bool _lockLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIot();
    _loadBookings();
  }

  Future<void> _loadIot() async {
    setState(() => _iotLoading = true);
    try {
      final id = widget.vehicle['vehicle_id']?.toString() ?? '';
      final res = await ApiService.getIotStatus(id);
      if (res['success'] == true && mounted) {
        setState(() => _iotData = res['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _iotLoading = false);
  }

  Future<void> _loadBookings() async {
    setState(() => _bookingsLoading = true);
    try {
      final id = widget.vehicle['vehicle_id']?.toString() ?? '';
      final res = await ApiService.getVendorBookings(vehicleId: id);
      if (res['success'] == true && mounted) {
        setState(() => _bookings = res['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _bookingsLoading = false);
  }

  Future<void> _vendorLock(String aksi) async {
    setState(() => _lockLoading = true);
    try {
      final id = widget.vehicle['vehicle_id']?.toString() ?? '';
      final res = await ApiService.vendorLockVehicle(id, aksi);
      if (mounted) {
        final ok = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? (ok ? 'Berhasil' : 'Gagal')),
          backgroundColor: ok ? AppTheme.primary : AppTheme.danger,
        ));
        if (ok) await _loadIot();
      }
    } finally {
      if (mounted) setState(() => _lockLoading = false);
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor':
        return '🛵';
      default:
        return '🛵';
    }
  }

  String _formatDt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _iotVal(String key) {
    final src = _iotData ?? widget.vehicle;
    return src[key]?.toString() ?? '-';
  }

  double? _lat() {
    final src = _iotData ?? widget.vehicle;
    return double.tryParse(src['lokasi_lat']?.toString() ?? '');
  }

  double? _lng() {
    final src = _iotData ?? widget.vehicle;
    return double.tryParse(src['lokasi_lng']?.toString() ?? '');
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return AppTheme.primary;
      case 'rented':
      case 'active':
        return AppTheme.accent;
      case 'maintenance':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _mesinColor(String? val) {
    switch (val?.toLowerCase()) {
      case 'on':
        return AppTheme.primary;
      case 'idle':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  Color _paymentColor(String? val) {
    switch (val?.toLowerCase()) {
      case 'paid':
        return AppTheme.primary;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.danger;
    }
  }

  Widget _badge(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        border: Border.all(color: bg.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: bg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onRefresh}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const Spacer(),
        if (onRefresh != null)
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primary),
          ),
      ],
    );
  }

  Widget _buildVehicleHeader() {
    final v = widget.vehicle;
    final jenis = v['jenis_kendaraan']?.toString();
    final merek = v['merek']?.toString() ?? '';
    final model = v['model']?.toString() ?? '';
    final tahun = v['tahun']?.toString() ?? '';
    final plat = v['plat_nomor']?.toString() ?? '-';
    final status = v['status']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Text(_vehicleEmoji(jenis), style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$merek $model $tahun',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(plat, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _badge(status, _statusColor(status)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIotSection() {
    final mesin = _iotVal('status_mesin');
    final kunci = _iotVal('status_kunci');
    final kecepatan = _iotData != null
        ? _iotData!['kecepatan']?.toString() ?? widget.vehicle['kecepatan']?.toString() ?? '-'
        : widget.vehicle['kecepatan']?.toString() ?? '-';
    final update = _iotData != null
        ? _iotData!['waktu_update']?.toString()
        : widget.vehicle['iot_update']?.toString();

    final lat = _lat();
    final lng = _lng();
    final hasLocation = lat != null && lng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Lokasi & Status IoT', onRefresh: _loadIot),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: _iotLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iotRow(Icons.power_settings_new_rounded, 'Mesin', mesin,
                            dotColor: _mesinColor(mesin)),
                        const SizedBox(width: 24),
                        _iotRow(Icons.lock_rounded, 'Kunci', kunci),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _iotRow(Icons.speed_rounded, 'Kecepatan', '$kecepatan km/h'),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _iotRow(Icons.access_time_rounded, 'Update', _formatDt(update)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: hasLocation
                          ? SizedBox(
                              height: 180,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(lat, lng),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.renthub.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(lat, lng),
                                        width: 36,
                                        height: 44,
                                        alignment: Alignment.topCenter,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: const [
                                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                                ],
                                              ),
                                              child: const Icon(Icons.two_wheeler,
                                                  color: Colors.white, size: 18),
                                            ),
                                            CustomPaint(
                                              size: const Size(12, 8),
                                              painter: _PinTipPainter(color: AppTheme.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              height: 80,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Lokasi tidak tersedia',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _sectionHeader('Kontrol Kunci (Vendor)'),
        const SizedBox(height: 8),
        if (_lockLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ))
        else
          Row(children: [
            Expanded(child: _lockBtn('Buka', Icons.lock_open_rounded, AppTheme.primary, () => _vendorLock('unlock'))),
            const SizedBox(width: 8),
            Expanded(child: _lockBtn('Kunci Paksa', Icons.lock_rounded, const Color(0xFF92400E), () => _vendorLock('force_lock'))),
            const SizedBox(width: 8),
            Expanded(child: _lockBtn('Darurat', Icons.gpp_maybe_rounded, AppTheme.danger, () => _vendorLock('emergency_lock'))),
          ]),
      ],
    );
  }

  Widget _lockBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ]),
      );

  Widget _iotRow(IconData icon, String label, String value, {Color? dotColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        if (dotColor != null) ...[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildBookingsSection() {
    final active = _bookings.where((b) => b['status_booking']?.toString().toLowerCase() == 'active').toList();
    final others = _bookings.where((b) => b['status_booking']?.toString().toLowerCase() != 'active').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Riwayat Pemesanan'),
        const SizedBox(height: 10),
        if (_bookingsLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('Belum ada riwayat pemesanan',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          )
        else ...[
          if (active.isNotEmpty) ...[
            _subsectionLabel('Aktif'),
            const SizedBox(height: 6),
            ...active.map(_buildBookingCard),
            const SizedBox(height: 12),
          ],
          if (others.isNotEmpty) ...[
            _subsectionLabel('Selesai / Lainnya'),
            const SizedBox(height: 6),
            ...others.map(_buildBookingCard),
          ],
        ],
      ],
    );
  }

  Widget _subsectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary));
  }

  Widget _buildBookingCard(dynamic booking) {
    final nama = booking['nama_penyewa']?.toString() ?? booking['user_name']?.toString() ?? '-';
    final statusBooking = booking['status_booking']?.toString() ?? '-';
    final statusPayment = booking['status_payment']?.toString() ?? '-';
    final mulai = _formatDt(booking['waktu_mulai']?.toString());
    final selesai = _formatDt(booking['waktu_selesai']?.toString());
    final total = booking['total_bayar'];
    final totalStr = total != null
        ? 'Rp${double.tryParse(total.toString())?.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') ?? total}'
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nama,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _badge(statusBooking, _statusColor(statusBooking)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$mulai  →  $selesai',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(totalStr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              _badge(statusPayment, _paymentColor(statusPayment)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final merek = v['merek']?.toString() ?? '';
    final model = v['model']?.toString() ?? '';
    final tahun = v['tahun']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('$merek $model $tahun'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleHeader(),
            const SizedBox(height: 20),
            _buildIotSection(),
            const SizedBox(height: 20),
            _buildBookingsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PinTipPainter old) => old.color != color;
}
