import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class VendorMapScreen extends StatefulWidget {
  const VendorMapScreen({super.key});
  @override
  State<VendorMapScreen> createState() => _VendorMapScreenState();
}

class _VendorMapScreenState extends State<VendorMapScreen> {
  List<dynamic> _fleet = [];
  bool _loading = true;
  Timer? _pollTimer;
  final MapController _mapController = MapController();

  static const LatLng _center = LatLng(-7.7972, 110.3688);

  @override
  void initState() {
    super.initState();
    _loadFleet();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadFleet());
  }

  Future<void> _loadFleet() async {
    try {
      final res = await ApiService.getVendorFleet();
      if (res['success'] == true && mounted) {
        setState(() { _fleet = res['data'] ?? []; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'available': return AppTheme.primary;
      case 'rented': return AppTheme.warning;
      case 'maintenance': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'available': return 'Tersedia';
      case 'rented': return 'Disewa';
      case 'maintenance': return 'Maintenance';
      default: return s ?? '-';
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      default: return '🛵';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Buat markers dari data fleet
    final markers = _fleet.where((v) =>
      v['lokasi_lat'] != null && v['lokasi_lng'] != null
    ).map<Marker>((v) {
      final lat = double.tryParse(v['lokasi_lat'].toString()) ?? -7.7972;
      final lng = double.tryParse(v['lokasi_lng'].toString()) ?? 110.3688;
      final color = _statusColor(v['status']);
      final emoji = _vehicleEmoji(v['jenis']);

      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 70,
        child: GestureDetector(
          onTap: () => _showVehicleInfo(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                child: Text(
                  v['plat_nomor'] ?? '-',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                      color: color),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking Armada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFleet,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
              // Legenda status
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  _legend('Tersedia', AppTheme.primary),
                  const SizedBox(width: 16),
                  _legend('Disewa', AppTheme.warning),
                  const SizedBox(width: 16),
                  _legend('Maintenance', AppTheme.danger),
                  const Spacer(),
                  Text('${_fleet.length} unit',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ),

              // Peta
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Tile layer OpenStreetMap (gratis, tidak perlu API key)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.renthub',
                    ),
                    // Markers kendaraan
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),

              // List armada di bawah peta
              Expanded(
                flex: 2,
                child: Container(
                  color: AppTheme.surface,
                  child: Column(children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(children: [
                        Text('Status Armada',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Spacer(),
                        Text('Tap marker di peta untuk detail',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _fleet.length,
                        itemBuilder: (_, i) {
                          final v = _fleet[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(children: [
                              Text(_vehicleEmoji(v['jenis']),
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${v['merek']} ${v['model']}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(v['plat_nomor'] ?? '-',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              )),
                              // Status mesin IoT
                              if (v['status_mesin'] != null) ...[
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: v['status_mesin'] == 'on'
                                        ? AppTheme.primary : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('GPS',
                                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(v['status']).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_statusLabel(v['status']),
                                    style: TextStyle(fontSize: 11,
                                        color: _statusColor(v['status']),
                                        fontWeight: FontWeight.w600)),
                              ),
                              // Tombol focus ke marker
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  final lat = double.tryParse(v['lokasi_lat']?.toString() ?? '') ?? -7.7972;
                                  final lng = double.tryParse(v['lokasi_lng']?.toString() ?? '') ?? 110.3688;
                                  _mapController.move(LatLng(lat, lng), 15);
                                },
                                child: const Icon(Icons.my_location_rounded,
                                    size: 18, color: AppTheme.primary),
                              ),
                            ]),
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

  void _showVehicleInfo(Map<String, dynamic> v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.black12,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Text(_vehicleEmoji(v['jenis']),
                style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${v['merek']} ${v['model']} ${v['tahun']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(v['plat_nomor'] ?? '-',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(v['status']).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_statusLabel(v['status']),
                  style: TextStyle(color: _statusColor(v['status']),
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const Divider(height: 24),
          _infoRow('Koordinat GPS',
              '${(v['lokasi_lat'] ?? -7.7972).toStringAsFixed(4)}°S, '
              '${(v['lokasi_lng'] ?? 110.3688).toStringAsFixed(4)}°E'),
          _infoRow('Status Mesin', v['status_mesin'] ?? 'off'),
          _infoRow('Status Kunci', v['status_kunci'] ?? 'locked'),
          _infoRow('Kecepatan', '${v['kecepatan'] ?? 0} km/h'),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11)),
  ]);
}
