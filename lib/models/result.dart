// Hasil satu kuartal simulasi. Murni Dart.
import 'quarter_state.dart';

class QuarterResult {
  final QuarterState prev;
  final QuarterState next;
  // Log 11 langkah agar dapat diaudit/diuji.
  final List<String> logs;
  // Id event yang dipicu kuartal ini.
  final List<String> triggeredEvents;
  final List<String> warnings;

  const QuarterResult({
    required this.prev,
    required this.next,
    required this.logs,
    required this.triggeredEvents,
    required this.warnings,
  });
}
