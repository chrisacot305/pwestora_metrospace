import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown whenever the API responds with ok:false or a non-2xx status.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // Change this if your domain is ever different.
  static const String baseUrl = 'https://pwestora.com/api';

  // ---------------- Token storage ----------------

  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString('user_name', user['full_name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // ---------------- Recently viewed (stored locally on-device) ----------------

  static Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('recently_viewed') ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  static Future<void> addRecentlyViewed(Map<String, dynamic> property) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('recently_viewed') ?? [];
    final list = raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    list.removeWhere((p) => p['id'] == property['id']);
    list.insert(0, property);
    final trimmed = list.take(8).toList();
    await prefs.setStringList(
      'recently_viewed',
      trimmed.map((p) => jsonEncode(p)).toList(),
    );
  }

  // ---------------- Internal helpers ----------------

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final res = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> _getJson(
    String path, {
    bool auth = false,
  }) async {
    final headers = <String, String>{};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final res = await http.get(Uri.parse('$baseUrl/$path'), headers: headers);
    return _handleResponse(res);
  }

  static Map<String, dynamic> _handleResponse(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'The server sent back something unexpected. Please try again.',
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300 && data['ok'] == true) {
      return data;
    }
    throw ApiException(
      data['error'] ?? 'Something went wrong. Please try again.',
    );
  }

  // ---------------- Auth ----------------

  static Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _postJson('auth_register.php', {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await saveSession(data['token'], data['user']);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _postJson('auth_login.php', {
      'email': email,
      'password': password,
    });
    await saveSession(data['token'], data['user']);
  }

  // ---------------- Properties ----------------

  static Future<List<dynamic>> fetchProperties() async {
    final data = await _getJson('properties_list.php');
    return data['properties'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> fetchPropertyDetail(int id) async {
    final data = await _getJson('properties_show.php?id=$id');
    return data['property'] as Map<String, dynamic>;
  }

  // ---------------- Applications & Checklist ----------------

  static Future<int> submitApplication({
    required int propertyId,
    required String businessName,
    required int termMonths,
    required double rent,
    Map<String, dynamic>? checklistNegotiation,
  }) async {
    final body = <String, dynamic>{
      'property_id': propertyId,
      'business_name': businessName,
      'term_months': termMonths,
      'rent': rent,
    };
    if (checklistNegotiation != null) {
      body['checklist_negotiation'] = checklistNegotiation;
    }
    final data = await _postJson('applications_create.php', body, auth: true);
    return data['application_id'] as int;
  }

  static Future<List<dynamic>> fetchMyApplications() async {
    final data = await _getJson('applications_mine.php', auth: true);
    return data['applications'] as List<dynamic>;
  }

  static Future<bool> replyToApplication({
    required int applicationId,
    required String message,
  }) async {
    final body = <String, dynamic>{
      'application_id': applicationId,
      'message': message,
    };
    final data = await _postJson('applications_reply.php', body, auth: true);
    return data['ok'] == true;
  }

  static Future<List<Map<String, dynamic>>> fetchChecklistItems() async {
    try {
      final data = await _getJson('checklist_items.php');
      final raw = (data['items'] as List<dynamic>?) ?? [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchContractView() async {
    final data = await _getJson('contract_view.php', auth: true);
    return data;
  }

  // ---------------- Lease status ----------------

  /// Returns null if no active lease, otherwise the lease details map.
  static Future<Map<String, dynamic>?> fetchLeaseStatus() async {
    final data = await _getJson('lease_status.php', auth: true);
    if (data['has_lease'] != true) return null;
    return data['lease'] as Map<String, dynamic>;
  }

  // ---------------- Maintenance tickets ----------------

  static Future<List<dynamic>> fetchTickets() async {
    final data = await _getJson('tickets_list.php', auth: true);
    return data['tickets'] as List<dynamic>;
  }

  static Future<int> createTicket({
    required String category,
    required String priority,
    required String title,
  }) async {
    final data = await _postJson('tickets_create.php', {
      'category': category,
      'priority': priority,
      'title': title,
    }, auth: true);
    return data['ticket_id'] as int;
  }

  // ---------------- Payments ----------------

  static Future<List<dynamic>> fetchPayments() async {
    final data = await _getJson('payments_list.php', auth: true);
    return data['payments'] as List<dynamic>;
  }

  // ---------------- Messages ----------------

  static Future<Map<String, dynamic>> fetchMessagesThread() async {
    final data = await _getJson('messages_thread.php', auth: true);
    return data;
  }

  static Future<void> sendMessage(String text) async {
    await _postJson('messages_send.php', {'body': text}, auth: true);
  }

  // ---------------- Installment / Payment Arrangements ----------------

  static Future<List<dynamic>> fetchInstallmentRequests() async {
    try {
      final data = await _getJson('requests_list.php', auth: true);
      return data['requests'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<int> createInstallmentRequest({
    required String reason,
    required String planLabel,
  }) async {
    final data = await _postJson('requests_create.php', {
      'reason': reason,
      'plan_label': planLabel,
    }, auth: true);
    return data['request_id'] as int;
  }

  // ---------------- Conflict Resolution / Violations (Section C) ----------------

  static const String _kDemoStrikeKey = 'demo_violation_strike_level';
  static const String _kAcknowledgedStrikesKey = 'demo_acknowledged_strikes';

  static Future<int> getDemoStrikeLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDemoStrikeKey) ?? 0;
  }

  static Future<void> setDemoStrikeLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDemoStrikeKey, level);
    // Reset acknowledged set if we switch levels
    final ackList = prefs.getStringList(_kAcknowledgedStrikesKey) ?? [];
    if (level == 0) {
      await prefs.remove(_kAcknowledgedStrikesKey);
    } else {
      // Remove this level from acknowledged list so modal triggers
      ackList.remove(level.toString());
      await prefs.setStringList(_kAcknowledgedStrikesKey, ackList);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchViolations() async {
    try {
      final data = await _getJson('violations_list.php', auth: true);
      final raw = (data['violations'] as List<dynamic>?) ?? [];
      if (raw.isNotEmpty) {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      // Offline or demo fallback
    }

    // Fallback based on Demo Strike Level
    final level = await getDemoStrikeLevel();
    if (level <= 0) return [];

    final prefs = await SharedPreferences.getInstance();
    final ackList = prefs.getStringList(_kAcknowledgedStrikesKey) ?? [];
    final isAck = ackList.contains(level.toString());

    final list = <Map<String, dynamic>>[];
    if (level >= 1) {
      list.add({
        'id': 101,
        'category': 'Late Operating Hours',
        'strike': 1,
        'clause': 'Clause 8.2 — Standard Operating Hours & Curfew',
        'description': 'Stall was observed operating past the mandated commercial closing time of 10:00 PM without prior written permit.',
        'penalty_amount': 0.0,
        'issued_at': '2026-09-18 22:45:00',
        'acknowledged': (level > 1 || isAck) ? 1 : 0,
        'image_url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&q=80',
      });
    }
    if (level >= 2) {
      list.add({
        'id': 102,
        'category': 'Improper Waste Disposal',
        'strike': 2,
        'clause': 'Clause 12.4 — Common Area Sanitation & Waste Disposal',
        'description': 'Commercial garbage bins left outside stall perimeter during non-collection hours, obstructing common hallway walkway.',
        'penalty_amount': 500.0,
        'issued_at': '2026-09-20 09:15:00',
        'acknowledged': (level > 2 || isAck) ? 1 : 0,
        'image_url': 'https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?w=500&q=80',
      });
    }
    if (level >= 3) {
      list.add({
        'id': 103,
        'category': 'Unauthorized Structural Alteration',
        'strike': 3,
        'clause': 'Clause 15.1 — Structural Modifications & Safety Standards',
        'description': 'Heavy electrical wiring installation performed without management authorization and safety inspection permit. Chronic breach threshold reached.',
        'penalty_amount': 1500.0,
        'issued_at': '2026-09-21 14:30:00',
        'acknowledged': isAck ? 1 : 0,
        'image_url': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&q=80',
      });
    }
    return list.reversed.toList();
  }

  static Future<bool> acknowledgeViolation(int violationId, {int? strike}) async {
    try {
      final res = await _postJson('violations_acknowledge.php', {
        'violation_id': violationId,
      }, auth: true);
      if (res['ok'] == true) return true;
    } catch (_) {}

    // Save locally for demo mode
    final prefs = await SharedPreferences.getInstance();
    final ackList = prefs.getStringList(_kAcknowledgedStrikesKey) ?? [];
    if (strike != null) {
      if (!ackList.contains(strike.toString())) {
        ackList.add(strike.toString());
        await prefs.setStringList(_kAcknowledgedStrikesKey, ackList);
      }
    }
    return true;
  }
}
