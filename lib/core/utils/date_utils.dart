import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility để parse DateTime từ Firestore một cách an toàn.
/// Xử lý được tất cả các kiểu: Timestamp, String (ISO), int (milliseconds).
class AppDateUtils {
  AppDateUtils._();

  /// Parse DateTime từ bất kỳ kiểu nào Firestore có thể trả về.
  /// Trả về null nếu không parse được.
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    // Kiểu chuẩn — Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // Milliseconds since epoch (int)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // ISO 8601 string
    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  /// Parse DateTime, trả về fallback nếu null (mặc định là DateTime.now())
  static DateTime parseDateOrNow(dynamic value) {
    return parseDate(value) ?? DateTime.now();
  }

  /// Chuyển DateTime sang Firestore Timestamp để lưu
  static Timestamp toTimestamp(DateTime date) {
    return Timestamp.fromDate(date);
  }

  /// Chuyển DateTime? sang Firestore Timestamp? để lưu
  static Timestamp? toTimestampOrNull(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
