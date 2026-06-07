import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_provider.dart';
import 'socket_service.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  static String buildUrl(String path) {
    final separator = path.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$path';
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthProvider.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Coba refresh access token; kembalikan true jika berhasil
  static Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await AuthProvider.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        await AuthProvider.saveTokens(data['access_token'], data['refresh_token']);
        // Reconnect socket jika terputus akibat token expired (Bug #2 fix)
        if (!SocketService().isConnected) {
          SocketService().connect(AppConstants.socketUrl, data['access_token']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    bool isRetry = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && auth && !isRetry) {
        final refreshed = await _tryRefresh();
        if (refreshed) return _post(path, body, auth: true, isRetry: true);
        await AuthProvider.clearTokens();
        return {'success': false, 'message': 'Sesi habis. Silakan login ulang.', 'code': 'SESSION_EXPIRED'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _get(
    String path, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _tryRefresh();
        if (refreshed) return _get(path, isRetry: true);
        await AuthProvider.clearTokens();
        return {'success': false, 'message': 'Sesi habis. Silakan login ulang.', 'code': 'SESSION_EXPIRED'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _tryRefresh();
        if (refreshed) return _put(path, body, isRetry: true);
        await AuthProvider.clearTokens();
        return {'success': false, 'message': 'Sesi habis. Silakan login ulang.', 'code': 'SESSION_EXPIRED'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _patch(
    String path, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _tryRefresh();
        if (refreshed) return _patch(path, isRetry: true);
        await AuthProvider.clearTokens();
        return {'success': false, 'message': 'Sesi habis. Silakan login ulang.', 'code': 'SESSION_EXPIRED'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<Map<String, dynamic>> _delete(
    String path, {
    bool isRetry = false,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _tryRefresh();
        if (refreshed) return _delete(path, isRetry: true);
        await AuthProvider.clearTokens();
        return {'success': false, 'message': 'Sesi habis. Silakan login ulang.', 'code': 'SESSION_EXPIRED'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password}, auth: false);

  static Future<Map<String, dynamic>> loginVendor(String email, String password) =>
      _post('/auth/login-vendor', {'email': email, 'password': password}, auth: false);

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      _post('/auth/register', data, auth: false);

  static Future<Map<String, dynamic>> verifyIdentity({
    required String nik, required String nomorSim, required String userId,
  }) => _post('/auth/verify-identity', {'nik': nik, 'nomor_sim': nomorSim, 'user_id': userId});

  // USER
  static Future<Map<String, dynamic>> getProfile() => _get('/users/profile');
  static Future<Map<String, dynamic>> getTrustHistory() => _get('/users/trust-history');
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _put('/users/profile', data);

  // VEHICLES
  static Future<Map<String, dynamic>> getVehicles({String? jenis, String? status}) {
    var path = '/vehicles';
    final params = <String>[];
    if (jenis != null) params.add('jenis=$jenis');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    return _get(path);
  }

  static Future<Map<String, dynamic>> getVehicleDetail(String id) => _get('/vehicles/$id');

  // GEOFENCES
  static Future<Map<String, dynamic>> getGeofences() => _get('/geofences');

  // BOOKINGS
  static Future<Map<String, dynamic>> estimateBooking({
    required String vehicleId,
    required int durasiHari,
    String? geofenceId,
    String metode = 'ambil_sendiri',
  }) => _post('/bookings/estimate', {
    'vehicle_id': vehicleId,
    'durasi_hari': durasiHari,
    if (geofenceId != null) 'geofence_id': geofenceId,
    'metode_pengambilan': metode,
  });

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) =>
      _post('/bookings', data);

  static Future<Map<String, dynamic>> getMyBookings() => _get('/bookings/my');

  static Future<Map<String, dynamic>> getBookingDetail(String id) => _get('/bookings/$id');

  static Future<Map<String, dynamic>> getBookingAudit(String id) => _get('/bookings/$id/audit');

  static Future<Map<String, dynamic>> returnVehicle(String bookingId,
      {double? lat, double? lng}) =>
      _post('/bookings/$bookingId/return', {'lat': lat, 'lng': lng});

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) =>
      _post('/bookings/$bookingId/cancel', {});

  // IOT
  static Future<Map<String, dynamic>> unlockVehicle(String bookingId, String aksi, {String? unlockToken}) =>
      _post('/iot/unlock', {
        'booking_id': bookingId,
        'aksi': aksi,
        if (unlockToken != null) 'unlock_token': unlockToken,
      });

  static Future<Map<String, dynamic>> getIotStatus(String vehicleId) =>
      _get('/iot/status/$vehicleId');

  static Future<Map<String, dynamic>> vendorLockVehicle(String vehicleId, String aksi) =>
      _post('/iot/vendor/lock', {'vehicle_id': vehicleId, 'aksi': aksi});

  // NOTIFICATIONS
  static Future<Map<String, dynamic>> getNotifications() => _get('/notifications');
  static Future<Map<String, dynamic>> markAllRead() => _patch('/notifications/read-all');

  // VENDOR
  static Future<Map<String, dynamic>> getVendorDashboard() => _get('/vendors/dashboard');
  static Future<Map<String, dynamic>> getVendorFleet() => _get('/vendors/fleet');
  static Future<Map<String, dynamic>> getVendorNotifications() => _get('/notifications/vendor');
  static Future<Map<String, dynamic>> markVendorNotificationRead(String id) =>
      _patch('/notifications/vendor/$id/read');
  static Future<Map<String, dynamic>> getVendorBookings({String? vehicleId}) {
    final path = vehicleId != null
        ? '/vendors/bookings?vehicle_id=$vehicleId'
        : '/vendors/bookings';
    return _get(path);
  }
  static Future<Map<String, dynamic>> updateVendorProfile(Map<String, dynamic> data) =>
      _put('/vendors/profile', data);
  static Future<Map<String, dynamic>> getBookingPenalties(String bookingId) =>
      _get('/vendors/bookings/$bookingId/penalties');
  static Future<Map<String, dynamic>> waivePenalty(String penaltyId) =>
      _post('/vendors/penalties/$penaltyId/waive', {});
  static Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> data) =>
      _post('/vendors/fleet', data);
  static Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data) =>
      _put('/vendors/fleet/$id', data);
  static Future<Map<String, dynamic>> deleteVehicle(String id) =>
      _delete('/vendors/fleet/$id');

  // REVIEWS
  static Future<Map<String, dynamic>> getVehicleReviews(String vehicleId) =>
      _get('/reviews/vehicle/$vehicleId');

  static Future<Map<String, dynamic>> getBookingReview(String bookingId) =>
      _get('/reviews/booking/$bookingId');

  static Future<Map<String, dynamic>> submitReview(String bookingId, int rating, String? komentar) =>
      _post('/reviews', {
        'booking_id': bookingId,
        'rating': rating,
        if (komentar != null && komentar.isNotEmpty) 'komentar': komentar,
      });

  // EWALLET
  static Future<Map<String, dynamic>> topUp(String metodeBayar, double amount) =>
      _post('/ewallet/topup', {'metode_bayar': metodeBayar, 'amount': amount});

  static Future<Map<String, dynamic>> getTransactions({String? metodeBayar}) {
    final q = metodeBayar != null ? '?metode_bayar=$metodeBayar' : '';
    return _get('/ewallet/transactions$q');
  }

  // PAYMENT
  static Future<Map<String, dynamic>> getPaymentDetail(String bookingId) =>
      _get('/payments/$bookingId');
}
