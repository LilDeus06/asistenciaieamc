import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimeZoneHelper {
  static bool _initialized = false;

  static void initializeTimeZones() {
    if (!_initialized) {
      tz.initializeTimeZones();
      final location = tz.getLocation('America/Lima');
      tz.setLocalLocation(location);
      _initialized = true;
    }
  }

  static tz.TZDateTime nowInLima() {
    if (!_initialized) {
      throw Exception('TimeZoneHelper has not been initialized. Call initializeTimeZones() first.');
    }
    return tz.TZDateTime.now(tz.local);
  }
}
