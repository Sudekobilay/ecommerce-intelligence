// mobile_app/lib/utils/formatters.dart

class MetricFormatter {
  static String currency(num value) {
    if (value >= 1000000) {
      return '£${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '£${(value / 1000).toStringAsFixed(1)}K';
    }
    return '£${value.toStringAsFixed(2)}';
  }

  static String compactNumber(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
