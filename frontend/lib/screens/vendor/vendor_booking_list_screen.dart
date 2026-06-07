import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class VendorBookingListScreen extends StatefulWidget {
  const VendorBookingListScreen({super.key});
  @override
  State<VendorBookingListScreen> createState() => _VendorBookingListScreenState();
}

class _VendorBookingListScreenState extends State<VendorBookingListScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getVendorBookings();
      if (res['success'] == true && mounted) {
        setState(() => _bookings = res['data'] ?? []);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':    return AppTheme.primary;
      case 'completed': return const Color(0xFF16A34A);
      case 'cancelled': return AppTheme.danger;
      default:          return AppTheme.warning;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'active':    return 'Aktif';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      case 'pending':   return 'Menunggu';
      default:          return s ?? '-';
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _fmtDate(String? s) {
    if (s == null) return '-';
    try {
      final d = DateTime.parse(s).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} '
             '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return s; }
  }

  void _showDetail(Map<String, dynamic> b) {
    final bookingId = b['booking_id']?.toString();
    List<dynamic> penalties = [];
    bool loadingPenalties = true;
    bool waiving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          if (loadingPenalties && bookingId != null) {
            loadingPenalties = false;
            ApiService.getBookingPenalties(bookingId).then((res) {
              if (res['success'] == true) {
                penalties = res['data'] ?? [];
                setSheetState(() {});
              }
            });
          }

          Future<void> waive(String penaltyId) async {
            setSheetState(() => waiving = true);
            final res = await ApiService.waivePenalty(penaltyId);
            final ok = res['success'] == true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['message'] ?? (ok ? 'Denda dibebaskan' : 'Gagal')),
                backgroundColor: ok ? const Color(0xFF16A34A) : AppTheme.danger,
              ));
            }
            if (ok && bookingId != null) {
              final refreshed = await ApiService.getBookingPenalties(bookingId);
              if (refreshed['success'] == true) penalties = refreshed['data'] ?? [];
              _load();
            }
            setSheetState(() => waiving = false);
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.black12,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                    child: Text(b['nama_kendaraan'] ?? '-',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(b['status_booking']).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_statusLabel(b['status_booking']),
                        style: TextStyle(color: _statusColor(b['status_booking']),
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
                Text(b['plat_nomor'] ?? '-',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const Divider(height: 24),

                _detailRow('Penyewa', b['nama_penyewa'] ?? '-'),
                _detailRow('Trust Score', '${b['trust_score'] ?? 0} (${b['level_trust'] ?? '-'})'),
                _detailRow('Durasi', '${b['durasi_jam']} jam'),
                _detailRow('Mulai', _fmtDate(b['waktu_mulai']?.toString())),
                _detailRow('Selesai', _fmtDate(b['waktu_selesai']?.toString())),
                if (b['titik_kembali'] != null)
                  _detailRow('Titik Kembali', b['titik_kembali']),
                const Divider(height: 20),
                _detailRow('Total Bayar', _fmt(b['total_bayar']), highlight: true),
                _detailRow('Deposit', _fmt(b['deposit_virtual'])),
                if (b['refund_amount'] != null)
                  _detailRow('Refund', _fmt(b['refund_amount']),
                      color: const Color(0xFF16A34A)),
                _detailRow('Metode', b['metode_bayar'] ?? '-'),
                _detailRow('Status Pembayaran', b['status_payment'] ?? '-'),

                if (penalties.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Denda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...penalties.map((p) {
                    final waived = p['status_potong'] == 'waived';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Overtime ${p['durasi_overtime_menit']} menit',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(_fmt(p['nominal_denda']),
                              style: const TextStyle(fontSize: 13, color: AppTheme.danger,
                                  fontWeight: FontWeight.bold)),
                        ])),
                        if (waived)
                          const Text('Dibebaskan',
                              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600))
                        else
                          TextButton(
                            onPressed: waiving ? null : () => waive(p['penalty_id'].toString()),
                            child: const Text('Bebaskan'),
                          ),
                      ]),
                    );
                  }),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar Booking')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _bookings.isEmpty
            ? const Center(
                child: Text('Belum ada booking',
                    style: TextStyle(color: AppTheme.textSecondary)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (_, i) {
                    final b = _bookings[i];
                    final statusColor = _statusColor(b['status_booking']);
                    return GestureDetector(
                      onTap: () => _showDetail(b),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(b['nama_kendaraan'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_statusLabel(b['status_booking']),
                                  style: TextStyle(fontSize: 11, color: statusColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text('${b['plat_nomor'] ?? '-'} | ${b['nama_penyewa'] ?? '-'}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(_fmtDate(b['waktu_mulai']?.toString()),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const Spacer(),
                            Text(_fmt(b['total_bayar']),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                    color: AppTheme.primary)),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
              ),
  );

  Widget _detailRow(String label, String value,
      {bool highlight = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(
            fontSize: highlight ? 15 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: color ?? (highlight ? AppTheme.primary : AppTheme.textPrimary),
          )),
        ]),
      );
}
