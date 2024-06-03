import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion_detector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _motionDetector = MotionDetector();
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  bool _isDetected = false;

  @override
  void initState() {
    super.initState();
    _motionDetector.start();

    _streamSubscriptions.add(
      _motionDetector.userAccelerometerStream.listen(
        (event) {
          setState(() => _isDetected = true);
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() => _isDetected = false);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _motionDetector.stop();
    _streamSubscriptions.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Sensor Test',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 4,
      ),
      body: AnimatedContainer(
        color: _isDetected ? Colors.red : Colors.transparent,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}