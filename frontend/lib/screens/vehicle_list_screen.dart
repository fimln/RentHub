import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'vehicle_detail_screen.dart';
import 'verify_identity_screen.dart';
import 'notification_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});
  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<dynamic> _vehicles = [];
  bool _loading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Motor', 'Mobil', 'Minibus', 'Truk'];
  final Map<String, String> _filterMap = {
    'Semua': '',
    'Motor': 'motor',
    'Mobil': 'mobil_sedan',
    'Minibus': 'minibus',
    'Truk': 'truk',
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final jenis = _filterMap[_selectedFilter];
      final result = await ApiService.getVehicles(jenis: jenis!.isEmpty ? null : jenis);
      if (result['success'] == true) {
        setState(() => _vehicles = result['data'] ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kendaraan: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      default: return '🛵';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'available': return AppTheme.primary;
      case 'rented': return AppTheme.warning;
      case 'maintenance': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'available': return 'Tersedia';
      case 'rented': return 'Disewa';
      case 'maintenance': return 'Maintenance';
      default: return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 185, // Ditambah sedikit untuk ruang napas
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primary,
                // Padding bawah dikurangi dari 16 ke 12 untuk mencegah tabrakan
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Halo, ${user?['nama']?.split(' ').first ?? 'Pengguna'} 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Text('Yogyakarta, Jawa Tengah',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    
                    // --- TRUST SCORE BAR (FIXED OVERFLOW) ---
                    GestureDetector(
                      onTap: () {
                        if (user?['status_verifikasi'] != 'verified') {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const VerifyIdentityScreen()));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // FittedBox akan memaksa Row mengecil jika ruang kurang 1.5 pixel
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Trust Score',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                              Text('${user?['trust_score'] ?? 0}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ]),
                            const SizedBox(width: 12),
                            const SizedBox(height: 30, child: VerticalDivider(color: Colors.white30)),
                            const SizedBox(width: 12),
                            // Constraints diberikan agar Column di dalam Row punya batas lebar
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user?['status_verifikasi'] == 'verified'
                                        ? '✓ Terverifikasi'
                                        : '⚠ Belum Verifikasi — Tap',
                                    style: const TextStyle(color: Colors.white, fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: (user?['trust_score'] ?? 0) / 100,
                                    backgroundColor: Colors.white30,
                                    color: Colors.white,
                                    minHeight: 4,
                                  ),
                                ]
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = f);
                        _loadVehicles();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(f,
                            style: TextStyle(
                              color: active ? Colors.white : AppTheme.textSecondary,
                              fontSize: 13, fontWeight: FontWeight.w500,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Map area
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFC8E8C0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                CustomPaint(painter: _MapPainter(), size: Size.infinite),
                ...[
                  const _MapMarker(left: 0.3, top: 0.25, emoji: '🛵', price: 'Rp45rb'),
                  const _MapMarker(left: 0.55, top: 0.55, emoji: '🛵', price: 'Rp120rb'),
                  const _MapMarker(left: 0.75, top: 0.22, emoji: '🚐', price: 'Rp200rb'),
                  const _MapMarker(left: 0.15, top: 0.62, emoji: '🛵', price: 'Rp45rb'),
                ],
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.45,
                  top: 70,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 8, spreadRadius: 4)],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 8, right: 12,
                  child: Text('Live Map — Simulasi GPS',
                      style: TextStyle(fontSize: 10, color: Colors.black45)),
                ),
              ]),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Kendaraan Terdekat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${_vehicles.length} unit',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
          ),

          // Vehicle list logic
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_vehicles.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Tidak ada kendaraan tersedia')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final v = _vehicles[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VehicleDetailScreen(vehicle: v))),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(_vehicleEmoji(v['jenis']),
                                style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text('${v['merek']} ${v['model']} ${v['tahun']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(v['status']).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_statusLabel(v['status']),
                                  style: TextStyle(fontSize: 10, color: _statusColor(v['status']),
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text('📍 ${v['nama_vendor']} • ${v['kota'] ?? 'Yogyakarta'}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF5B800), size: 14),
                            Text(' ${v['rating_avg'] ?? '4.5'} (${v['total_ulasan'] ?? 0})',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(
                            'Rp${_formatNum(v['tarif_per_hari'] ?? v['tarif_per_jam'])}',
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 15, color: AppTheme.primary),
                          ),
                          const Text('/hari', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ]),
                      ]),
                    ),
                  );
                },
                childCount: _vehicles.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  String _formatNum(dynamic n) {
    if (n == null) return '0';
    final num = double.tryParse(n.toString()) ?? 0;
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(0)}rb';
    return num.toStringAsFixed(0);
  }
}

class _MapMarker extends StatelessWidget {
  final double left, top;
  final String emoji, price;
  const _MapMarker({required this.left, required this.top,
      required this.emoji, required this.price});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: 160 * top,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Text(price, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = const Color(0xFFD4D4D4).withOpacity(0.7)..strokeWidth = 8;
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), roadPaint);
    final thinRoad = Paint()..color = const Color(0xFFDCDCDC).withOpacity(0.5)..strokeWidth = 5;
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), thinRoad);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), thinRoad);
  }
  @override
  bool shouldRepaint(_) => false;
}