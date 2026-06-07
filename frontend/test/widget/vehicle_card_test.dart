import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:renthub/widgets/vehicle_card.dart';

void main() {
  testWidgets('TC-UI-004 VehicleCard render nama + harga', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleCard(nama: 'Honda Beat 2024', harga: 45000),
        ),
      ),
    );

    expect(find.text('Honda Beat 2024'), findsOneWidget);
    expect(find.text('Rp45000'), findsOneWidget);
  });

  testWidgets('TC-UI-004 VehicleCard dengan harga nol', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleCard(nama: 'Gratis', harga: 0),
        ),
      ),
    );

    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('Rp0'), findsOneWidget);
  });
}
