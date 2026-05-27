import 'package:intl/intl.dart';

class Utils {
  /// Formats a [DateTime] to a readable string, e.g., "Apr 12, 2024".
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Simple regex helpers for OCR extracted text.
  static String? extractDoctorName(String text) {
    final regex = RegExp(r'Dr\.\s*([A-Za-z ]+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String? extractHospitalName(String text) {
    final regex = RegExp(r'Hospital\s*[:\-]\s*([A-Za-z0-9 &]+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static DateTime? extractDate(String text) {
    final regex = RegExp(r'(\d{2}[\/\-]\d{2}[\/\-]\d{4})');
    final match = regex.firstMatch(text);
    if (match != null) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(match.group(0)!);
      } catch (_) {}
    }
    return null;
  }
}
