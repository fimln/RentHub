// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'verify_identity_screen.dart';
import 'wallet_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  bool _saving = false;
  List<Map<String, dynamic>> _ewalletAccounts = [];
  double _totalSaldo = 0;
  final _namaTampilanCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fotoUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadSaldo());
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().refreshProfile();
    await loadSaldo();
  }

  Future<void> loadSaldo() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true && mounted) {
        final data = res['data'] as Map<String, dynamic>;
        final accounts = ((data['ewallet_accounts'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _totalSaldo = double.tryParse(data['saldo_ewallet']?.toString() ?? '0') ?? 0;
          _ewalletAccounts = accounts;
        });
      }
    } catch (e) {
      debugPrint('[loadSaldo] $e');
    }
  }

  @override
  void dispose() {
    _namaTampilanCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _fotoUrlCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode(Map<String, dynamic>? user) {
    _namaTampilanCtrl.text = user?['nama'] ?? '';
    _emailCtrl.text = user?['email'] ?? '';
    _phoneCtrl.text = user?['phone'] ?? '';
    _fotoUrlCtrl.text = user?['foto_profil_url'] ?? '';
    setState(() => _editMode = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final result = await ApiService.updateProfile({
        'nama': _namaTampilanCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'foto_profil_url': _fotoUrlCtrl.text.trim(),
      });
      if (result['success'] == true && mounted) {
        await context.read<AuthProvider>().refreshProfile();
        if (!mounted) return;
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: AppTheme.primary),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan'), backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final score = user?['trust_score'] ?? 0;
    final level = user?['level_trust'] ?? 'bronze';
    final levelEmoji = {'platinum':'💎','gold':'🥇','silver':'🥈','bronze':'🥉'}[level] ?? '🥉';
    final verified = user?['status_verifikasi'] == 'verified';
    final namaTampilan = user?['nama'] ?? '-';
    final namaDukcapil = user?['nama_lengkap'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_editMode) ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Muat ulang',
              onPressed: _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Profil',
              onPressed: () => _enterEditMode(user),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSaldo,
        color: AppTheme.primary,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12)),
            child: Column(children: [
              Builder(builder: (_) {
                final foto = user?['foto_profil_url'] as String?;
                final hasFoto = foto != null && foto.isNotEmpty;
                return CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: hasFoto ? NetworkImage(foto) : null,
                  child: hasFoto
                      ? null
                      : Text(
                          namaTampilan.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                );
              }),
              const SizedBox(height: 12),
              Text(namaTampilan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (namaDukcapil != null && namaDukcapil.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.verified_rounded, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(namaDukcapil,
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                ]),
              ],
              Text(user?['email'] ?? '-', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _badge(verified ? '✓ NIK Terverifikasi' : '⚠ Belum Verifikasi',
                    verified ? AppTheme.primary : AppTheme.warning),
                const SizedBox(width: 8),
                _badge('$levelEmoji $level', AppTheme.primary),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Edit form
          if (_editMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Edit Profil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _namaTampilanCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Tampilan'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No HP'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fotoUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link Foto Profil (opsional)',
                    hintText: 'https://contoh.com/foto.jpg',
                    helperText: 'Tempel tautan gambar yang sudah ada di internet',
                    helperMaxLines: 2,
                  ),
                ),
                if (namaDukcapil != null && namaDukcapil.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Nama Terverifikasi (tidak dapat diubah)',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(namaDukcapil,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(height: 18, width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => setState(() => _editMode = false),
                      child: const Text('Batal'),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Saldo E-Wallet header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Saldo E-Wallet',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _fmtSaldo(_totalSaldo),
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showTopUpDialog,
                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    label: const Text('Top-up', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const WalletHistoryScreen())),
                    icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
                    label: const Text('Riwayat', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Metode pembayaran
          ..._metodeBayarCards(),
          const SizedBox(height: 12),

          // Stats card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12)),
            child: Column(children: [
              _row('Trust Score', '$score / 100', valueColor: AppTheme.primary),
              _row('Level', '$levelEmoji ${level[0].toUpperCase()}${level.substring(1)}'),
              _row('Status Verifikasi', verified ? 'Terverifikasi ✓' : 'Belum Verifikasi',
                  valueColor: verified ? AppTheme.primary : AppTheme.warning),
              if (namaDukcapil != null && namaDukcapil.isNotEmpty)
                _row('Nama Dukcapil', namaDukcapil),
              _row('Bergabung', user?['created_at']?.toString().substring(0, 10) ?? '-'),
            ]),
          ),
          const SizedBox(height: 16),

          // Verifikasi button if not verified
          if (!verified) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const VerifyIdentityScreen())),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Verifikasi NIK & SIM Sekarang'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              ),
            ),
            const SizedBox(height: 12),
          ],

          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ]),
      ),
      ),
    );
  }

  String _fmtSaldo(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'Rp${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  static const Map<String, Map<String, dynamic>> _metodeInfo = {
    'gopay':      {'nama':'GOPAY',         'color':Color(0xFF00AA13)},
    'ovo':        {'nama':'OVO',           'color':Color(0xFF4C2A85)},
    'dana':       {'nama':'DANA',          'color':Color(0xFF1089D3)},
    'debit':      {'nama':'Kartu Debit',   'color':Color(0xFF1565C0)},
    'bca_va':     {'nama':'BCA Virtual',   'color':Color(0xFF0066AE)},
    'mandiri_va': {'nama':'Mandiri VA',    'color':Color(0xFFE09B00)},
    'cash':       {'nama':'Cash',          'color':Color(0xFF616161)},
  };

  Future<void> _showTopUpDialog() async {
    final accounts = List<Map<String, dynamic>>.from(_ewalletAccounts);
    if (accounts.isEmpty) return;
    String selectedMetode = accounts.first['metode_bayar'] as String;
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Top-up E-Wallet'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: selectedMetode,
            decoration: const InputDecoration(labelText: 'Metode Bayar', isDense: true),
            items: accounts.map((a) => DropdownMenuItem(
              value: a['metode_bayar'] as String,
              child: Text((a['metode_bayar'] as String).toUpperCase()),
            )).toList(),
            onChanged: (v) => setLocal(() => selectedMetode = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah (Rp)', isDense: true,
              prefixText: 'Rp ',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              final res = await ApiService.topUp(selectedMetode, amount);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['success'] == true ? 'Top-up berhasil' : (res['message'] ?? 'Gagal')),
                backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : AppTheme.danger,
              ));
              if (res['success'] == true) loadSaldo();
            },
            child: const Text('Top-up'),
          ),
        ],
      )),
    );
    amountCtrl.dispose();
  }

  List<Widget> _metodeBayarCards() {
    if (_ewalletAccounts.isEmpty) return [];

    return _ewalletAccounts.map<Widget>((a) {
      final metode = a['metode_bayar'] as String? ?? '';
      final info = _metodeInfo[metode] ?? {'nama': metode, 'color': AppTheme.textSecondary};
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (info['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.wallet_giftcard, color: info['color'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(info['nama'] as String,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(
            _fmtSaldo(a['saldo']),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
        ]),
      );
    }).toList();
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _row(String l, String v, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );
}
