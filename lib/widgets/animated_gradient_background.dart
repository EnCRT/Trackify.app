import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // We use Math.sin and Map it to create a shifting effect
        final offset = sin(_controller.value * 2 * pi);

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // Target colors: #C6E9F7 #CBF7DD #F0E8AD 155deg
                    colors: const [
                      Color.fromARGB(255, 224, 221, 255),
                      Color.fromARGB(255, 234, 255, 232),
                      Color.fromARGB(255, 255, 235, 235),
                      Color.fromARGB(255, 238, 239, 255),
                      Color.fromARGB(255, 230, 255, 253),
                      Color.fromARGB(255, 226, 208, 255),
                    ],
                    // 155 degrees is roughly Alignment.topLeft to Alignment.bottomRight shifted
                    begin: Alignment(sin(offset), -cos(offset)),
                    end: Alignment(-sin(offset), cos(offset)),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
