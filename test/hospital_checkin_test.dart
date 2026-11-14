import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sathi/features/hospital_checkin/services/hospital_checkin_service.dart';
import 'package:health_sathi/features/upload/domain/entities/ocr_record.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HospitalQrPayload.tryParse', () {
    test('parses JSON QR payload', () {
      const raw =
          '{"type":"healthsathi_checkin","hospitalId":"hosp-uuid-1","hospitalName":"City General","apiBaseUrl":"https://api.healthsathi.test"}';
      final parsed = HospitalQrPayload.tryParse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.hospitalId, 'hosp-uuid-1');
      expect(parsed.hospitalName, 'City General');
      expect(parsed.apiBaseUrl, 'https://api.healthsathi.test');
    });

    test('parses deep-link URI QR payload', () {
      const raw =
          'healthsathi://checkin/hosp-999?name=Square+Hospital&api=https%3A%2F%2Fapi.example.com';
      final parsed = HospitalQrPayload.tryParse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.hospitalId, 'hosp-999');
      expect(parsed.hospitalName, 'Square Hospital');
      expect(parsed.apiBaseUrl, 'https://api.example.com');
    });

    test('parses plain hospital ID string', () {
      final parsed = HospitalQrPayload.tryParse('hosp_abc123');
      expect(parsed, isNotNull);
      expect(parsed!.hospitalId, 'hosp_abc123');
    });

    test('rejects invalid or unrelated QR content', () {
      expect(HospitalQrPayload.tryParse(''), isNull);
      expect(HospitalQrPayload.tryParse('{"type":"other","hospitalId":"123"}'), isNull);
      expect(HospitalQrPayload.tryParse('hello world with spaces'), isNull);
    });
  });

  group('HospitalCheckInService.submitCheckInRequest', () {
    test('sends Firebase bearer token and patientCode, and returns check-in result', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'visitId': 'visit-42',
            'hospitalName': 'City General Hospital',
            'patientCode': 'HS-2026-000001',
            'patientName': 'Akhlak',
            'status': 'CHECKED_IN',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HospitalCheckInService(
        httpClient: client,
        fallbackBaseUrl: 'https://api.healthsathi.test',
      );

      final result = await service.submitCheckInRequest(
        baseUrl: 'https://api.healthsathi.test',
        hospitalId: 'hosp-1',
        idToken: 'firebase-jwt-token',
        patientCode: 'HS-2026-000001',
        activeProfileId: 'self',
        patientName: 'Akhlak',
        bloodGroup: 'O+',
        email: 'akhlak@example.com',
      );

      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'https://api.healthsathi.test/hospitals/hosp-1/check-in',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer firebase-jwt-token');

      final sentBody = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(sentBody['patientCode'], 'HS-2026-000001');
      expect(sentBody['activeProfileId'], 'self');
      expect(sentBody['patientName'], 'Akhlak');
      expect(sentBody['bloodGroup'], 'O+');

      expect(result.visitId, 'visit-42');
      expect(result.hospitalName, 'City General Hospital');
      expect(result.patientCode, 'HS-2026-000001');
      expect(result.status, 'CHECKED_IN');
    });

    test('throws HospitalCheckInException with server message on 404', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Hospital not found or not approved'}),
          404,
        );
      });

      final service = HospitalCheckInService(
        httpClient: client,
        fallbackBaseUrl: 'https://api.healthsathi.test',
      );

      expect(
        () => service.submitCheckInRequest(
          baseUrl: 'https://api.healthsathi.test',
          hospitalId: 'unknown-hosp',
          idToken: 'token',
          patientCode: 'HS-2026-000001',
          activeProfileId: 'self',
          patientName: 'Akhlak',
        ),
        throwsA(
          isA<HospitalCheckInException>().having(
            (e) => e.message,
            'message',
            contains('Hospital not found'),
          ),
        ),
      );
    });
  });

  group('OcrRecord hospital metadata parsing', () {
    test('reads verified hospital report metadata and keeps legacy defaults', () {
      final now = Timestamp.now();
      final hospitalRecord = OcrRecord.fromJson({
        'recordType': 'lab_report',
        'recordLabel': 'CBC Blood Panel',
        'doctorName': 'Dr. John Doe',
        'hospitalName': 'City General Hospital',
        'date': now,
        'pdfUrl': 'https://res.cloudinary.com/demo/raw/upload/report.pdf',
        'createdAt': now,
        'updatedAt': now,
        'userId': 'uid-1',
        'source': 'hospital',
        'hospitalId': 'hosp-1',
        'verifiedByHospital': true,
      }, 'rep-1');

      expect(hospitalRecord.source, 'hospital');
      expect(hospitalRecord.hospitalId, 'hosp-1');
      expect(hospitalRecord.verifiedByHospital, isTrue);

      final legacyRecord = OcrRecord.fromJson({
        'recordType': 'prescription',
        'date': now,
        'createdAt': now,
        'updatedAt': now,
        'userId': 'uid-1',
      }, 'rep-2');

      expect(legacyRecord.source, 'patient');
      expect(legacyRecord.hospitalId, isNull);
      expect(legacyRecord.verifiedByHospital, isFalse);
    });
  });
}

