import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'payment_receipt_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _detail = {};
  Map<String, dynamic> _audit = {};
  bool _loadingDetail = true;
  bool _loadingAudit = true;
  bool _loadingAksi = false;
  Map<String, dynamic>? _existingReview;
  bool _loadingReview = false;
  int _reviewRating = 5;
  final _reviewKomentar = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); _reviewKomentar.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    final futures = await Future.wait([
      ApiService.getBookingDetail(widget.bookingId),
      ApiService.getBookingAudit(widget.bookingId),
      ApiService.getBookingReview(widget.bookingId),
    ]);
    if (mounted) {
      setState(() {
        if (futures[0]['success'] == true) {
          _detail = futures[0]['data'] ?? {};
          _loadingDetail = false;
        }
        if (futures[1]['success'] == true) {
          _audit = futures[1]['data'] ?? {};
          _loadingAudit = false;
        }
        _existingReview = futures[2]['data'] as Map<String, dynamic>?;
      });
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
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} '
             '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return s; }
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
      default:          return s ?? '-';
    }
  }

  Future<void> _refreshAudit() async {
    final res = await ApiService.getBookingAudit(widget.bookingId);
    if (mounted && res['success'] == true) {
      setState(() {
        _audit = res['data'] ?? {};
        _loadingAudit = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    final futures = await Future.wait([
      ApiService.getBookingDetail(widget.bookingId),
      ApiService.getBookingAudit(widget.bookingId),
    ]);
    if (mounted) {
      setState(() {
        if (futures[0]['success'] == true) _detail = futures[0]['data'] ?? {};
        if (futures[1]['success'] == true) _audit = futures[1]['data'] ?? {};
      });
    }
  }

  Future<void> _doAksi(String aksi) async {
    setState(() => _loadingAksi = true);
    try {
      final String? token = _detail['unlock_token'] as String?;
      final res = await ApiService.unlockVehicle(widget.bookingId, aksi, unlockToken: token);
      if (mounted) {
        final ok = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? (ok ? 'Berhasil' : 'Gagal')),
          backgroundColor: ok ? const Color(0xFF16A34A) : AppTheme.danger,
        ));
        if (ok) await _refreshAudit();
      }
    } finally {
      if (mounted) setState(() => _loadingAksi = false);
    }
  }

  Future<void> _confirmReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kembalikan Kendaraan'),
        content: const Text('Kendaraan akan dikembalikan ke titik geofence. Deposit direfund jika tidak overtime. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Kembalikan')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loadingAksi = true);
    try {
      final lat = double.tryParse(_detail['geo_lat']?.toString() ?? '');
      final lng = double.tryParse(_detail['geo_lng']?.toString() ?? '');
      final res = await ApiService.returnVehicle(widget.bookingId, lat: lat, lng: lng);
      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? (success ? 'Kendaraan berhasil dikembalikan' : 'Gagal mengembalikan')),
          backgroundColor: success ? const Color(0xFF16A34A) : AppTheme.danger,
        ));
        if (success) await _refreshAll();
      }
    } finally {
      if (mounted) setState(() => _loadingAksi = false);
    }
  }

  bool _sudahDibuka() {
    final logs = List<dynamic>.from(_audit['unlock_logs'] ?? []);
    return logs.any((l) => l['aksi'] == 'unlock');
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: const Text('Booking akan dibatalkan dan seluruh pembayaran dikembalikan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loadingAksi = true);
    try {
      final res = await ApiService.cancelBooking(widget.bookingId);
      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? (success ? 'Booking dibatalkan' : 'Gagal membatalkan')),
          backgroundColor: success ? const Color(0xFF16A34A) : AppTheme.danger,
        ));
        if (success) await _refreshAll();
      }
    } finally {
      if (mounted) setState(() => _loadingAksi = false);
    }
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: _loadingAksi ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final status = _detail['status_booking'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Trust Log'),
            Tab(text: 'Akses'),
            Tab(text: 'Denda'),
            Tab(text: 'Ulasan'),
          ],
        ),
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(controller: _tabCtrl, children: [
              // Tab 1: Info booking
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Status badge
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_statusLabel(status),
                          style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _card([
                    _row('Kendaraan', _detail['nama_kendaraan'] ?? '-'),
                    _row('Plat', _detail['plat_nomor'] ?? '-'),
                    _row('Vendor', _detail['nama_vendor'] ?? '-'),
                    _row('Durasi', '${_detail['durasi_hari'] ?? '-'} hari'),
                    _row('Mulai', _fmtDate(_detail['waktu_mulai']?.toString())),
                    _row('Selesai', _fmtDate(_detail['waktu_selesai']?.toString())),
                    if (_detail['waktu_aktual_kembali'] != null)
                      _row('Aktual Kembali', _fmtDate(_detail['waktu_aktual_kembali'].toString())),
                    if (_detail['titik_kembali'] != null)
                      _row('Titik Kembali', _detail['titik_kembali']),
                    _row('Geofence Valid',
                        _detail['geofence_validated'] == null ? 'Belum' :
                        (_detail['geofence_validated'] == 1 || _detail['geofence_validated'] == true) ? 'Ya' : 'Tidak'),
                    if (_detail['catatan'] != null && _detail['catatan'].toString().isNotEmpty)
                      _row('Catatan', _detail['catatan'].toString()),
                  ], title: 'Booking'),
                  const SizedBox(height: 12),
                  _cardWithAction(
                    rows: [
                      _row('Total Bayar', _fmt(_detail['total_bayar']), bold: true),
                      _row('Biaya Sewa', _fmt(_detail['biaya_sewa'])),
                      _row('Deposit', _fmt(_detail['deposit_virtual'])),
                      _row('Refund', _fmt(_detail['refund_amount']),
                          valueColor: const Color(0xFF16A34A)),
                      _row('Metode', _detail['metode_bayar'] ?? '-'),
                      _row('Status Bayar', _detail['status_payment'] ?? '-'),
                    ],
                    title: 'Pembayaran',
                    action: IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppTheme.primary),
                      tooltip: 'Lihat Kwitansi',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PaymentReceiptScreen(bookingId: widget.bookingId))),
                    ),
                  ),
                  if (status == 'active' && !_sudahDibuka()) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _actionBtn('Batalkan Booking', Icons.cancel_rounded, AppTheme.danger, _confirmCancel),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Pembatalan tersedia selama kendaraan belum dibuka.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                  ],
                ]),
              ),

              // Tab 2: Trust logs
              _logList(
                loading: _loadingAudit,
                items: List<dynamic>.from(_audit['trust_logs'] ?? []),
                emptyMsg: 'Belum ada trust log',
                builder: (item) => _logTile(
                  icon: (item['delta_skor'] ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                  iconColor: (item['delta_skor'] ?? 0) >= 0 ? AppTheme.primary : AppTheme.danger,
                  title: item['parameter'] ?? '-',
                  subtitle: item['keterangan'] ?? '',
                  trailing: '${(item['delta_skor'] ?? 0) >= 0 ? '+' : ''}${item['delta_skor']}',
                  trailingColor: (item['delta_skor'] ?? 0) >= 0 ? AppTheme.primary : AppTheme.danger,
                  date: _fmtDate(item['created_at']?.toString()),
                ),
              ),

              // Tab 3: Akses
              if (_detail['status_booking'] == 'active') ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(children: [
                    if (_detail['status_payment'] != null &&
                        _detail['status_payment'] != 'pre_authorized' &&
                        _detail['status_payment'] != 'captured')
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF92400E)),
                          SizedBox(width: 8),
                          Expanded(child: Text('Pembayaran belum dikonfirmasi. Buka kunci tidak tersedia.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
                        ]),
                      ),
                    Row(children: [
                      Expanded(child: _actionBtn('Buka Kunci', Icons.lock_open_rounded, AppTheme.primary, () => _doAksi('unlock'))),
                      const SizedBox(width: 8),
                      Expanded(child: _actionBtn('Kunci', Icons.lock_rounded, const Color(0xFF92400E), () => _doAksi('lock'))),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _actionBtn('Kembalikan Kendaraan', Icons.keyboard_return_rounded, const Color(0xFF16A34A), _confirmReturn),
                    ),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Divider(),
                ),
              ],
              if (_loadingAksi)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                ),
              _logList(
                loading: _loadingAudit,
                items: List<dynamic>.from(_audit['unlock_logs'] ?? []),
                emptyMsg: 'Belum ada log akses',
                builder: (item) => _logTile(
                  icon: item['aksi'] == 'unlock' ? Icons.lock_open_rounded : Icons.lock_rounded,
                  iconColor: item['berhasil'] == 1 ? AppTheme.primary : AppTheme.danger,
                  title: '${item['aksi'] == 'unlock' ? 'Buka' : 'Kunci'} kendaraan',
                  subtitle: 'via ${item['sumber'] ?? '-'}',
                  trailing: item['berhasil'] == 1 ? 'Berhasil' : 'Gagal',
                  trailingColor: item['berhasil'] == 1 ? AppTheme.primary : AppTheme.danger,
                  date: _fmtDate(item['created_at']?.toString()),
                ),
              ),

              // Tab 4: Denda
              _logList(
                loading: _loadingAudit,
                items: List<dynamic>.from(_audit['penalties'] ?? []),
                emptyMsg: 'Tidak ada denda',
                builder: (item) => _logTile(
                  icon: Icons.timer_off_rounded,
                  iconColor: AppTheme.danger,
                  title: 'Denda overtime ${item['durasi_overtime_menit']} menit',
                  subtitle: 'Tarif denda: ${_fmt(item['tarif_per_jam_denda'])}/jam (1.5x)',
                  trailing: _fmt(item['nominal_denda']),
                  trailingColor: AppTheme.danger,
                  date: '',
                ),
              ),

              // Tab 5: Ulasan
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _detail['status_booking'] != 'completed'
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text('Ulasan tersedia setelah booking selesai',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ))
                    : _existingReview != null
                        ? _reviewCard(_existingReview!)
                        : _reviewForm(),
              ),
            ]),
    );
  }

  Widget _cardWithAction({required List<Widget> rows, required String title, Widget? action}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (action != null) action,
          ]),
          const Divider(height: 16),
          ...rows,
        ]),
      );

  Widget _card(List<Widget> rows, {required String title}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const Divider(height: 16),
      ...rows,
    ]),
  );

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ))),
        ]),
      );

  Widget _logList({
    required bool loading,
    required List<dynamic> items,
    required String emptyMsg,
    required Widget Function(Map<String, dynamic>) builder,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (items.isEmpty) return Center(child: Text(emptyMsg,
        style: const TextStyle(color: AppTheme.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => builder(items[i] as Map<String, dynamic>),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ulasan Anda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 10),
      Row(children: List.generate(5, (i) => Icon(
        i < (r['rating'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
        color: const Color(0xFFF5B800), size: 28))),
      if (r['komentar'] != null && r['komentar'].toString().isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(r['komentar'].toString(), style: const TextStyle(fontSize: 13)),
      ],
      const SizedBox(height: 8),
      Text(_fmtDate(r['created_at']?.toString()),
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  );

  Widget _reviewForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Beri Ulasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    const SizedBox(height: 14),
    const Text('Rating', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    const SizedBox(height: 6),
    Row(children: List.generate(5, (i) => GestureDetector(
      onTap: () => setState(() => _reviewRating = i + 1),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(
          i < _reviewRating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFF5B800), size: 36),
      )))),
    const SizedBox(height: 16),
    TextField(
      controller: _reviewKomentar,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Ceritakan pengalamanmu (opsional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(12),
      ),
    ),
    const SizedBox(height: 16),
    SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loadingReview ? null : _submitReview,
        child: _loadingReview
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Kirim Ulasan'),
      ),
    ),
  ]);

  Future<void> _submitReview() async {
    setState(() => _loadingReview = true);
    try {
      final res = await ApiService.submitReview(widget.bookingId, _reviewRating, _reviewKomentar.text.trim());
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ulasan berhasil dikirim'), backgroundColor: Color(0xFF16A34A)));
        final reviewRes = await ApiService.getBookingReview(widget.bookingId);
        if (mounted) setState(() => _existingReview = reviewRes['data'] as Map<String, dynamic>?);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Gagal mengirim ulasan'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loadingReview = false);
    }
  }

  Widget _logTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
    required Color trailingColor,
    required String date,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            if (date.isNotEmpty)
              Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          Text(trailing, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: trailingColor)),
        ]),
      );
}
