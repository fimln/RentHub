import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../utils/app_theme.dart';

class VendorNotificationScreen extends StatefulWidget {
  final VoidCallback? onRead;
  const VendorNotificationScreen({super.key, this.onRead});
  @override
  State<VendorNotificationScreen> createState() => _VendorNotificationScreenState();
}

class _VendorNotificationScreenState extends State<VendorNotificationScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService().on('booking:new', _onBookingNew);
    SocketService().on('booking:returned', _onBookingReturned);
  }

  void _onBookingNew(dynamic data) {
    if (!mounted) return;
    setState(() {
      _notifs.insert(0, {
        'tipe': 'vehicle_rented',
        'judul': 'Booking Baru',
        'pesan': 'Total: Rp${(data['total_bayar'] ?? 0).toStringAsFixed(0)}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  void _onBookingReturned(dynamic data) {
    if (!mounted) return;
    setState(() {
      _notifs.insert(0, {
        'tipe': 'vehicle_returned',
        'judul': 'Kendaraan Dikembalikan',
        'pesan': 'Overtime: ${data['overtime_menit'] ?? 0} menit. Denda: Rp${(data['penalty_amount'] ?? 0).toStringAsFixed(0)}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  void dispose() {
    SocketService().off('booking:new');
    SocketService().off('booking:returned');
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getVendorNotifications();
      if (res['success'] == true && mounted) setState(() => _notifs = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  IconData _icon(String? tipe) {
    switch (tipe) {
      case 'vehicle_rented': return Icons.two_wheeler;
      case 'vehicle_returned': return Icons.flag_rounded;
      case 'overtime_deducted': return Icons.warning_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _color(String? tipe) {
    switch (tipe) {
      case 'vehicle_rented': return const Color(0xFF3B82F6);
      case 'vehicle_returned': return AppTheme.primary;
      case 'overtime_deducted': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _load,
            child: _notifs.isEmpty
                ? const Center(child: Text('Belum ada notifikasi',
                    style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final isUnread = n['is_read'] != true;
                      return GestureDetector(
                        onTap: () async {
                          if (!isUnread) return;
                          final id = n['notification_id'];
                          if (id != null) {
                            await ApiService.markVendorNotificationRead(id.toString());
                          }
                          if (mounted) {
                            setState(() => n['is_read'] = true);
                            widget.onRead?.call();
                          }
                        },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUnread ? AppTheme.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isUnread ? AppTheme.primary.withOpacity(0.3) : Colors.black12)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(color: _color(n['tipe']).withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(_icon(n['tipe']), color: _color(n['tipe']), size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(n['pesan'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(n['created_at']?.toString().substring(0, 16) ?? '',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          ])),
                          if (isUnread)
                            Container(width: 8, height: 8,
                                decoration: const BoxDecoration(
                                    color: AppTheme.primary, shape: BoxShape.circle)),
                        ]),
                      ));
                    },
                  ),
          ),
  );
}
