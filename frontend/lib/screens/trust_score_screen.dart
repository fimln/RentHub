// lib/screens/trust_score_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'dart:math' as math;

class TrustScoreScreen extends StatefulWidget {
  const TrustScoreScreen({super.key});
  @override
  State<TrustScoreScreen> createState() => _TrustScoreScreenState();
}

class _TrustScoreScreenState extends State<TrustScoreScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.getTrustHistory();
      if (res['success'] == true && mounted) setState(() => _history = res['data'] ?? []);
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshProfile();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final score = user?['trust_score'] ?? 0;
    final level = user?['level_trust'] ?? 'bronze';
    final levelEmoji = {'platinum':'💎','gold':'🥇','silver':'🥈','bronze':'🥉'}[level] ?? '🥉';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Trust Score'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Score ring card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12)),
              child: Column(children: [
                SizedBox(
                  width: 140, height: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(size: const Size(140, 140),
                        painter: _RingPainter(score / 100.0)),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$score', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                      const Text('/ 100', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('$levelEmoji Level ${level[0].toUpperCase()}${level.substring(1)}',
                      style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Text(_nextLevelMsg(score, level),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
            const SizedBox(height: 16),

            // Benefits card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Benefit Level Saat Ini',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                ..._benefits(level).map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(b['locked'] ? Icons.lock_outline : Icons.check_circle_rounded,
                        color: b['locked'] ? AppTheme.textSecondary : AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(b['text'], style: TextStyle(fontSize: 13,
                        color: b['locked'] ? AppTheme.textSecondary : AppTheme.textPrimary)),
                  ]),
                )),
              ]),
            ),
            const SizedBox(height: 16),

            // History
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Riwayat Poin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                else if (_history.isEmpty)
                  const Center(child: Text('Belum ada riwayat',
                      style: TextStyle(color: AppTheme.textSecondary)))
                else ..._history.map((h) {
                  final delta = h['delta_skor'] as int? ?? 0;
                  final isPos = delta >= 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12))),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isPos ? AppTheme.primaryLight : const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(isPos ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPos ? AppTheme.primary : AppTheme.danger, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h['parameter']?.toString().replaceAll('_', ' ') ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(h['created_at']?.toString().substring(0, 10) ?? '',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ])),
                      Text('${isPos ? '+' : ''}$delta',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                              color: isPos ? AppTheme.primary : AppTheme.danger)),
                    ]),
                  );
                }),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _nextLevelMsg(int score, String level) {
    if (level == 'platinum') return 'Level tertinggi! Pertahankan prestasi Anda 🌟';
    if (level == 'gold') return '${90 - score} poin lagi untuk Platinum 💎';
    if (level == 'silver') return '${75 - score} poin lagi untuk Gold 🥇';
    return '${50 - score} poin lagi untuk Silver 🥈';
  }

  List<Map<String,dynamic>> _benefits(String level) {
    final all = [
      {'text': 'Verifikasi NIK & SIM digital', 'minLevel': 'bronze', 'locked': false},
      {'text': 'Deposit virtual lebih rendah 10%', 'minLevel': 'silver', 'locked': level == 'bronze'},
      {'text': 'Akses kendaraan premium', 'minLevel': 'silver', 'locked': level == 'bronze'},
      {'text': 'Toleransi overtime 15 menit', 'minLevel': 'silver', 'locked': level == 'bronze'},
      {'text': 'Deposit virtual lebih rendah 20%', 'minLevel': 'gold', 'locked': ['bronze','silver'].contains(level)},
      {'text': 'Prioritas booking pada jam sibuk', 'minLevel': 'gold', 'locked': ['bronze','silver'].contains(level)},
      {'text': 'Bebas pickup fee (platinum)', 'minLevel': 'platinum', 'locked': level != 'platinum'},
    ];
    return all;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final bg = Paint()..color = Colors.black12..strokeWidth = 12..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()..color = AppTheme.primary..strokeWidth = 12
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * progress, false, fg);
  }
  @override
  bool shouldRepaint(_) => true;
}
