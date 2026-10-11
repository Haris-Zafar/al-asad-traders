import 'package:intl/intl.dart';

/// PKR Currency Utility
/// Enforces integer PKR currency representation across the app.
abstract class PkrFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  /// Formats integer PKR amount into standard display format: `Rs. 1,200`
  static String format(int pkrAmount) {
    return 'Rs. ${_formatter.format(pkrAmount)}';
  }

  /// Formats integer PKR amount without prefix: `1,200`
  static String formatNumberOnly(int pkrAmount) {
    return _formatter.format(pkrAmount);
  }

  /// Formats integer PKR with suffix/unit, e.g. `Rs. 1,200 / unit`
  static String formatWithUnit(int pkrAmount, {String unit = 'unit'}) {
    return 'Rs. ${_formatter.format(pkrAmount)} / $unit';
  }

  /// Parses user input string safely to integer PKR. Returns `null` if invalid.
  static int? parsePkr(String input) {
    final cleanInput = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanInput.isEmpty) return null;
    return int.tryParse(cleanInput);
  }
}
