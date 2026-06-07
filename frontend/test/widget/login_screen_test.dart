import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:renthub/screens/login_screen.dart';
import 'package:renthub/services/auth_provider.dart';

Widget buildTestWidget() {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('TC-UI-002 LoginScreen render 2 TextField + tombol Masuk',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('TC-UI-003 LoginScreen tampilkan error jika email kosong',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());

    final masukButton = find.widgetWithText(ElevatedButton, 'Masuk');
    await tester.tap(masukButton);
    await tester.pumpAndSettle();

    expect(find.text('Email tidak valid'), findsOneWidget);
  });
}
