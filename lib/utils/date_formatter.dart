import 'package:intl/intl.dart';

class DateFormatter {
  /// Format date from API format (yyyy-MM-dd or yyyy or yyyy-MM) to display format (dd-MM-yyyy)
  static String formatForDisplay(String? date) {
    if (date == null || date.isEmpty) return '';
    
    try {
      // Google Books kan "2015", "2015-12" of "2015-12-08" retourneren
      if (date.length == 4) {
        // Alleen jaar: "2015" -> "01-01-2015"
        return '01-01-$date';
      } else if (date.length == 7) {
        // Jaar-maand: "2015-12" -> "01-12-2015"
        final parts = date.split('-');
        return '01-${parts[1]}-${parts[0]}';
      } else {
        // Volledige datum parsen
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
    } catch (e) {
      return date;
    }
  }

  /// Format date from display format (dd-MM-yyyy) to API format (yyyy-MM-dd)
  static String formatForApi(String? date) {
    if (date == null || date.isEmpty) return '';
    
    try {
      // Probeer eerst dd-MM-yyyy formaat (van display)
      final parsedDate = DateFormat('dd-MM-yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      // Als dat faalt, check of het al een geldig yyyy-MM-dd formaat is
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e2) {
        // Als niets werkt, retourneer lege string in plaats van ongeldige datum
        return '';
      }
    }
  }

  /// Format date for API or return null if invalid
  static String? formatForApiOrNull(String text) {
    if (text.isEmpty) return null;
    final formatted = formatForApi(text);
    return formatted.isEmpty ? null : formatted;
  }

  /// Parse display date string to DateTime
  static DateTime? parseDisplayDate(String? date) {
    if (date == null || date.isEmpty) return null;
    
    try {
      return DateFormat('dd-MM-yyyy').parse(date);
    } catch (e) {
      return null;
    }
  }

  /// Format DateTime to display format
  static String formatDateTimeForDisplay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Extract year from date string in dd-MM-yyyy format
  static int? extractYearFromDisplayDate(String? date) {
    final parsed = parseDisplayDate(date);
    return parsed?.year;
  }
}
