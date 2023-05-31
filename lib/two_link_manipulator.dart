import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// animate a two link manipulator robot
class TwoLinkManipulator extends StatefulWidget {
  // set canvas width and height to parent widget width and height

  // constructor
  TwoLinkManipulator({Key? key}) : super(key: key);

  @override
  TwoLinkManipulatorState createState() => TwoLinkManipulatorState();
}

class TwoLinkManipulatorState extends State<TwoLinkManipulator>
    with SingleTickerProviderStateMixin {
  // animation controller
  late AnimationController _controller;
  late Animation<double> _animation;

  double _angle1 = 0;
  double _angle2 = 0;

  double _cursorX = 0;
  double _cursorY = 0;

  double _link1Length = 90;
  double _link2Length = 50;
  double _angle1Min = 0;
  double _angle1Max = math.pi * 2;
  double _angle2Min = -math.pi;
  double _angle2Max = math.pi;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateHoverCursorPosition(PointerEvent event, BuildContext context) {
    setState(() {
      _cursorX = event.localPosition.dx;
      _cursorY = event.localPosition.dy;
    });
  }

  void _updateCursorPosition(TapDownDetails details, BuildContext context) {
    setState(() {
      _cursorX = details.localPosition.dx;
      _cursorY = details.localPosition.dy;
    });
    _animateToCursor(context);
  }

  // translate the cursor position to the manipulator
  // world with origin at the center of the canvas
  Offset _translateCursorPosition(width, height) {
    return Offset(
      _cursorX - width / 2,
      _cursorY - height / 2,
    );
  }

  void _animateToCursor(BuildContext context) {
    // get size of the parent widget
    final size = context.size;

    // animate the manipulator from the previous position to the current position
    final initialAngle1 = _angle1;
    final initialAngle2 = _angle2;

    Offset ik = _calculateInverseKinematics(size?.width, size?.height);

    final targetAngle1 = ik.dx;
    final targetAngle2 = ik.dy;

    _controller.reset();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller)
      ..addListener(() {
        setState(() {
          _angle1 = lerpDouble(
            initialAngle1,
            targetAngle1,
            _animation.value,
          )!;
          _angle2 = lerpDouble(
            initialAngle2,
            targetAngle2,
            _animation.value,
          )!;
        });
      });

    _controller.forward();
  }

  Offset _calculateInverseKinematics(width, height) {
    Offset cursorPosition = _translateCursorPosition(width, height);

    double angle1 = math.atan2(cursorPosition.dy, cursorPosition.dx);
    double angle2 = 0;

    double distance = cursorPosition.distance;
    double distanceSquared = distance * distance;

    double link1LengthSquared = _link1Length * _link1Length;
    double link2LengthSquared = _link2Length * _link2Length;

    double cosAngle2 =
        (distanceSquared - link1LengthSquared - link2LengthSquared) /
            (2 * _link1Length * _link2Length);

    if (cosAngle2 < -1 || cosAngle2 > 1) {
      return Offset(angle1, angle2);
    }

    angle2 = math.acos(cosAngle2);

    double sinAngle2 = math.sin(angle2);

    double k1 = _link1Length + _link2Length * cosAngle2;

    double k2 = _link2Length * sinAngle2;

    angle1 = math.atan2(cursorPosition.dy * k1 - cursorPosition.dx * k2,
        cursorPosition.dx * k1 + cursorPosition.dy * k2);

    return Offset(angle1, angle2);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MouseRegion(
        onHover: (event) => _updateHoverCursorPosition(event, context),
        cursor: SystemMouseCursors.none,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            // do something with the details
            _updateCursorPosition(details, context);
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: ManipulatorPainter(
              angle1: _angle1,
              angle2: _angle2,
              cursorX: _cursorX,
              cursorY: _cursorY,
              link1Length: _link1Length,
              link2Length: _link2Length,
              angle1Min: _angle1Min,
              angle1Max: _angle1Max,
              angle2Min: _angle2Min,
              angle2Max: _angle2Max,
            ),
          ),
        ),
      );
    });
  }
}

class ManipulatorPainter extends CustomPainter {
  final double angle1;
  final double angle2;
  final double cursorX;
  final double cursorY;
  final double link1Length;
  final double link2Length;
  final double angle1Min;
  final double angle1Max;
  final double angle2Min;
  final double angle2Max;

  ManipulatorPainter(
      {required this.angle1,
      required this.angle2,
      required this.cursorX,
      required this.cursorY,
      required this.link1Length,
      required this.link2Length,
      required this.angle1Min,
      required this.angle1Max,
      required this.angle2Min,
      required this.angle2Max});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw reachable workspace shade
    final shadePaint = Paint()..color = Colors.blue.withOpacity(0.2);

    // draw a hollow circle to represent the reachable workspace with
    // inner radius = link1Length - link2Length
    // outer radius = link1Length + link2Length

    final double innerRadius = link1Length - link2Length;
    final double outerRadius = link1Length + link2Length;

    final shadeTransparentPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.2);

    // draw the inner circle with transparent paint
    canvas.drawCircle(
      center,
      innerRadius,
      shadeTransparentPaint,
    );

    // draw the outer circle
    canvas.drawCircle(
      center,
      outerRadius,
      shadePaint,
    );

    // Draw links
    final link1Paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final link2Paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final x1 = center.dx + link1Length * math.cos(angle1);
    final y1 = center.dy + link1Length * math.sin(angle1);
    final link1End = Offset(x1, y1);

    final x2 = x1 + link2Length * math.cos(angle1 + angle2);
    final y2 = y1 + link2Length * math.sin(angle1 + angle2);
    final link2End = Offset(x2, y2);

    canvas.drawLine(center, link1End, link1Paint);
    canvas.drawLine(link1End, link2End, link2Paint);

    // Draw cursor
    final cursorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(
        PointMode.points, [Offset(cursorX, cursorY)], cursorPaint);
  }

  @override
  bool shouldRepaint(ManipulatorPainter oldDelegate) {
    return oldDelegate.angle1 != angle1 ||
        oldDelegate.angle2 != angle2 ||
        oldDelegate.cursorX != cursorX ||
        oldDelegate.cursorY != cursorY;
  }
}
