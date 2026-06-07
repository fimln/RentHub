import 'package:flutter/material.dart';

class VehicleCard extends StatelessWidget {
  final String nama;
  final int harga;

  const VehicleCard({
    super.key,
    required this.nama,
    required this.harga,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Text(nama, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('Rp${harga.toString()}'),
        ]),
      ),
    );
  }
}
