import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class Accelerometer {
  final double x;
  final double y;
  final double z;
  final DateTime time;

  Accelerometer({required this.x, required this.y, required this.z, required this.time});
}

class MotionDetector {
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Duration _sensorInterval = SensorInterval.uiInterval;
  late AccelerometerHandler _accelerometerXHandler;

  final _userAccelerometerStreamController = StreamController<void>();

  Stream<void> get userAccelerometerStream => _userAccelerometerStreamController.stream;

  MotionDetector() {
    _accelerometerXHandler = AccelerometerHandler(
      name: 'x',
      onDetect: () => _userAccelerometerStreamController.add(null),
    );
  }

  void start() {
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: _sensorInterval).listen(
        (UserAccelerometerEvent event) {
          final now = DateTime.now();
          _accelerometerXHandler.set(event.x, now);
        },
        onError: (e) {
          print(e);
        },
        cancelOnError: true,
      ),
    );
  }

  void stop() {
    _streamSubscriptions.clear();
  }
}

class AccelerometerHandler {
  final String name;
  final void Function() onDetect;

  AccelerometerHandler({required this.name, required this.onDetect});

  double _prevValue = 0;
  double _speed = 0;
  double _prevSpeed = 0;
  double _distance = 0;
  DateTime? _prevTime;

  /// キャリブレーター
  final _calibrator = Calibrator();

  /// ローパスフィルター
  final _lowPassFilter = LowPassFilter();

  final double threshold = 0.2;

  void set(double value, DateTime time) {
    final pTime = _prevTime;
    _prevTime = time;
    if (pTime == null) {
      return;
    }
    final timeSpan = time.difference(pTime).inMilliseconds / 1000;

    // キャリブレーション
    final calibratedValue = _calibrator.calibrate(value);

    final roundedValue = round(calibratedValue, _calibrator.offset);

    // ハイパスフィルター (= センサ値 - ローパスフィルターの値)
    final filteredValue = roundedValue - _lowPassFilter.filter(roundedValue);
    //final filteredValue = calibratedValue - _lowPassFilter.filter(calibratedValue);

    // 速度計算(加速度を台形積分する)
    _speed = ((filteredValue + _prevValue) * timeSpan) / 2 + _speed;
    _prevValue = filteredValue;

    // 変位計算(速度を台形積分する)
    _distance = ((_speed + _prevSpeed) * timeSpan) / 2 + _distance;
    _prevSpeed = _speed;

    print(
        '$name: value=${value.toStringAsFixed(5)}, caliValue=${calibratedValue.toStringAsFixed(5)}, roundedValue=${roundedValue.toStringAsFixed(5)}, filValue=${filteredValue.toStringAsFixed(5)}, speed=${_speed.toStringAsFixed(5)}, distance=${_distance.toStringAsFixed(5)}');

    if (_distance.abs() > threshold) {
      //print('$name: distance=${distance.toStringAsFixed(5)}');
      clear();
      onDetect();
    }
  }

  double round(double value, double offset) {
    if (value.abs() < offset.abs() * 2) {
      return 0;
    } else {
      return value;
    }
  }

  void clear() {
    _prevValue = 0;
    _speed = 0;
    _prevSpeed = 0;
    _distance = 0;
  }
}

/// キャリブレーター
class Calibrator {
  final List<double> _values = [];
  final _numberOfSampling = 30;
  double _offset = 0.0;

  double get offset => _offset;

  double calibrate(double value) {
    if (_values.length < _numberOfSampling) {
      _values.add(value);
      return value;
    } else {
      if (_offset == 0) {
        _offset = _median(_values);
        print('@@@@ _offset = $_offset');
      }
      return value - _offset;
    }
  }

  double _median(List<double> list) {
    list.sort();
    final middle = list.length ~/ 2;
    if (list.length % 2 == 1) {
      return list[middle];
    } else {
      return (list[middle - 1] + list[middle]) / 2.0;
    }
  }
}

class Rounder {
  double round(double value, double offset) {
    if (value.abs() < offset.abs()) {
      return 0;
    } else {
      return value;
    }
  }
}

/// ローパスフィルター
class LowPassFilter {
  final double rate = 0.8;
  double _prevValue = 0;

  double filter(double value) {
    final output = rate * value + _prevValue * (1 - rate);
    _prevValue = value;
    return output;
  }
}