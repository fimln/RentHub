import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'socket_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _vendor;
  bool _isLoading = false;
  String? _error;
  bool _isVendor = false;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get vendor => _vendor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isVendor => _isVendor;
  bool get isLoggedIn => _user != null || _vendor != null;

  AuthProvider() { _loadFromStorage(); }

  // ── Token helpers — diakses oleh ApiService ──────────────────────────────
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  static Future<void> clearTokens() => _storage.deleteAll();

  // Decode JWT payload untuk cek expiry tanpa library tambahan
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isBefore(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    String? userData;
    String? vendorData;
    try {
      userData = await _storage.read(key: 'user_data');
      vendorData = await _storage.read(key: 'vendor_data');
    } catch (_) {
      return;
    }
    if (userData != null) {
      _user = jsonDecode(userData);
      _isVendor = false;
    } else if (vendorData != null) {
      _vendor = jsonDecode(vendorData);
      _isVendor = true;
    }
    if (_user != null || _vendor != null) await _restoreSocketConnection();
    notifyListeners();
  }

  // Reconnect socket saat app dibuka ulang dari storage (Bug #1 fix)
  Future<void> _restoreSocketConnection() async {
    final accessToken = await getAccessToken();

    if (accessToken != null && !_isTokenExpired(accessToken)) {
      SocketService().connect(AppConstants.socketUrl, accessToken);
      return;
    }

    // Access token expired — coba refresh dulu
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      await clearTokens();
      _user = null; _vendor = null; _isVendor = false;
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await saveTokens(data['access_token'], data['refresh_token']);
        SocketService().connect(AppConstants.socketUrl, data['access_token']);
      } else {
        await clearTokens();
        _user = null; _vendor = null; _isVendor = false;
      }
    } catch (_) {
      // Tidak ada jaringan — sesi tetap ada, socket tidak tersambung
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await saveTokens(data['access_token'], data['refresh_token']);
        _user = data['user'] as Map<String, dynamic>;
        _isVendor = false;
        await _storage.write(key: 'user_data', value: jsonEncode(_user));
        SocketService().connect(AppConstants.socketUrl, data['access_token']);
        _isLoading = false; notifyListeners(); return true;
      } else {
        _error = result['message'] as String?;
        _isLoading = false; notifyListeners(); return false;
      }
    } catch (e) {
      _error = 'Koneksi gagal. Pastikan backend berjalan.';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  Future<bool> loginVendor(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login-vendor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await saveTokens(data['access_token'], data['refresh_token']);
        _vendor = data['vendor'] as Map<String, dynamic>;
        _isVendor = true;
        await _storage.write(key: 'vendor_data', value: jsonEncode(_vendor));
        SocketService().connect(AppConstants.socketUrl, data['access_token']);
        _isLoading = false; notifyListeners(); return true;
      } else {
        _error = result['message'] as String?;
        _isLoading = false; notifyListeners(); return false;
      }
    } catch (e) {
      _error = 'Koneksi gagal. Pastikan backend berjalan.';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {}

    SocketService().disconnect();
    await clearTokens();
    _user = null; _vendor = null; _isVendor = false;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> data) {
    _user = {...?_user, ...data};
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getAccessToken()}',
        },
      ).timeout(const Duration(seconds: 15));
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true && result['data'] != null) {
        _user = result['data'] as Map<String, dynamic>;
        await _storage.write(key: 'user_data', value: jsonEncode(_user));
        notifyListeners();
      }
    } catch (_) {}
  }
}
