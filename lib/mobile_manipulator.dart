// an animation of a mobile manipulator robot with a three link arm
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// create a mobile manipulator robot painter
class MobileManipulatorPainter extends CustomPainter {
  // set canvas width and height to parent widget width and height
  final double width;
  final double height;

  final double playGroundHeight;

  final double wheelRadius = 10;
  final double wheelDistance = 50;
  final double baseWidth = 100;
  final double baseHeight = 50;

  final double armLink1Length = 50;
  final double armLink2Length = 50;
  final double armLink3Length = 50;

  final double armLink1Angle;
  final double armLink2Angle;
  final double armLink3Angle;

  final double baseX;

  final double cubeX;
  final double cubeY;

  late double cubeXComputed;
  late double cubeYComputed;

  final Function onCubePositionComputed;

  final bool isCubePickedUp;

  // constructor
  MobileManipulatorPainter(
      {required this.width,
      required this.height,
      required this.playGroundHeight,
      required this.baseX,
      required this.armLink1Angle,
      required this.armLink2Angle,
      required this.armLink3Angle,
      required this.cubeX,
      required this.cubeY,
      required this.isCubePickedUp,
      required this.onCubePositionComputed});

  @override
  void paint(Canvas canvas, Size size) {
    // set canvas background color
    canvas.drawColor(Colors.white, BlendMode.color);

    // set paint properties
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // wheel paint
    final wheelPaint = Paint()
      ..color = const Color.fromARGB(255, 154, 153, 153)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // arm paint
    final armLink1Paint = Paint()
      ..color = Color.fromARGB(255, 207, 122, 37)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final armLink2Paint = Paint()
      ..color = Color.fromARGB(255, 156, 88, 19)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final armLink3Paint = Paint()
      ..color = Color.fromARGB(255, 227, 158, 89)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // compute base position
    double baseY = playGroundHeight - wheelRadius - baseHeight / 2;

    // draw a playground for the robot with 200 in height and full canvas width
    double canvasWidth = width;
    canvas.drawLine(Offset(0, playGroundHeight),
        Offset(canvasWidth, playGroundHeight), paint);

    // draw a base attached to the wheels with wheelRadius above the playground
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(baseX, baseY), width: baseWidth, height: baseHeight),
        paint);

    // compute wheel positions
    double wheel1X = baseX - wheelDistance / 2;
    double wheel1Y = playGroundHeight - wheelRadius;

    double wheel2X = baseX + wheelDistance / 2;
    double wheel2Y = playGroundHeight - wheelRadius;

    // draw two wheels centered above the playground
    canvas.drawCircle(
        Offset(wheel1X, wheel1Y), wheelRadius, wheelPaint); // left wheel

    canvas.drawCircle(
        Offset(wheel2X, wheel2Y), wheelRadius, wheelPaint); // right wheel

    // compute relative position of the arm links
    double armLink1X = baseX + baseWidth / 4;
    double armLink1Y = playGroundHeight - wheelRadius - baseHeight;

    canvas.drawLine(
        Offset(armLink1X, armLink1Y),
        Offset(armLink1X + armLink1Length * math.cos(armLink1Angle),
            armLink1Y + armLink1Length * math.sin(armLink1Angle)),
        armLink1Paint);

    double armLink2X = armLink1X + armLink1Length * math.cos(armLink1Angle);
    double armLink2Y = armLink1Y + armLink1Length * math.sin(armLink1Angle);

    canvas.drawLine(
        Offset(armLink2X, armLink2Y),
        Offset(armLink2X + armLink2Length * math.cos(armLink2Angle),
            armLink2Y + armLink2Length * math.sin(armLink2Angle)),
        armLink2Paint);

    double armLink3X = armLink2X + armLink2Length * math.cos(armLink2Angle);
    double armLink3Y = armLink2Y + armLink2Length * math.sin(armLink2Angle);

    canvas.drawLine(
        Offset(armLink3X, armLink3Y),
        Offset(armLink3X + armLink3Length * math.cos(armLink3Angle),
            armLink3Y + armLink3Length * math.sin(armLink3Angle)),
        armLink3Paint);

    final endEffectorPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // draw end effector as half circle
    double endEffectorRadius = 10;

    // end-effector position is at the tip of the third arm link including the
    // end-effector radius offset as a function of the angle of the third arm link
    double endEffectorX = armLink3X +
        armLink3Length * math.cos(armLink3Angle) +
        endEffectorRadius * math.cos(armLink3Angle);
    double endEffectorY = armLink3Y +
        armLink3Length * math.sin(armLink3Angle) +
        endEffectorRadius * math.sin(armLink3Angle);

    double endEffectorEndAngle = math.pi;

    // end effector start angle as a function of the angle of the third arm link
    double endEffectorStartAngle = armLink3Angle + endEffectorEndAngle / 2;

    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(endEffectorX, endEffectorY),
            width: endEffectorRadius * 2,
            height: endEffectorRadius * 2),
        endEffectorStartAngle,
        endEffectorEndAngle,
        false,
        endEffectorPaint);

    // draw a cube that can be picked up by the end effector
    // cube paint
    final cubePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    double cubeWidth = 20;
    double cubeHeight = 20;

    Offset cubeCenter = Offset(cubeX, cubeY);

    if (isCubePickedUp) {
      // compute the cube position based on the end effector position
      double cubeXComputed =
          endEffectorX + endEffectorRadius * math.cos(armLink3Angle);
      double cubeYComputed =
          endEffectorY + endEffectorRadius * math.sin(armLink3Angle);

      // when cube is picked up, if it crosses canvas top, move it to the bottom
      if (cubeYComputed < 6) {
        // save the current canvas state
        canvas.save();

        // translate to the end effector's position
        canvas.translate(endEffectorX, endEffectorY);

        // rotate the canvas by the end effector's rotation angle
        canvas.rotate(armLink3Angle);

        // translate back
        canvas.translate(-endEffectorX, -endEffectorY);

        cubeYComputed = height - cubeHeight / 2;
        cubeXComputed = endEffectorX;

        onCubePositionComputed(cubeXComputed, cubeYComputed);

        // restore the canvas state
        canvas.restore();
      }

      cubeCenter = Offset(cubeXComputed, cubeYComputed);

      // save the current canvas state
      canvas.save();

      // translate to the cube's center
      canvas.translate(cubeCenter.dx, cubeCenter.dy);

      // rotate the canvas by the end effector's rotation angle
      canvas.rotate(armLink3Angle);

      // translate back
      canvas.translate(-cubeCenter.dx, -cubeCenter.dy);
    }

    // draw the cube
    canvas.drawRect(
        Rect.fromCenter(
            center: cubeCenter, width: cubeWidth, height: cubeHeight),
        cubePaint);

    // restore the canvas state
    if (isCubePickedUp) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  double getCubeXComputed() {
    return cubeXComputed;
  }

  double getCubeYComputed() {
    return cubeYComputed;
  }
}

// create a mobile manipulator robot widget
class MobileManipulator extends StatefulWidget {
  // constructor
  const MobileManipulator({Key? key}) : super(key: key);

  @override
  MobileManipulatorState createState() => MobileManipulatorState();
}

class MobileManipulatorState extends State<MobileManipulator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _baseController;
  late AnimationController _armController;
  late AnimationController _pickUpController;

  GravitySimulation? _gravitySimulation;

  // limits for the arm links
  double armLink1AngleMin = -math.pi + math.pi / 10;
  double armLink1AngleMax = -math.pi / 10;
  double armLink2AngleMin = -math.pi;
  double armLink2AngleMax = math.pi / 4;
  double armLink3AngleMin = -math.pi / 2;
  double armLink3AngleMax = 3 * math.pi / 2;

  final double armLink1Length = 50;
  final double armLink2Length = 60;
  final double armLink3Length = 50;

  // variables
  double playGroundHeight = 225;
  double baseXDefault = 200;
  double armLink1DefaultAngle = -math.pi / 2;
  double armLink2DefaultAngle = 0.0;
  double armLink3DefaultAngle = math.pi / 2;

  double cubeDimension = 20;
  double cubeDefaultX = 500;

  double baseCubeOffset = 70;

  late double cubeX = cubeDefaultX;
  late double? cubeY;
  bool isCubePickedUp = false;

  final double baseWidth = 100;
  late double baseX = baseXDefault;
  late double armLink1Angle = armLink1DefaultAngle;
  late double armLink2Angle = armLink2DefaultAngle;
  late double armLink3Angle = armLink3DefaultAngle;

  @override
  void initState() {
    super.initState();
    cubeY = playGroundHeight - cubeDimension / 2 + 55;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _gravitySimulation = null;
    super.dispose();
  }

  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double parentWidth = constraints.maxWidth;
        double parentHeight = constraints.maxHeight;

        return GestureDetector(
          onPanDown: (DragDownDetails details) {
            double dx = details.localPosition.dx - cubeX;
            double dy = details.localPosition.dy - cubeY!;
            if (dx * dx + dy * dy <= cubeDimension * cubeDimension) {
              isDragging = true;
            }
          },
          onPanUpdate: (DragUpdateDetails details) {
            if (isDragging) {
              setState(() {
                double newCubeX = cubeX + details.delta.dx;
                double newCubeY = (cubeY ?? 0) + details.delta.dy;

                // Check if the new position is within the parent's bounds
                if (newCubeX >= 0 &&
                    newCubeX <= parentWidth - cubeDimension - 50) {
                  cubeX = newCubeX;
                }
                // if newCubeY is crossing the parent, then set it to parent boundary
                if (newCubeY >= 0 && newCubeY <= parentHeight - cubeDimension) {
                  cubeY = newCubeY;
                } else if (newCubeY < 0) {
                  cubeY = 0;
                } else {
                  cubeY = parentHeight - cubeDimension;
                }
              });
            }
          },
          onPanEnd: (DragEndDetails details) {
            isDragging = false;

            // Check if the cube is within the robot base
            if (cubeX >= baseX - baseWidth / 2 &&
                cubeX <= baseX + baseWidth / 2 + 50) {
              cubeX = baseX + baseWidth / 2 + 70;
            }

            // check if the cube is within the playground including the base
            if (cubeX <= baseWidth + baseCubeOffset ||
                cubeX >= parentWidth - cubeDimension) {
              cubeX = cubeDefaultX;
              cubeY = playGroundHeight - cubeDimension / 2 + 55;
            }

            _gravitySimulation = GravitySimulation(
              0.0,
              playGroundHeight - cubeDimension / 2,
              cubeY!,
              0,
            );

            _controller = AnimationController(
              vsync: this,
              duration: Duration(seconds: 1),
            )..addListener(() {
                setState(() {
                  cubeY = _gravitySimulation!.x(_controller.value);
                });

                // Stop the simulation when the cube reaches the playGroundHeight
                if (_controller.value >= playGroundHeight - cubeDimension / 2) {
                  _controller.stop();
                }
              });

            _controller.forward(from: 0.0);

            // Start an animation to move the base closer to the cube

            // Define the initial and final positions of the base
            double initialBaseX = baseX;
            double finalBaseX = cubeX - baseWidth / 2 - baseCubeOffset;

            // Create a Tween to interpolate between the initial and final positions
            Tween<double> baseXTween = Tween<double>(
              begin: initialBaseX,
              end: finalBaseX,
            );

            _baseController = AnimationController(
              vsync: this,
              duration: Duration(milliseconds: 500),
            )..addListener(() {
                setState(() {
                  baseX = baseXTween.transform(_baseController.value);
                });

                // Stop the animation when the base reaches the cube
                if (_baseController.value >= 1.0) {
                  _baseController.stop();
                }
              });

            // Start the baseController after a delay of 0.5 seconds
            Future.delayed(Duration(milliseconds: 100), () {
              _baseController.forward(from: 0.0);
            });

            // Compute the inverse kinematics for the three link manipulator
            List ik = _calculateInverseKinematics(Offset(cubeX, cubeY!));

            // Define the initial and final angles of the arm links
            double initialArmLink1Angle = armLink1Angle;
            double finalArmLink1Angle = ik[0];

            double initialArmLink2Angle = armLink2Angle;
            double finalArmLink2Angle = ik[1];

            double initialArmLink3Angle = armLink3Angle;
            double finalArmLink3Angle = ik[2];

            // Create a Tween to interpolate between the initial and final angles
            Tween<double> armLink1AngleTween = Tween<double>(
              begin: initialArmLink1Angle,
              end: finalArmLink1Angle,
            );

            Tween<double> armLink2AngleTween = Tween<double>(
              begin: initialArmLink2Angle,
              end: finalArmLink2Angle,
            );

            Tween<double> armLink3AngleTween = Tween<double>(
              begin: initialArmLink3Angle,
              end: finalArmLink3Angle,
            );

            _armController = AnimationController(
              vsync: this,
              duration: Duration(milliseconds: 500),
            )..addListener(() {
                setState(() {
                  armLink1Angle =
                      armLink1AngleTween.transform(_armController.value);
                  armLink2Angle =
                      armLink2AngleTween.transform(_armController.value);
                  armLink3Angle =
                      armLink3AngleTween.transform(_armController.value);
                });

                // Stop the animation when the arm links reach the target angles
                if (_armController.value >= 1.0) {
                  _armController.stop();
                }
              });

            // Start the armController after a delay of 0.5 seconds
            Future.delayed(Duration(milliseconds: 100), () {
              _armController.forward(from: 0.0);
            });

            // Start the armController after a delay of 0.5 seconds
            _armController.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                // pick up the cube and push it up
                initialArmLink1Angle = armLink1Angle;
                finalArmLink1Angle = -math.pi / 2;
                initialArmLink2Angle = armLink2Angle;
                finalArmLink2Angle = -math.pi / 2;
                initialArmLink3Angle = armLink3Angle;
                finalArmLink3Angle = -math.pi / 2;

                isCubePickedUp = true;

                armLink1AngleTween = Tween<double>(
                  begin: initialArmLink1Angle,
                  end: finalArmLink1Angle,
                );

                armLink2AngleTween = Tween<double>(
                  begin: initialArmLink2Angle,
                  end: finalArmLink2Angle,
                );

                armLink3AngleTween = Tween<double>(
                  begin: initialArmLink3Angle,
                  end: finalArmLink3Angle,
                );

                _pickUpController = AnimationController(
                  vsync: this,
                  duration: Duration(seconds: 1),
                )..addListener(() {
                    setState(() {
                      armLink1Angle =
                          armLink1AngleTween.transform(_pickUpController.value);
                      armLink2Angle =
                          armLink2AngleTween.transform(_pickUpController.value);
                      armLink3Angle =
                          armLink3AngleTween.transform(_pickUpController.value);

                      isCubePickedUp = true;
                    });

                    // Stop the animation when the arm links reach the target angles
                    if (_pickUpController.value >= 1.0) {
                      _pickUpController.stop();
                    }
                  });

                Future.delayed(Duration(milliseconds: 100), () {
                  _pickUpController.forward(from: 0.0);
                });

                // set the isCubePickedUp to false after 1 second
                _pickUpController.addStatusListener((status) {
                  if (status == AnimationStatus.completed) {
                    isCubePickedUp = false;

                    // move the links back to the default position
                    initialArmLink1Angle = armLink1Angle;
                    finalArmLink1Angle = armLink1DefaultAngle;
                    initialArmLink2Angle = armLink2Angle;
                    finalArmLink2Angle = armLink2DefaultAngle;
                    initialArmLink3Angle = armLink3Angle;
                    finalArmLink3Angle = armLink3DefaultAngle;

                    armLink1AngleTween = Tween<double>(
                      begin: initialArmLink1Angle,
                      end: finalArmLink1Angle,
                    );

                    armLink2AngleTween = Tween<double>(
                      begin: initialArmLink2Angle,
                      end: finalArmLink2Angle,
                    );

                    armLink3AngleTween = Tween<double>(
                      begin: initialArmLink3Angle,
                      end: finalArmLink3Angle,
                    );

                    _armController = AnimationController(
                      vsync: this,
                      duration: Duration(milliseconds: 500),
                    )..addListener(() {
                        setState(() {
                          armLink1Angle = armLink1AngleTween
                              .transform(_armController.value);
                          armLink2Angle = armLink2AngleTween
                              .transform(_armController.value);
                          armLink3Angle = armLink3AngleTween
                              .transform(_armController.value);
                        });

                        // Stop the animation when the arm links reach the target angles
                        if (_armController.value >= 1.0) {
                          _armController.stop();
                        }
                      });

                    // Start the armController after a delay of 0.5 seconds
                    Future.delayed(Duration(milliseconds: 100), () {
                      _armController.forward(from: 0.0);
                    });
                  }
                });
              }
            });

            // set the isCubePickedUp to false after 1 second
          },
          child: CustomPaint(
            painter: MobileManipulatorPainter(
                width: parentWidth,
                height: parentHeight,
                playGroundHeight: playGroundHeight,
                baseX: baseX,
                armLink1Angle: armLink1Angle,
                armLink2Angle: armLink2Angle,
                armLink3Angle: armLink3Angle,
                cubeX: cubeX,
                cubeY: cubeY!,
                isCubePickedUp: isCubePickedUp,
                onCubePositionComputed: (double x, double y) {
                  cubeX = x;
                  cubeY = y;
                }),
            size: Size(parentWidth, parentHeight),
          ),
        );
      },
    );
  }

  // inverse kinematics for the three link manipulator
  List _calculateInverseKinematics(Offset cubePos) {
    // get the position of the cube
    double x = cubePos.dx;
    double y = cubePos.dy;

    double theta1 = -math.atan2(y, x);

    double c2 = (x * x +
            y * y -
            armLink1Length * armLink1Length -
            armLink2Length * armLink2Length) /
        (2 * armLink1Length * armLink2Length);

    // Ensure that c2 is within the valid range [-1, 1]
    c2 = c2.clamp(-1.0, 1.0);

    double theta2_positive = math.asin(c2);

    // Calculate theta2_negative to cover both possible solutions
    double theta2_negative = math.pi - theta2_positive;

    double k1 = armLink1Length + armLink2Length * math.cos(theta2_positive);
    double k2 = armLink2Length * math.sin(theta2_positive);

    double theta3_positive = math.atan2(y - k2, x - k1);

    // fuck it

    return [-math.pi / 8, 0.0, math.pi / 2];
  }
}
