import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'checkout_screen.dart';
import 'verify_identity_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});
  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  List<dynamic> _geofences = [];
  String? _selectedGeofenceId;
  int _durasiHari = 1;
  bool _manualHari = false;
  final _manualCtrl = TextEditingController();

  String _metodePengambilan = 'ambil_sendiri';
  double _deliveryFee = 0;

  bool _loadingGeo = true;
  bool _loadingEstimate = false;
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;

  double _biayaSewa = 0;
  double _pickupFee = 0;
  double _depositVirtual = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
    _loadReviews();
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final res = await ApiService.getVehicleReviews(widget.vehicle['vehicle_id']);
      if (res['success'] == true && mounted) setState(() => _reviews = res['data'] ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadGeofences() async {
    try {
      final result = await ApiService.getGeofences();
      if (result['success'] == true && mounted) {
        setState(() {
          _geofences = result['data'] ?? [];
          final garasi = _geofences.firstWhere(
            (g) => g['tipe'] == 'vendor_garage' && double.parse(g['pickup_fee'].toString()) == 0,
            orElse: () => _geofences.isNotEmpty ? _geofences[0] : null,
          );
          _selectedGeofenceId = garasi?['geofence_id'];
        });
        await _fetchEstimate();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  Future<void> _fetchEstimate() async {
    if (!mounted) return;
    setState(() => _loadingEstimate = true);
    try {
      final result = await ApiService.estimateBooking(
        vehicleId: widget.vehicle['vehicle_id'],
        durasiHari: _durasiHari,
        geofenceId: _selectedGeofenceId,
        metode: _metodePengambilan,
      );
      if (result['success'] == true && mounted) {
        final d = result['data'] as Map<String, dynamic>;
        setState(() {
          _biayaSewa      = (d['biaya_sewa']     as num).toDouble();
          _pickupFee      = (d['pickup_fee']      as num).toDouble();
          _depositVirtual = (d['deposit_virtual'] as num).toDouble();
          _total          = (d['total']           as num).toDouble();
          _deliveryFee    = d['delivery_fee'] != null
              ? (d['delivery_fee'] as num).toDouble()
              : 0;
        });
      }
    } catch (_) {
      // Fallback ke kalkulasi lokal jika API gagal
      final tarifPerHari = widget.vehicle['tarif_per_hari'] != null
          ? double.parse(widget.vehicle['tarif_per_hari'].toString())
          : 70000.0;
      double fee = 0;
      if (_selectedGeofenceId != null) {
        final geo = _geofences.firstWhere(
          (g) => g['geofence_id'] == _selectedGeofenceId,
          orElse: () => {'pickup_fee': 0},
        );
        fee = double.parse(geo['pickup_fee'].toString());
      }
      final sewa = tarifPerHari * _durasiHari;
      final deposit = sewa * 0.5 < 150000 ? 150000.0 : sewa * 0.5;
      if (mounted) {
        setState(() {
          _biayaSewa      = sewa;
          _pickupFee      = fee;
          _depositVirtual = deposit;
          _total          = sewa + fee + deposit;
          _deliveryFee    = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingEstimate = false);
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      default: return '🛵';
    }
  }

  String _fmt(double v) => 'Rp${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  double get _tarifPerHari {
    if (widget.vehicle['tarif_per_hari'] != null) {
      return double.parse(widget.vehicle['tarif_per_hari'].toString());
    }
    return 70000.0;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final fitur = (v['fitur'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('${v['merek']} ${v['model']}')),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero area
          Container(
            width: double.infinity,
            color: AppTheme.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              Text(_vehicleEmoji(v['jenis']), style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('● Tersedia',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Text('${v['plat_nomor']}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title & tarif
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text('${v['merek']} ${v['model']} ${v['tahun']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmt(_tarifPerHari),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const Text('/hari', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.store_rounded, size: 14, color: AppTheme.textSecondary),
                Expanded(
                  child: Text(' ${v['nama_vendor']} • ${v['kota'] ?? 'Yogyakarta'}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
                if (v['vendor_rating'] != null) ...[
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5B800)),
                  Text(' ${(double.tryParse(v['vendor_rating'].toString()) ?? 0).toStringAsFixed(1)} vendor',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF5B800), size: 16),
                Text(' ${v['rating_avg']} (${v['total_ulasan']} ulasan)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),

              // Fitur badges
              if (fitur.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: fitur.map<Widget>((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(f.toString(),
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w500)),
                )).toList()),
              ],

              const SizedBox(height: 16),
              const Divider(),

              // Booking form
              const Text('Detail Pemesanan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // Durasi slider
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Durasi Sewa', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$_durasiHari Hari',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ]),
              if (!_manualHari) ...[
                Slider(
                  value: _durasiHari.toDouble().clamp(1, 7),
                  min: 1, max: 7,
                  divisions: 6,
                  activeColor: AppTheme.primary,
                  label: '$_durasiHari Hari',
                  onChanged: (val) => setState(() => _durasiHari = val.toInt()),
                  onChangeEnd: (_) => _fetchEstimate(),
                ),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('1 hari', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text('7 hari', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Text('Lebih dari 7 hari?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                if (!_manualHari)
                  GestureDetector(
                    onTap: () => setState(() {
                      _manualHari = true;
                      _manualCtrl.text = '$_durasiHari';
                    }),
                    child: const Text('Masukkan manual',
                        style: TextStyle(fontSize: 12, color: AppTheme.primary, decoration: TextDecoration.underline)),
                  )
                else
                  Expanded(
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Jumlah hari',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onSubmitted: (val) {
                            final hari = int.tryParse(val);
                            if (hari != null && hari >= 1) {
                              setState(() => _durasiHari = hari);
                              _fetchEstimate();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          final hari = int.tryParse(_manualCtrl.text);
                          if (hari != null && hari >= 1) {
                            setState(() {
                              _durasiHari = hari;
                              if (hari <= 7) _manualHari = false;
                            });
                            _fetchEstimate();
                          }
                        },
                        child: const Text('OK'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _manualHari = false;
                          _durasiHari = _durasiHari.clamp(1, 7);
                        }),
                        child: const Text('Batal'),
                      ),
                    ]),
                  ),
              ]),

              const SizedBox(height: 16),

              // Geofence picker
              const Text('Titik Pengembalian',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (_loadingGeo)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else
                ..._geofences.map((geo) {
                  final fee = double.parse(geo['pickup_fee'].toString());
                  final selected = _selectedGeofenceId == geo['geofence_id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedGeofenceId = geo['geofence_id']);
                      _fetchEstimate();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.primary : Colors.black12,
                          width: selected ? 2 : 1,
                        ),
                        color: selected ? AppTheme.primaryLight : Colors.white,
                      ),
                      child: Row(children: [
                        Icon(Icons.location_on_rounded,
                            color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(geo['nama_lokasi'],
                              style: TextStyle(fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ),
                        Text(fee == 0 ? 'Gratis' : '+${_fmt(fee)}',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: fee == 0 ? AppTheme.primary : AppTheme.warning,
                            )),
                      ]),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Metode Pengambilan
              const Text('Metode Pengambilan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () {
                    setState(() => _metodePengambilan = 'ambil_sendiri');
                    _fetchEstimate();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _metodePengambilan == 'ambil_sendiri' ? AppTheme.primary : Colors.black12,
                        width: _metodePengambilan == 'ambil_sendiri' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: _metodePengambilan == 'ambil_sendiri' ? AppTheme.primaryLight : Colors.white,
                    ),
                    child: Column(children: [
                      Icon(Icons.directions_walk_rounded,
                          color: _metodePengambilan == 'ambil_sendiri' ? AppTheme.primary : AppTheme.textSecondary),
                      const SizedBox(height: 4),
                      Text('Ambil Sendiri',
                          style: TextStyle(fontSize: 12,
                              color: _metodePengambilan == 'ambil_sendiri' ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const Text('Gratis', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                    ]),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () {
                    setState(() => _metodePengambilan = 'diantar');
                    _fetchEstimate();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _metodePengambilan == 'diantar' ? AppTheme.primary : Colors.black12,
                        width: _metodePengambilan == 'diantar' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: _metodePengambilan == 'diantar' ? AppTheme.primaryLight : Colors.white,
                    ),
                    child: Column(children: [
                      Icon(Icons.delivery_dining_rounded,
                          color: _metodePengambilan == 'diantar' ? AppTheme.primary : AppTheme.textSecondary),
                      const SizedBox(height: 4),
                      Text('Diantar',
                          style: TextStyle(fontSize: 12,
                              color: _metodePengambilan == 'diantar' ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                      Text(_deliveryFee > 0 ? '+${_fmt(_deliveryFee)}' : 'Lihat harga',
                          style: const TextStyle(fontSize: 11, color: AppTheme.warning)),
                    ]),
                  ),
                )),
              ]),

              const SizedBox(height: 16),
              const Divider(),

              // Price breakdown
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Rincian Biaya',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (_loadingEstimate)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ]),
              const SizedBox(height: 10),
              _priceRow('Biaya sewa ($_durasiHari hari)', _fmt(_biayaSewa)),
              _priceRow('Pickup fee', _fmt(_pickupFee)),
              if (_deliveryFee > 0) _priceRow('Biaya pengiriman', _fmt(_deliveryFee)),
              _priceRow('Deposit virtual (ditahan)', _fmt(_depositVirtual),
                  valueColor: AppTheme.warning),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(_fmt(_total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Deposit dikembalikan penuh jika tidak ada overtime',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (v['status'] != 'available' || _loadingEstimate || _total == 0) ? null : () {
                    if (user?['status_verifikasi'] != 'verified') {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const VerifyIdentityScreen()));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        vehicle: v,
                        durasiJam: _durasiHari * 24,
                        geofenceId: _selectedGeofenceId,
                        biayaSewa: _biayaSewa,
                        pickupFee: _pickupFee,
                        depositVirtual: _depositVirtual,
                        total: _total,
                        metodePengambilan: _metodePengambilan,
                        durasiHari: _durasiHari,
                      ),
                    ));
                  },
                  child: Text(v['status'] != 'available'
                      ? 'Tidak Tersedia'
                      : 'Lanjut ke Pembayaran →'),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Ulasan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (!_loadingReviews)
                  Text('${_reviews.length} ulasan',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              const SizedBox(height: 10),
              if (_loadingReviews)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else if (_reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Belum ada ulasan untuk kendaraan ini',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                )
              else
                ..._reviews.take(5).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(r['nama_penyewa'] ?? 'Pengguna',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Row(children: List.generate(5, (i) => Icon(
                        i < (r['rating'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF5B800), size: 14))),
                    ]),
                    if (r['komentar'] != null && r['komentar'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r['komentar'].toString(),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ]),
                )),
              const SizedBox(height: 20),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );
}
