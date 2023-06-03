import 'package:flutter/material.dart';

class BlackholeButton extends StatefulWidget {
  final Function onAcceptMethod;

  BlackholeButton({required this.onAcceptMethod});

  @override
  State<StatefulWidget> createState() =>
      // ignore: no_logic_in_create_state
      BlackholeButtonState(onAcceptMethod: onAcceptMethod);
}

class BlackholeButtonState extends State<BlackholeButton>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final Function onAcceptMethod;

  BlackholeButtonState({required this.onAcceptMethod});

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.25).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.forward();
  }

  void _reverseAnimation() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
        },
        backgroundColor: Colors.black,
        shape: CircleBorder(),
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              isHovered = true;
              _startAnimation();
            });
          },
          onExit: (_) {
            setState(() {
              isHovered = false;
              _reverseAnimation();
            });
          },
          child: DragTarget(
            onAccept: (data) {
              onAcceptMethod(data, context);
            },
            builder: (_, __, child) {
              return Center(
                child: Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        painter: AccretionRingPainter(
                          innerRadius: 25,
                          outerRadius: 35,
                          color: Colors.amber,
                          opacity: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AccretionRingPainter extends CustomPainter {
  final double innerRadius;
  final double outerRadius;
  final Color color;
  final double opacity;

  AccretionRingPainter({
    required this.innerRadius,
    required this.outerRadius,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // create a ring fading from amber to transparent with inner radius 25 and outer radius 35
    final Gradient gradient = RadialGradient(
      colors: [
        color.withOpacity(opacity),
        color.withOpacity(0),
      ],
      stops: [0.5, 1],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: outerRadius,
        ),
      );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      outerRadius,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      innerRadius,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(AccretionRingPainter oldDelegate) {
    return false;
  }
}
