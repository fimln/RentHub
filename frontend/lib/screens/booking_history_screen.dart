import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});
  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String? _filterStatus;
  List<dynamic> get _filtered => _filterStatus == null
      ? _bookings
      : _bookings.where((b) => b['status_booking'] == _filterStatus).toList();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMyBookings();
      if (res['success'] == true && mounted) setState(() => _bookings = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed': return AppTheme.primary;
      case 'active': return const Color(0xFF3B82F6);
      case 'cancelled': return AppTheme.danger;
      default: return AppTheme.warning;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'completed': return 'Selesai';
      case 'active': return 'Aktif';
      case 'confirmed': return 'Dikonfirmasi';
      case 'pending': return 'Menunggu';
      case 'cancelled': return 'Dibatalkan';
      default: return s ?? '-';
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return 'Rp0';
    final n = double.tryParse(v.toString()) ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),(m)=>'${m[1]}.')}';
  }

  Widget _filterChip(String label, String? status) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _filterStatus == status,
      onSelected: (_) => setState(() => _filterStatus = status),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: _filterStatus == status ? Colors.white : AppTheme.textPrimary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Riwayat Booking'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Muat ulang',
          onPressed: _load,
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _load,
            child: Column(children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    _filterChip('Semua', null),
                    _filterChip('Aktif', 'active'),
                    _filterChip('Selesai', 'completed'),
                    _filterChip('Dibatalkan', 'cancelled'),
                  ],
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('Tidak ada booking', style: TextStyle(color: AppTheme.textSecondary)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final b = _filtered[i];
                          final status = b['status_booking'] as String?;
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => BookingDetailScreen(bookingId: b['booking_id'])));
                              _load();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black12)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(child: Text(b['nama_kendaraan'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_statusLabel(status),
                                        style: TextStyle(fontSize: 11, color: _statusColor(status),
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text('${b['plat_nomor']} • ${b['nama_vendor']}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                Text('${b['durasi_hari']} hari • ${_fmt(b['total_bayar'])}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                if (b['titik_kembali'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Kembali ke: ${b['titik_kembali']}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                                const SizedBox(height: 6),
                                Text(b['created_at']?.toString().substring(0, 16) ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
  );
}
