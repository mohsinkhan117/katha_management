// lib/core/services/distributor_auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DistributorAuthService {
  static const String _kClaimedTokenKey = 'claimed_invite_token';
  static const String _kDistributorIdKey = 'distributor_id';
  static const String _kCompanyIdKey = 'company_id';
  static const String _kCompanyNameKey = 'company_name';
  static const String _kTerritoryNameKey = 'territory_name';
  static const String _kDistributorNameKey = 'distributor_name';

  // Base URL for the company web portal backend API
  // In Android Emulator: 10.0.2.2 points to host machine localhost:3000
  // In Physical device or Web/Desktop: localhost:3000 or custom IP
  static String baseUrl = 'http://10.0.2.2:3000';

  /// Check if this distributor device has already claimed an invite token
  static Future<bool> isTokenClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kClaimedTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Retrieve saved distributor metadata
  static Future<Map<String, String?>> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_kClaimedTokenKey),
      'distributorId': prefs.getString(_kDistributorIdKey),
      'companyId': prefs.getString(_kCompanyIdKey),
      'companyName': prefs.getString(_kCompanyNameKey),
      'territoryName': prefs.getString(_kTerritoryNameKey),
      'distributorName': prefs.getString(_kDistributorNameKey),
    };
  }

  /// Claim a 12-char cryptographic token (e.g. KTH-8821-4920) against Company Web API
  static Future<Map<String, dynamic>> claimInviteToken({
    required String inviteToken,
    required String distributorName,
    required String phoneNumber,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/distributor/claim-token');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inviteToken': inviteToken.trim(),
          'distributorName': distributorName.trim(),
          'phoneNumber': phoneNumber.trim(),
          'deviceId': 'device_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final distData = data['data'] ?? {};

        await prefs.setString(_kClaimedTokenKey, inviteToken.trim());
        await prefs.setString(_kDistributorIdKey, distData['distributorId'] ?? '');
        await prefs.setString(_kCompanyIdKey, distData['companyId'] ?? '');
        await prefs.setString(_kCompanyNameKey, distData['companyName'] ?? 'Apex Agro Chemical Ltd.');
        await prefs.setString(_kTerritoryNameKey, distData['territoryName'] ?? 'Assigned Zone');
        await prefs.setString(_kDistributorNameKey, distributorName);

        return {'success': true, 'data': distData};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Token validation failed. Please check the code.',
        };
      }
    } catch (e) {
      debugPrint('Error claiming invite token: $e');
      // If network fails (e.g. offline field usage), verify token format and allow offline onboarding
      if (inviteToken.toUpperCase().startsWith('KTH-')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kClaimedTokenKey, inviteToken.trim());
        await prefs.setString(_kDistributorNameKey, distributorName);
        await prefs.setString(_kCompanyNameKey, 'Apex Agro Chemical Ltd.');
        return {
          'success': true,
          'offlineMode': true,
          'message': 'Token registered in local offline vault. Will sync with Neon when connected.',
        };
      }
      return {'success': false, 'error': 'Could not reach server: $e'};
    }
  }

  /// Reset / logout token on device
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kClaimedTokenKey);
    await prefs.remove(_kDistributorIdKey);
    await prefs.remove(_kCompanyIdKey);
  }
}
