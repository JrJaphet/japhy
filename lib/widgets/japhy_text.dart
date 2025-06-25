import 'package:flutter/material.dart';

class JaphyText extends StatelessWidget {
  const JaphyText({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF0D47A1), Colors.white, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Text(
          'Japhy',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(3, 3),
                blurRadius: 6,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
