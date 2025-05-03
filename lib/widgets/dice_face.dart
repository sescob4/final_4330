import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class DiceFace extends StatelessWidget {
  final int value;
  const DiceFace({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      
      padding: const EdgeInsets.all(0),       // ← optional padding so the art isn’t jammed to the edges
      child: SvgPicture.asset(
        'assets/face$value.svg',
        fit: BoxFit.cover,
      ),
    );
  }
}