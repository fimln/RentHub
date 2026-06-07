import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final String bookingId;
  const PaymentReceiptScreen({super.key, required this.bookingId});
  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.getPaymentDetail(widget.bookingId);
      if (res['success'] == true && mounted) setState(() => _data = res['data'] ?? {});
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  String _fmt(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]}.')}';
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'captured': return const Color(0xFF16A34A);
      case 'partially_refunded': return AppTheme.warning;
      case 'refunded': return const Color(0xFF2563EB);
      case 'pre_authorized': return AppTheme.primary;
      default: return AppTheme.textSecondary;
    }
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ))),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kwitansi Pembayaran')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusColor(_data['status_payment']).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _statusColor(_data['status_payment']).withOpacity(0.3)),
                ),
                child: Column(children: [
                  Icon(Icons.receipt_long_rounded,
                      color: _statusColor(_data['status_payment']), size: 40),
                  const SizedBox(height: 8),
                  Text((_data['status_payment'] ?? '-').toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                          color: _statusColor(_data['status_payment']))),
                ]),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Rincian Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Divider(height: 20),
                  _row('Biaya Sewa', _fmt(_data['biaya_sewa'])),
                  _row('Deposit Virtual', _fmt(_data['deposit_virtual']),
                      valueColor: AppTheme.warning),
                  _row('Pickup Fee', _fmt(_data['pickup_fee'])),
                  const Divider(height: 20),
                  _row('Total Dibayar', _fmt(_data['total_bayar']),
                      bold: true, valueColor: AppTheme.primary),
                  if (_data['refund_amount'] != null &&
                      double.tryParse(_data['refund_amount'].toString()) != 0)
                    _row('Deposit Dikembalikan', _fmt(_data['refund_amount']),
                        valueColor: const Color(0xFF16A34A)),
                  const SizedBox(height: 8),
                  _row('Metode Bayar', (_data['metode_bayar'] ?? '-').toUpperCase()),
                  _row('ID Pembayaran', _data['payment_id']?.toString().substring(0, 8) ?? '-'),
                  if (_data['gateway_ref'] != null)
                    _row('Ref Gateway', _data['gateway_ref'] ?? '-'),
                  if (_data['paid_at'] != null)
                    _row('Tanggal Bayar', _data['paid_at']?.toString().substring(0, 16) ?? '-'),
                  if (_data['deposit_dilepas_at'] != null)
                    _row('Deposit Dilepas', _data['deposit_dilepas_at']?.toString().substring(0, 16) ?? '-'),
                ]),
              ),
            ]),
          ),
  );
}
