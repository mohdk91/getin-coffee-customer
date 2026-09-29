import 'package:flutter/material.dart';

class GetinLogoMark extends StatelessWidget {
  final double size;

  const GetinLogoMark({
    super.key,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/getin_logo_mark.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
