import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const VendorDashboardScreen({super.key, this.onSwitchTab});
  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic> _data = {};
  List<dynamic> _fleet = [];
  List<dynamic> _unreadNotifs = [];
  bool _loading = true;

  static const LatLng _center = LatLng(-7.7972, 110.3688);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getVendorDashboard(),
        ApiService.getVendorFleet(),
        ApiService.getVendorNotifications(),
      ]);
      if (mounted) {
        setState(() {
          if (results[0]['success'] == true) _data = results[0]['data'] ?? {};
          if (results[1]['success'] == true) _fleet = results[1]['data'] ?? [];
          if (results[2]['success'] == true) {
            final all = (results[2]['data'] as List?) ?? [];
            _unreadNotifs = all.where((n) => n['is_read'] != true).toList();
          }
        });
      }
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  String _fmtCurrency(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]}.')}';
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'available': return AppTheme.primary;
      case 'rented': return AppTheme.warning;
      case 'maintenance': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      case 'mobil_sedan': return '🛵';
      case 'mobil_suv': return '🚙';
      case 'minibus': return '🚐';
      default: return '🛵';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final markers = _fleet.where((v) =>
        v['lokasi_lat'] != null && v['lokasi_lng'] != null
    ).map<Marker>((v) {
      final lat = double.tryParse(v['lokasi_lat'].toString()) ?? _center.latitude;
      final lng = double.tryParse(v['lokasi_lng'].toString()) ?? _center.longitude;
      final color = _statusColor(v['status']);
      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 52,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Center(child: Text(_vehicleEmoji(v['jenis']),
                style: const TextStyle(fontSize: 18))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            child: Text(v['plat_nomor'] ?? '-',
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: color)),
          ),
        ]),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_data['nama_vendor'] ?? 'Dashboard Vendor'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Mini-map armada
                  SizedBox(
                    height: 180,
                    child: Stack(children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 12.5,
                          interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.renthub',
                          ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                      // Overlay button "Lihat Penuh"
                      Positioned(
                        bottom: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => widget.onSwitchTab?.call(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.fullscreen_rounded, size: 14, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text('Lihat Penuh',
                                  style: TextStyle(fontSize: 11, color: AppTheme.primary,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                      // Badge jumlah armada
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                          ),
                          child: Text('${_fleet.length} armada',
                              style: const TextStyle(color: Colors.white, fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Pendapatan card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryDark]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Pendapatan Hari Ini',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_fmtCurrency(_data['pendapatan_hari_ini']),
                              style: const TextStyle(color: Colors.white, fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Bulan ini: ${_fmtCurrency(_data['pendapatan_bulan_ini'])}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 10),
                          Text('Saldo akun: ${_fmtCurrency(_data['saldo_akun'])}',
                              style: const TextStyle(color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Kartu langganan
                      _subscriptionCard(),
                      const SizedBox(height: 16),

                      // Stat grid - clickable ke tab yang sesuai
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _statCard('Total Armada', '${_data['total_armada'] ?? 0}',
                              Icons.two_wheeler, AppTheme.primary,
                              onTap: () => widget.onSwitchTab?.call(1)),
                          _statCard('Tersedia', '${_data['unit_tersedia'] ?? 0}',
                              Icons.check_circle_rounded, AppTheme.primary,
                              onTap: () => widget.onSwitchTab?.call(1)),
                          _statCard('Sedang Disewa', '${_data['unit_disewa'] ?? 0}',
                              Icons.drive_eta_rounded, AppTheme.warning,
                              onTap: () => widget.onSwitchTab?.call(3)),
                          _statCard('Maintenance', '${_data['unit_maintenance'] ?? 0}',
                              Icons.build_rounded, AppTheme.danger,
                              onTap: () => widget.onSwitchTab?.call(1)),
                        ],
                      ),

                      // Notifikasi highlight (jika ada yang belum dibaca)
                      if (_unreadNotifs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => widget.onSwitchTab?.call(4),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5E0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.warning.withOpacity(0.4)),
                            ),
                            child: Row(children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications_rounded,
                                      color: AppTheme.warning, size: 24),
                                  Positioned(
                                    top: -4, right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                          color: AppTheme.danger,
                                          shape: BoxShape.circle),
                                      child: Text('${_unreadNotifs.length}',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 9,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_unreadNotifs.length} notifikasi belum dibaca',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13,
                                          color: Color(0xFF92400E)),
                                    ),
                                    Text(
                                      _unreadNotifs.first['judul']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 11,
                                          color: Color(0xFF78350F)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ])),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.warning),
                            ]),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ]),
              ),
      ),
    );
  }

  Widget _subscriptionCard() {
    final kategori = (_data['kategori_langganan'] ?? '-').toString();
    final komisi = _data['komisi_platform'];
    final status = (_data['status_langganan'] ?? '-').toString();
    final jatuhTempo = _data['tanggal_jatuh_tempo']?.toString();
    final maks = _data['maks_armada'];
    final total = _data['total_armada'] ?? 0;
    final isActive = status == 'active';
    final maksLabel = maks == null ? '∞' : maks.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('Langganan ${kategori[0].toUpperCase()}${kategori.length > 1 ? kategori.substring(1) : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.primary : AppTheme.danger).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isActive ? 'Aktif' : 'Suspended',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.primary : AppTheme.danger)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Rating', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B800)),
            const SizedBox(width: 2),
            Text(
              '${(double.tryParse(_data['rating_avg']?.toString() ?? '') ?? 0).toStringAsFixed(1)} '
              '(${_data['total_ulasan'] ?? 0} ulasan)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
        _subRow('Komisi platform', komisi == null ? '-' : '${komisi.toString()}%'),
        _subRow('Armada', '$total / $maksLabel unit'),
        if (jatuhTempo != null && jatuhTempo.isNotEmpty)
          _subRow('Jatuh tempo', jatuhTempo.split('T').first),
        _subRow('Pendapatan total', _fmtCurrency(_data['pendapatan_total'])),
        const Divider(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Biaya antar', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Row(children: [
            Text(_fmtCurrency(_data['biaya_antar']),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            InkWell(
              onTap: _editDeliveryFee,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  Future<void> _editDeliveryFee() async {
    final ctrl = TextEditingController(
        text: (double.tryParse(_data['biaya_antar']?.toString() ?? '') ?? 0).toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Biaya Antar'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
            helperText: 'Biaya pengantaran kendaraan ke penyewa',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (result == null) return;
    final nilai = double.tryParse(result);
    if (nilai == null || nilai < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Masukkan angka yang valid'), backgroundColor: AppTheme.danger));
      }
      return;
    }
    final res = await ApiService.updateVendorProfile({'biaya_antar': nilai});
    if (!mounted) return;
    final ok = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Biaya antar diperbarui' : (res['message'] ?? 'Gagal')),
      backgroundColor: ok ? const Color(0xFF16A34A) : AppTheme.danger,
    ));
    if (ok) {
      setState(() => _data['biaya_antar'] = nilai);
    }
  }

  Widget _subRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _statCard(String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color, size: 24),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: color.withOpacity(0.5)),
            ]),
            const Spacer(),
            Text(value, style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
      );
}
