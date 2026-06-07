import 'package:flutter_test/flutter_test.dart';
import 'package:renthub/services/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TC-UI-005 AuthProvider awal: user null, isLoggedIn false', () async {
    final auth = AuthProvider();
    await Future.delayed(const Duration(milliseconds: 200));

    expect(auth.user, isNull);
    expect(auth.isLoggedIn, false);
    expect(auth.isVendor, false);
  });

  test('TC-UI-005 AuthProvider awal: isLoading false, error null', () async {
    final auth = AuthProvider();
    await Future.delayed(const Duration(milliseconds: 200));

    expect(auth.isLoading, false);
    expect(auth.error, isNull);
  });
}
