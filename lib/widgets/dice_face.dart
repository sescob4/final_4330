import 'package:flutter/material.dart';

class DiceFace extends StatelessWidget {
  final int value;
  const DiceFace({super.key, required this.value});

  Widget dot({bool visible = true}) => Opacity(
        opacity: visible ? 1 : 0,
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: CircleAvatar(radius: 6, backgroundColor: Colors.black),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // 3x3 matrix pattern
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              dot(visible: [4, 5, 6].contains(value)),
              dot(visible: value == 6),
              dot(visible: [2, 3, 4, 5, 6].contains(value)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dot(visible: value == 1 || value == 3 || value == 5),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              dot(visible: [2, 3, 4, 5, 6].contains(value)),
              dot(visible: value == 6),
              dot(visible: [4, 5, 6].contains(value)),
            ],
          ),
        ],
      ),
    );
  }
}
