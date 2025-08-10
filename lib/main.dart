import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(900, 300),
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _DesktopWidgetState();
}

class _DesktopWidgetState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () {
            // Widget interaction
          },
          onPanUpdate: (details) {
            // Make widget draggable
            windowManager.startDragging();
          },
          child: FlipClock(),
        ),
      ),
    );
  }
}

class FlipClock extends StatefulWidget {
  const FlipClock({super.key});

  @override
  State<FlipClock> createState() => _FlipClockState();
}

class _FlipClockState extends State<FlipClock> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final hours = _formatTime(_currentTime.hour);
    final minutes = _formatTime(_currentTime.minute);
    final seconds = _formatTime(_currentTime.second);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlipDigit(digit: hours[0]),
        SizedBox(width: 4),
        FlipDigit(digit: hours[1]),
        SizedBox(width: 16),
        TimeSeparator(),
        SizedBox(width: 16),
        FlipDigit(digit: minutes[0]),
        SizedBox(width: 4),
        FlipDigit(digit: minutes[1]),
        SizedBox(width: 16),
        TimeSeparator(),
        SizedBox(width: 16),
        FlipDigit(digit: seconds[0]),
        SizedBox(width: 4),
        FlipDigit(digit: seconds[1]),
      ],
    );
  }
}

class TimeSeparator extends StatelessWidget {
  const TimeSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class FlipDigit extends StatefulWidget {
  final String digit;

  const FlipDigit({super.key, required this.digit});

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  String? _previousDigit;
  String? _nextDigit;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInCubic),
    );

    _previousDigit = widget.digit;
    _nextDigit = widget.digit;

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _previousDigit = _nextDigit;
          _isFlipping = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      setState(() {
        _nextDigit = widget.digit;
        _isFlipping = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 160,
      child: Stack(
        children: [
          // Background card
          FlipCard(digit: _previousDigit!, isTop: true),
          FlipCard(digit: _previousDigit!, isTop: false),

          // Animated flip cards
          if (_isFlipping) ...[
            // Top half flipping down
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                if (_flipAnimation.value < 0.5) {
                  return Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(-_flipAnimation.value * math.pi),
                    child: FlipCard(digit: _previousDigit!, isTop: true),
                  );
                } else {
                  return Container();
                }
              },
            ),

            // Bottom half flipping up
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                if (_flipAnimation.value >= 0.5) {
                  return Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX((_flipAnimation.value - 1) * math.pi),
                    child: FlipCard(digit: _nextDigit!, isTop: false),
                  );
                } else {
                  return Container();
                }
              },
            ),

            // New top half (appears instantly at halfway point)
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                if (_flipAnimation.value >= 0.5) {
                  return FlipCard(digit: _nextDigit!, isTop: true);
                } else {
                  return Container();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class FlipCard extends StatelessWidget {
  final String digit;
  final bool isTop;

  const FlipCard({super.key, required this.digit, required this.isTop});

  @override
  Widget build(BuildContext context) {
    const height = 80.0;
    return Container(
      width: 120,
      height: height,
      margin: EdgeInsets.only(top: isTop ? 0 : height),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 60,
          height: height,
          child: OverflowBox(
            minHeight: height * 2,
            maxHeight: height * 2,
            child: Container(
              height: height * 2,
              width: 60,
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, isTop ? height / 2 : -(height / 2)),
              child: Text(
                digit,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
