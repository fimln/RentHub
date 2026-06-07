import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'booking_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final int durasiJam;
  final int durasiHari;
  final String? geofenceId;
  final String metodePengambilan;
  final double biayaSewa, pickupFee, depositVirtual, total;

  const CheckoutScreen({
    super.key, required this.vehicle, required this.durasiJam,
    this.durasiHari = 1,
    required this.geofenceId, required this.biayaSewa,
    required this.pickupFee, required this.depositVirtual, required this.total,
    this.metodePengambilan = 'ambil_sendiri',
  });
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _metode = 'gopay';
  bool _loading = false;
  bool _loadingMetodes = true;
  List<Map<String, dynamic>> _metodes = [];
  final _catatanCtrl = TextEditingController();

  static const Map<String, Map<String, dynamic>> _metodeInfo = {
    'gopay':      {'label':'GOPAY',         'color':Color(0xFF00AA13)},
    'ovo':        {'label':'OVO',           'color':Color(0xFF4C2A85)},
    'dana':       {'label':'DANA',          'color':Color(0xFF1089D3)},
    'debit':      {'label':'Kartu Debit',  'color':Color(0xFF1565C0)},
    'bca_va':     {'label':'Transfer BCA',  'color':Color(0xFF0066AE)},
    'mandiri_va': {'label':'Mandiri VA',    'color':Color(0xFFE09B00)},
    'cash':       {'label':'Cash',          'color':Color(0xFF616161)},
  };

  @override
  void initState() {
    super.initState();
    _loadMetodes();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetodes() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true && mounted) {
        final raw = ((res['data']?['ewallet_accounts'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _metodes = raw.map<Map<String, dynamic>>((a) {
            final m = a['metode_bayar'] as String? ?? '';
            final info = _metodeInfo[m] ?? {'label': m, 'color': const Color(0xFF888888)};
            final saldo = double.tryParse(a['saldo']?.toString() ?? '0') ?? 0;
            return {
              'id': m,
              'label': info['label'],
              'color': info['color'],
              'saldo': saldo,
              'saldoText': _fmt(saldo),
            };
          }).toList();
          if (_metodes.isNotEmpty) _metode = _metodes[0]['id'] as String;
        });
      }
    } catch (e) {
      debugPrint('[loadMetodes] $e');
    } finally {
      if (mounted) setState(() => _loadingMetodes = false);
    }
  }

  String _fmt(double v) => 'Rp${v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _processPayment() async {
    setState(() => _loading = true);
    try {
      // Fase 4: satu panggilan atomik - booking + payment sekaligus
      final result = await ApiService.createBooking({
        'vehicle_id':  widget.vehicle['vehicle_id'],
        'geofence_id': widget.geofenceId,
        'waktu_mulai': DateTime.now().toIso8601String(),
        'durasi_jam':  widget.durasiJam,
        'durasi_hari': widget.durasiHari,
        'metode_bayar': _metode,
        'metode_pengambilan': widget.metodePengambilan,
        if (_catatanCtrl.text.trim().isNotEmpty) 'catatan': _catatanCtrl.text.trim(),
      });

      if (!mounted) return;

      if (result['success'] != true) {
        final msg = result['message'] ?? 'Booking gagal';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 4),
        ));
        setState(() => _loading = false);
        return;
      }

      final data = result['data'] as Map<String, dynamic>;
      final summary = data['payment_summary'] as Map<String, dynamic>? ?? {};

      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          bookingId:      data['booking_id'],
          unlockToken:    data['unlock_token'],
          vehicleId:      widget.vehicle['vehicle_id'],
          vehicleName:    '${widget.vehicle['merek']} ${widget.vehicle['model']} ${widget.vehicle['tahun']}',
          platNomor:      widget.vehicle['plat_nomor'],
          waktuSelesai:   DateTime.parse(data['waktu_selesai'].toString()).toLocal(),
          depositVirtual: (summary['deposit_virtual'] as num?)?.toDouble() ?? widget.depositVirtual,
          geofenceId:     widget.geofenceId,
          biayaSewa:      (summary['biaya_sewa']    as num?)?.toDouble() ?? widget.biayaSewa,
          pickupFee:      (summary['pickup_fee']    as num?)?.toDouble() ?? widget.pickupFee,
          totalBayar:     (summary['total_bayar']   as num?)?.toDouble() ?? widget.total,
          saldoSetelah:   (summary['saldo_setelah'] as num?)?.toDouble() ?? 0,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.danger));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingMetodes)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ))
          else ...[
            if (_metodes.isEmpty)
              const Text('Tidak ada metode pembayaran tersedia',
                  style: TextStyle(color: AppTheme.textSecondary))
            else
              ..._metodes.map((m) => GestureDetector(
                onTap: () => setState(() => _metode = m['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _metode == m['id'] ? AppTheme.primary : Colors.black12,
                      width: _metode == m['id'] ? 2 : 1,
                    ),
                    color: _metode == m['id'] ? AppTheme.primaryLight : Colors.white,
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (m['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.wallet_giftcard, color: m['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['label'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Saldo: ${m['saldoText']}',
                          style: TextStyle(fontSize: 12,
                              color: (m['saldo'] as num) >= widget.total
                                  ? const Color(0xFF16A34A)
                                  : AppTheme.danger)),
                    ])),
                    if (_metode == m['id'])
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                  ]),
                ),
              )),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rincian Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              _row('Biaya sewa (${widget.durasiHari} hari)', _fmt(widget.biayaSewa)),
              _row('Pickup fee', _fmt(widget.pickupFee)),
              _row('Deposit virtual (pre-auth)', _fmt(widget.depositVirtual),
                  valueColor: AppTheme.warning),
              const Divider(height: 16),
              _row('Total Dibayar', _fmt(widget.total), bold: true, valueColor: AppTheme.primary),
            ]),
          ),

          const SizedBox(height: 14),
          TextField(
            controller: _catatanCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Catatan untuk vendor (opsional)',
              hintText: 'mis. minta diantar ke lobby',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_rounded, color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Pre-Authorization Aktif',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF92400E))),
                const SizedBox(height: 2),
                Text(
                  'Deposit ${_fmt(widget.depositVirtual)} ditahan sementara. '
                  'Kendaraan hanya bisa dibuka setelah pembayaran berhasil (No Funds, No Key).',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ])),
            ]),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _processPayment,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Konfirmasi & Bayar ${_fmt(widget.total)}'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13,
          color: bold ? AppTheme.textPrimary : AppTheme.textSecondary)),
      Text(value, style: TextStyle(fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );
}
