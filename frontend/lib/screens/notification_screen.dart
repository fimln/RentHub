import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService().on('payment:success', _onPaymentSuccess);
    SocketService().on('penalty:applied', _onPenaltyApplied);
  }

  void _onPaymentSuccess(dynamic data) {
    if (!mounted) return;
    setState(() {
      _notifs.insert(0, {
        'tipe': 'payment_success',
        'judul': 'Pembayaran Berhasil',
        'pesan': 'Total: Rp${(data['total_bayar'] ?? 0).toStringAsFixed(0)}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  void _onPenaltyApplied(dynamic data) {
    if (!mounted) return;
    setState(() {
      _notifs.insert(0, {
        'tipe': 'overtime_deducted',
        'judul': 'Denda Overtime',
        'pesan': data['message'] ?? 'Terdapat denda keterlambatan',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  void dispose() {
    SocketService().off('payment:success');
    SocketService().off('penalty:applied');
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true && mounted) setState(() => _notifs = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  IconData _icon(String? tipe) {
    switch (tipe) {
      case 'payment_success': return Icons.check_circle_rounded;
      case 'trust_score_up': return Icons.star_rounded;
      case 'deposit_refund': return Icons.account_balance_wallet_rounded;
      case 'vehicle_rented': return Icons.two_wheeler;
      case 'overtime_deducted': return Icons.warning_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _color(String? tipe) {
    switch (tipe) {
      case 'payment_success': return AppTheme.primary;
      case 'trust_score_up': return const Color(0xFFF5B800);
      case 'deposit_refund': return const Color(0xFF3B82F6);
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
                ? const Center(child: Text('Tidak ada notifikasi',
                    style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final isRead = n['is_read'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? Colors.black12 : AppTheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _color(n['tipe']).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon(n['tipe']), color: _color(n['tipe']), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(n['pesan'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(n['created_at']?.toString().substring(0, 16) ?? '',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          ])),
                          if (!isRead) Container(width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                        ]),
                      );
                    },
                  ),
          ),
  );
}
