import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class VendorAddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicle;
  const VendorAddVehicleScreen({super.key, this.vehicle});

  @override
  State<VendorAddVehicleScreen> createState() => _VendorAddVehicleScreenState();
}

class _VendorAddVehicleScreenState extends State<VendorAddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  bool get _isEdit => widget.vehicle != null;

  late final TextEditingController _platCtrl;
  late final TextEditingController _merekCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _tahunCtrl;
  late final TextEditingController _warnaCtrl;
  late final TextEditingController _tarifCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _kapasitasCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _fotoUrlCtrl;
  String _status = 'available';

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _platCtrl = TextEditingController(text: v?['plat_nomor'] ?? '');
    _merekCtrl = TextEditingController(text: v?['merek'] ?? '');
    _modelCtrl = TextEditingController(text: v?['model'] ?? '');
    _tahunCtrl = TextEditingController(text: v?['tahun']?.toString() ?? '');
    _warnaCtrl = TextEditingController(text: v?['warna'] ?? '');
    _tarifCtrl = TextEditingController(text: v?['tarif_per_hari']?.toString() ?? '70000');
    _depositCtrl = TextEditingController(text: v?['tarif_deposit']?.toString() ?? '');
    _kapasitasCtrl = TextEditingController(text: v?['kapasitas']?.toString() ?? '2');
    _deskripsiCtrl = TextEditingController(text: v?['deskripsi'] ?? '');
    _fotoUrlCtrl = TextEditingController(text: v?['foto_url'] ?? '');
    _status = v?['status'] ?? 'available';
  }

  @override
  void dispose() {
    _platCtrl.dispose();
    _merekCtrl.dispose();
    _modelCtrl.dispose();
    _tahunCtrl.dispose();
    _warnaCtrl.dispose();
    _tarifCtrl.dispose();
    _depositCtrl.dispose();
    _kapasitasCtrl.dispose();
    _deskripsiCtrl.dispose();
    _fotoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final tarif = int.tryParse(_tarifCtrl.text.trim()) ?? 70000;
    int deposit;
    if (_depositCtrl.text.trim().isEmpty) {
      deposit = ((tarif * 0.5) < 150000) ? 150000 : (tarif * 0.5).round();
    } else {
      deposit = int.tryParse(_depositCtrl.text.trim()) ?? 150000;
    }

    final data = <String, dynamic>{
      'merek': _merekCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'tahun': int.tryParse(_tahunCtrl.text.trim()),
      'warna': _warnaCtrl.text.trim(),
      'tarif_per_hari': tarif,
      'tarif_deposit': deposit,
      'kapasitas': int.tryParse(_kapasitasCtrl.text.trim()) ?? 2,
      if (_deskripsiCtrl.text.trim().isNotEmpty) 'deskripsi': _deskripsiCtrl.text.trim(),
      if (_fotoUrlCtrl.text.trim().isNotEmpty) 'foto_url': _fotoUrlCtrl.text.trim(),
      if (_isEdit) 'status': _status,
    };

    if (!_isEdit) {
      data['plat_nomor'] = _platCtrl.text.trim();
    }

    try {
      final res = _isEdit
          ? await ApiService.updateVehicle(widget.vehicle!['vehicle_id'].toString(), data)
          : await ApiService.addVehicle(data);

      if (!mounted) return;

      final statusCode = res['statusCode'] as int?;
      final msg = res['message'] as String? ?? 'Terjadi kesalahan.';

      if (res['success'] == true) {
        String snackMsg = msg;
        if (!_isEdit && res['verified'] == false) {
          snackMsg = '$msg (Verifikasi Korlantas gagal, kendaraan tidak aktif)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackMsg), backgroundColor: AppTheme.primary),
        );
        Navigator.of(context).pop(true);
      } else if (statusCode == 409 || msg.toLowerCase().contains('limit') || msg.toLowerCase().contains('upgrade')) {
        _showDialog('Batas Armada', msg);
      } else if (statusCode == 403 || msg.toLowerCase().contains('suspend')) {
        _showDialog('Akun Ditangguhkan', msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
              _field(
                controller: _platCtrl,
                label: 'Plat Nomor',
                hint: 'AB 1234 CD',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
            ],
            _field(
              controller: _merekCtrl,
              label: 'Merek',
              hint: 'Honda',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _modelCtrl,
              label: 'Model',
              hint: 'Vario 125',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _tahunCtrl,
              label: 'Tahun',
              hint: '2022',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final y = int.tryParse(v.trim());
                if (y == null || y < 1990 || y > 2030) return 'Tahun tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _field(
              controller: _warnaCtrl,
              label: 'Warna',
              hint: 'Merah',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _tarifCtrl,
              label: 'Tarif per Hari (Rp)',
              hint: '70000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Tarif tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _field(
              controller: _depositCtrl,
              label: 'Tarif Deposit (Rp, kosongkan = otomatis)',
              hint: 'Otomatis 50% tarif atau min Rp150.000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _field(
              controller: _kapasitasCtrl,
              label: 'Kapasitas (orang)',
              hint: '2',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _field(
              controller: _deskripsiCtrl,
              label: 'Deskripsi (opsional)',
              hint: 'Kondisi baik, full helm...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _fotoUrlCtrl,
              label: 'URL Foto (opsional)',
              hint: 'https://contoh.com/foto.jpg',
              helper: 'Tempel tautan gambar yang sudah ada di internet',
              keyboardType: TextInputType.url,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: _inputDecoration('Status'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Tersedia')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'available'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? helper}) => InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: _inputDecoration(label, hint: hint, helper: helper),
      );
}
