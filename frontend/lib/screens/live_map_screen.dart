import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'vehicle_detail_screen.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<dynamic> _vehicles = [];
  List<dynamic> _geofences = [];
  bool _loading = true;
  Timer? _pollTimer;
  final MapController _mapController = MapController();

  static const LatLng _center = LatLng(-7.7972, 110.3688);

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadVehicles());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadVehicles(), _loadGeofences()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadVehicles() async {
    try {
      final res = await ApiService.getVehicles(status: 'available');
      if (res['success'] == true && mounted) {
        setState(() => _vehicles = res['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _loadGeofences() async {
    try {
      final res = await ApiService.getGeofences();
      if (res['success'] == true && mounted) {
        setState(() => _geofences = res['data'] ?? []);
      }
    } catch (_) {}
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      default: return '🛵';
    }
  }

  String _fmtPrice(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/hari';
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return 2 * R * asin(sqrt(a));
  }

  Widget _buildVehiclePin(String emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        CustomPaint(
          size: const Size(14, 10),
          painter: _PinTipPainter(color: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildLocationPin(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 19),
        ),
        CustomPaint(
          size: const Size(12, 9),
          painter: _PinTipPainter(color: color),
        ),
      ],
    );
  }

  void _showNearbyVehicles(double lat, double lng) {
    final withDist = _vehicles
        .where((v) => v['lokasi_lat'] != null && v['lokasi_lng'] != null)
        .map((v) {
      final vLat = double.tryParse(v['lokasi_lat'].toString()) ?? lat;
      final vLng = double.tryParse(v['lokasi_lng'].toString()) ?? lng;
      final d = _haversineKm(lat, lng, vLat, vLng);
      final label = d < 1 ? '${(d * 1000).round()} m' : '${d.toStringAsFixed(1)} km';
      return {'v': v, 'd': d, 'label': label};
    }).toList()
      ..sort((a, b) => (a['d'] as double).compareTo(b['d'] as double));

    final items = withDist.take(8).map((e) => _SheetItem(
      vehicle: e['v'] as Map,
      info: e['label'] as String,
    )).toList();

    _showVehicleSheet(title: 'Kendaraan Terdekat', items: items);
  }

  void _showRentalVehicles(dynamic geofence) {
    final vendorId = geofence['vendor_id'];
    final namaLokasi = geofence['nama_lokasi'] as String? ?? 'Lokasi Rental';
    List<_SheetItem> items;

    if (vendorId != null) {
      items = _vehicles
          .where((v) => v['vendor_id'] == vendorId)
          .map((v) => _SheetItem(vehicle: v as Map, info: v['nama_vendor'] ?? ''))
          .toList();
    } else {
      final gLat = double.tryParse(geofence['latitude'].toString()) ?? _center.latitude;
      final gLng = double.tryParse(geofence['longitude'].toString()) ?? _center.longitude;
      final withDist = _vehicles
          .where((v) => v['lokasi_lat'] != null && v['lokasi_lng'] != null)
          .map((v) {
        final d = _haversineKm(gLat, gLng,
            double.tryParse(v['lokasi_lat'].toString()) ?? gLat,
            double.tryParse(v['lokasi_lng'].toString()) ?? gLng);
        return {'v': v, 'd': d, 'label': d < 1 ? '${(d * 1000).round()} m' : '${d.toStringAsFixed(1)} km'};
      }).toList()
        ..sort((a, b) => (a['d'] as double).compareTo(b['d'] as double));
      items = withDist.take(8).map((e) => _SheetItem(
        vehicle: e['v'] as Map,
        info: e['label'] as String,
      )).toList();
    }

    _showVehicleSheet(title: namaLokasi, items: items);
  }

  void _showVehicleSheet({required String title, required List<_SheetItem> items}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${items.length} unit', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Expanded(child: Center(
                child: Text('Tidak ada kendaraan tersedia',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ))
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final v = item.vehicle;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(children: [
                        Text(_vehicleEmoji(v['jenis'] as String?),
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${v['merek']} ${v['model']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${v['plat_nomor']} • ${item.info}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(_fmtPrice(v['tarif_per_hari'] ?? v['tarif_per_jam']),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => VehicleDetailScreen(vehicle: v as Map<String, dynamic>)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Sewa'),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleMarkers = _vehicles
        .where((v) => v['lokasi_lat'] != null && v['lokasi_lng'] != null)
        .map<Marker>((v) {
      final lat = double.tryParse(v['lokasi_lat'].toString()) ?? _center.latitude;
      final lng = double.tryParse(v['lokasi_lng'].toString()) ?? _center.longitude;
      return Marker(
        point: LatLng(lat, lng),
        width: 52,
        height: 58,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showNearbyVehicles(lat, lng),
          child: _buildVehiclePin(_vehicleEmoji(v['jenis'] as String?)),
        ),
      );
    }).toList();

    final locationMarkers = _geofences
        .where((g) => g['latitude'] != null && g['longitude'] != null)
        .map<Marker>((g) {
      final lat = double.tryParse(g['latitude'].toString()) ?? _center.latitude;
      final lng = double.tryParse(g['longitude'].toString()) ?? _center.longitude;
      final color = (g['tipe'] == 'vendor_garage') ? AppTheme.accent : Colors.blueGrey;
      return Marker(
        point: LatLng(lat, lng),
        width: 46,
        height: 51,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showRentalVehicles(g),
          child: _buildLocationPin(color),
        ),
      );
    }).toList();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
              Expanded(
                flex: 5,
                child: Stack(children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: _center,
                      initialZoom: 13,
                      interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.renthub',
                      ),
                      MarkerLayer(markers: [...locationMarkers, ...vehicleMarkers]),
                    ],
                  ),
                  Positioned(
                    top: 48, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text('${_vehicles.length} unit tersedia',
                          style: const TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _legendItem(AppTheme.primary, 'Kendaraan'),
                        const SizedBox(height: 3),
                        _legendItem(AppTheme.accent, 'Lokasi Rental'),
                      ]),
                    ),
                  ),
                ]),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: AppTheme.surface,
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(children: [
                        const Text('Kendaraan Tersedia',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.sync_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Text('Live 10s',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _vehicles.length,
                        itemBuilder: (_, i) {
                          final v = _vehicles[i];
                          return GestureDetector(
                            onTap: () {
                              final lat = double.tryParse(v['lokasi_lat']?.toString() ?? '') ?? _center.latitude;
                              final lng = double.tryParse(v['lokasi_lng']?.toString() ?? '') ?? _center.longitude;
                              _mapController.move(LatLng(lat, lng), 15);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Row(children: [
                                Text(_vehicleEmoji(v['jenis'] as String?),
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${v['merek']} ${v['model']}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text('${v['plat_nomor']} • ${v['nama_vendor'] ?? ''}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(_fmtPrice(v['tarif_per_hari'] ?? v['tarif_per_jam']),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => VehicleDetailScreen(vehicle: v))),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    child: const Text('Sewa'),
                                  ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary)),
    ]);
  }
}

class _SheetItem {
  final Map vehicle;
  final String info;
  const _SheetItem({required this.vehicle, required this.info});
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
