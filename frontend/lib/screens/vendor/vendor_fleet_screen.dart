import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'vendor_add_vehicle_screen.dart';
import 'vendor_vehicle_detail_screen.dart';

class VendorFleetScreen extends StatefulWidget {
  const VendorFleetScreen({super.key});
  @override
  State<VendorFleetScreen> createState() => _VendorFleetScreenState();
}

class _VendorFleetScreenState extends State<VendorFleetScreen> {
  List<dynamic> _fleet = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getVendorFleet();
      if (res['success'] == true && mounted) setState(() => _fleet = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
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
      case 'inactive': return 'Tidak Aktif';
      default: return s ?? '-';
    }
  }

  String _vehicleEmoji(String? jenis) {
    switch (jenis) {
      case 'motor': return '🛵';
      default: return '🛵';
    }
  }

  void _openOptions(Map<String, dynamic> v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${v['merek']} ${v['model']} ${v['tahun']}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Kendaraan'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorAddVehicleScreen(vehicle: v),
                  ),
                );
                if (result == true) _load();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.danger),
              title: Text('Hapus Kendaraan', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Tutup'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> v) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text(
          'Hapus ${v['merek']} ${v['model']} (${v['plat_nomor']})? '
          'Kendaraan yang sedang disewa tidak dapat dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVehicle(v);
            },
            child: Text('Hapus', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(Map<String, dynamic> v) async {
    final res = await ApiService.deleteVehicle(v['vehicle_id'].toString());
    if (!mounted) return;
    final msg = res['message'] as String? ?? 'Terjadi kesalahan.';
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.primary),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Status Armada')),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorAddVehicleScreen()),
        );
        if (result == true) _load();
      },
      child: const Icon(Icons.add),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fleet.isEmpty ? 0 : _fleet.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  if (_fleet.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Ketuk untuk detail kendaraan, tahan untuk edit/hapus',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary),
                    ),
                  );
                }
                final v = _fleet[i - 1];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorVehicleDetailScreen(vehicle: Map<String, dynamic>.from(v)),
                    ),
                  ),
                  onLongPress: () => _openOptions(v),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _statusColor(v['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(_vehicleEmoji(v['jenis']),
                            style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${v['merek']} ${v['model']} ${v['tahun']}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(v['plat_nomor'] ?? '-',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (v['status_mesin'] != null)
                          Row(children: [
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: v['status_mesin'] == 'on' ? AppTheme.primary : AppTheme.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text('Mesin: ${v['status_mesin']} | GPS aktif',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          ]),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(v['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_statusLabel(v['status']),
                            style: TextStyle(fontSize: 11, color: _statusColor(v['status']),
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
  );
}
