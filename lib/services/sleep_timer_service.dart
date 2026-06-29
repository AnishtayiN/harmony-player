import 'dart:async';
import 'package:flutter/foundation.dart';

class SleepTimerService {
  Timer? _timer;
  DateTime? _endTime;
  VoidCallback? _onComplete;
  final StreamController<Duration?> _remainingController =
      StreamController<Duration?>.broadcast();

  Stream<Duration?> get remainingStream => _remainingController.stream;

  Duration? get remaining {
    if (_endTime == null) return null;
    final diff = _endTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isActive => _timer != null && _timer!.isActive;

  void start(Duration duration, VoidCallback onComplete) {
    cancel();
    _onComplete = onComplete;
    _endTime = DateTime.now().add(duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = remaining;
      _remainingController.add(rem);
      if (rem != null && rem.inSeconds <= 0) {
        cancel();
        _onComplete?.call();
      }
    });

    _remainingController.add(remaining);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _onComplete = null;
    _remainingController.add(null);
  }

  void dispose() {
    cancel();
    _remainingController.close();
  }
}
