class TimeUtils {
  /// Formats duration in milliseconds to a human-readable string.
  /// Format: [Dd ]HH:mm:ss.SSS or HH:mm:ss.SSS or mm:ss.SSS
  static String formatDuration(int ms, {bool includeMillis = true}) {
    if (ms == 0) return includeMillis ? "00:00.000" : "0:00";

    final bool isNegative = ms < 0;
    final int absMs = ms.abs();

    final int days = absMs ~/ 86400000;
    final int hours = (absMs % 86400000) ~/ 3600000;
    final int minutes = (absMs % 3600000) ~/ 60000;
    final int seconds = (absMs % 60000) ~/ 1000;
    final int milliseconds = absMs % 1000;

    final StringBuffer buffer = StringBuffer();
    if (isNegative) buffer.write('-');

    if (days > 0) {
      buffer.write('${days}d ');
    }

    if (days > 0 || hours > 0) {
      buffer.write('${hours.toString().padLeft(2, '0')}:');
    }

    buffer.write('${minutes.toString().padLeft(2, '0')}:');
    buffer.write(seconds.toString().padLeft(2, '0'));

    if (includeMillis) {
      buffer.write('.');
      buffer.write(milliseconds.toString().padLeft(3, '0'));
    }

    return buffer.toString();
  }

  /// Formats duration in milliseconds to a concise human-readable string.
  /// Used in feed cards. Example: "1d 2h 30m" or "1h 30m" or "30m"
  static String formatDurationConcise(int ms) {
    if (ms == 0) return "0m";

    final int absMs = ms.abs();
    final int days = absMs ~/ 86400000;
    final int hours = (absMs % 86400000) ~/ 3600000;
    final int minutes = (absMs % 3600000) ~/ 60000;

    final List<String> parts = [];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');

    return parts.join(' ');
  }
}
