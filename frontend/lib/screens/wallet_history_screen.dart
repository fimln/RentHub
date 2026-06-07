import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class WalletHistoryScreen extends StatefulWidget {
  const WalletHistoryScreen({super.key});
  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  List<dynamic> _txns = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getTransactions();
      if (res['success'] == true && mounted) setState(() => _txns = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  String _fmt(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]}.')}';
  }

  Color _tipeColor(String? t) {
    switch (t) {
      case 'topup': return const Color(0xFF16A34A);
      case 'refund': return const Color(0xFF2563EB);
      case 'deduct': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _tipeIcon(String? t) {
    switch (t) {
      case 'topup': return Icons.add_circle_outline_rounded;
      case 'refund': return Icons.undo_rounded;
      case 'deduct': return Icons.remove_circle_outline_rounded;
      case 'transfer_out': return Icons.arrow_upward_rounded;
      case 'transfer_in': return Icons.arrow_downward_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  String _tipeLabel(String? t) {
    switch (t) {
      case 'topup': return 'Top-up';
      case 'refund': return 'Refund Deposit';
      case 'deduct': return 'Pembayaran';
      case 'transfer_out': return 'Transfer Keluar';
      case 'transfer_in': return 'Transfer Masuk';
      default: return t ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Transaksi')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _load,
            child: _txns.isEmpty
                ? const Center(child: Text('Belum ada transaksi',
                      style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _txns.length,
                    itemBuilder: (_, i) {
                      final t = _txns[i] as Map<String, dynamic>;
                      final tipe = t['tipe'] as String?;
                      final isCredit = tipe == 'topup' || tipe == 'refund' || tipe == 'transfer_in';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _tipeColor(tipe).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_tipeIcon(tipe), color: _tipeColor(tipe), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_tipeLabel(tipe),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text((t['metode_bayar'] as String? ?? '').toUpperCase(),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            if (t['keterangan'] != null && t['keterangan'].toString().isNotEmpty)
                              Text(t['keterangan'].toString(),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${isCredit ? '+' : '-'}${_fmt(t['amount'])}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                    color: _tipeColor(tipe))),
                            Text(_fmt(t['saldo_sesudah']),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text(t['created_at']?.toString().substring(0, 16) ?? '',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
  );
}
