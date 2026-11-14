import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_config.dart';
import '../../auth/services/patient_id_service.dart';

/// Parsed representation of a hospital check-in QR code.
class HospitalQrPayload {
  final String hospitalId;
  final String? hospitalName;
  final String? apiBaseUrl;

  const HospitalQrPayload({
    required this.hospitalId,
    this.hospitalName,
    this.apiBaseUrl,
  });

  /// Parses QR code text in JSON, `healthsathi://checkin/<id>` URI, or plain ID format.
  /// Returns `null` if the scanned value is empty or not a recognized hospital QR payload.
  static HospitalQrPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. JSON payload: {"type":"healthsathi_checkin","hospitalId":"...","hospitalName":"..."}
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final type = (decoded['type'] ?? '').toString().trim();
          final id = (decoded['hospitalId'] ?? decoded['hospital_id'] ?? '')
              .toString()
              .trim();
          if (id.isNotEmpty &&
              (type.isEmpty ||
                  type == 'healthsathi_checkin' ||
                  type == 'healthsathi_hospital_checkin')) {
            final name =
                (decoded['hospitalName'] ?? decoded['hospital_name'])
                    ?.toString()
                    .trim();
            final apiUrl =
                (decoded['apiBaseUrl'] ?? decoded['api_base_url'])
                    ?.toString()
                    .trim();
            return HospitalQrPayload(
              hospitalId: id,
              hospitalName: (name != null && name.isNotEmpty) ? name : null,
              apiBaseUrl: (apiUrl != null && apiUrl.isNotEmpty) ? apiUrl : null,
            );
          }
        }
      } catch (_) {
        return null;
      }
      return null;
    }

    // 2. Deep link URI: healthsathi://checkin/<hospitalId>?name=...&api=...
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'healthsathi' && uri.host == 'checkin') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final id = segments.isNotEmpty
          ? segments.first
          : (uri.queryParameters['hospitalId'] ?? '').trim();
      if (id.isEmpty) return null;
      final name = uri.queryParameters['name']?.trim();
      final api = uri.queryParameters['api']?.trim();
      return HospitalQrPayload(
        hospitalId: id,
        hospitalName: (name != null && name.isNotEmpty) ? name : null,
        apiBaseUrl: (api != null && api.isNotEmpty) ? api : null,
      );
    }

    // 3. Plain hospital ID (UUID or alphanumeric code without whitespace)
    if (RegExp(r'^[a-zA-Z0-9_-]{6,64}$').hasMatch(trimmed)) {
      return HospitalQrPayload(hospitalId: trimmed);
    }

    return null;
  }
}

/// Result returned when a patient successfully checks in at a hospital.
class HospitalCheckInResult {
  final String hospitalId;
  final String hospitalName;
  final String? visitId;
  final String patientCode;
  final String patientName;
  final String status;

  const HospitalCheckInResult({
    required this.hospitalId,
    required this.hospitalName,
    this.visitId,
    required this.patientCode,
    required this.patientName,
    this.status = 'CHECKED_IN',
  });
}

/// Typed exception for user-friendly error messages during hospital check-in.
class HospitalCheckInException implements Exception {
  final String message;
  const HospitalCheckInException(this.message);

  @override
  String toString() => message;
}

/// Handles sending the patient's verified identity & Patient ID (`HS-YYYY-XXXXXX`)
/// to the `healthSathi-v2` NestJS backend after scanning a hospital QR code.
class HospitalCheckInService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final String? _fallbackBaseUrl;

  HospitalCheckInService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    String? fallbackBaseUrl,
  })  : _auth = auth,
        _firestore = firestore,
        _httpClient = httpClient ?? http.Client(),
        _fallbackBaseUrl = fallbackBaseUrl;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Resolves the active backend base URL from the QR payload or `.env` configuration.
  String resolveBaseUrl(HospitalQrPayload payload) {
    final candidate = (payload.apiBaseUrl != null && payload.apiBaseUrl!.isNotEmpty)
        ? payload.apiBaseUrl!
        : (_fallbackBaseUrl ?? EnvConfig.hospitalApiBaseUrl);

    final normalized = candidate.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw const HospitalCheckInException(
        'Hospital server URL is not configured. Set HOSPITAL_API_BASE_URL in .env or scan a QR with server URL.',
      );
    }
    return normalized;
  }

  /// Sends the check-in request for [activeProfileId] (`'self'` or family profile ID).
  Future<HospitalCheckInResult> checkIn({
    required HospitalQrPayload payload,
    required String activeProfileId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const HospitalCheckInException(
        'You must be logged in to check in at a hospital.',
      );
    }

    final baseUrl = resolveBaseUrl(payload);

    // 1. Ensure sequential Patient ID (HS-YYYY-XXXXXX) exists in Firestore.
    final patientCode = await PatientIdService(_db).ensurePatientId(user.uid);

    // 2. Read active profile metadata for display in the hospital reception queue.
    String patientName = user.displayName ?? 'HealthSathi Patient';
    String bloodGroup = '';

    try {
      final profileRef = activeProfileId == 'self'
          ? _db.collection('users').doc(user.uid)
          : _db
              .collection('users')
              .doc(user.uid)
              .collection('familyProfiles')
              .doc(activeProfileId);

      final snap = await profileRef.get();
      final data = snap.data();
      if (data != null) {
        final fetchedName = (data['name'] ?? data['fullName'] ?? '').toString().trim();
        if (fetchedName.isNotEmpty) {
          patientName = fetchedName;
        }
        bloodGroup = (data['bloodGroup'] ?? '').toString().trim();
      }
    } catch (_) {
      // Non-fatal: continue with FirebaseAuth display name if offline cache misses.
    }

    // 3. Get verified Firebase ID token for healthSathi-v2 FirebaseAuthGuard.
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw const HospitalCheckInException(
        'Could not obtain authentication token. Please sign in again.',
      );
    }

    return submitCheckInRequest(
      baseUrl: baseUrl,
      hospitalId: payload.hospitalId,
      fallbackHospitalName: payload.hospitalName,
      idToken: idToken,
      patientCode: patientCode,
      activeProfileId: activeProfileId,
      patientName: patientName,
      bloodGroup: bloodGroup,
      email: user.email ?? '',
    );
  }

  /// Executes the HTTP POST `/hospitals/:hospitalId/check-in` request.
  /// Exposed cleanly for unit testing.
  Future<HospitalCheckInResult> submitCheckInRequest({
    required String baseUrl,
    required String hospitalId,
    String? fallbackHospitalName,
    required String idToken,
    required String patientCode,
    required String activeProfileId,
    required String patientName,
    String bloodGroup = '',
    String email = '',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/hospitals/${Uri.encodeComponent(hospitalId)}/check-in',
    );

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'patientCode': patientCode,
              'activeProfileId': activeProfileId,
              'patientName': patientName,
              'bloodGroup': bloodGroup,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final bodyText = response.body;
      Map<String, dynamic> jsonBody = {};
      if (bodyText.isNotEmpty) {
        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic>) {
            jsonBody = decoded;
          }
        } catch (_) {}
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final hospitalName = (jsonBody['hospitalName'] ??
                fallbackHospitalName ??
                'Hospital')
            .toString();
        return HospitalCheckInResult(
          hospitalId: hospitalId,
          hospitalName: hospitalName,
          visitId: jsonBody['visitId']?.toString() ?? jsonBody['id']?.toString(),
          patientCode: (jsonBody['patientCode'] ?? patientCode).toString(),
          patientName: (jsonBody['patientName'] ?? patientName).toString(),
          status: (jsonBody['status'] ?? 'CHECKED_IN').toString(),
        );
      }

      final serverMsg =
          (jsonBody['message'] ?? jsonBody['error'] ?? '').toString().trim();
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw HospitalCheckInException(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Session verification failed. Please log in again.',
        );
      }
      if (response.statusCode == 404) {
        throw HospitalCheckInException(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Hospital not found or not approved yet.',
        );
      }
      throw HospitalCheckInException(
        serverMsg.isNotEmpty
            ? serverMsg
            : 'Check-in failed (HTTP ${response.statusCode}).',
      );
    } on HospitalCheckInException {
      rethrow;
    } on SocketException catch (e) {
      throw HospitalCheckInException(
        'Cannot reach hospital server (${e.message}). Check your internet connection.',
      );
    } on TimeoutException {
      throw const HospitalCheckInException(
        'Connection to hospital server timed out. Please try again.',
      );
    } catch (e) {
      throw HospitalCheckInException('Check-in failed: $e');
    }
  }
}

