import 'package:flutter/material.dart';
import 'dice_face.dart';


const int dicePerPlayer = 5;

class PlayerArea extends StatelessWidget {
  final String     name;
  final bool       isCurrent;
  final List<int>? diceValues;
  final bool       small;
  final int        lives;

  const PlayerArea({
    required this.name,
    required this.isCurrent,
    this.diceValues,
    this.small = false,
    required this.lives, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dieSize = isCurrent? 96.0 : 72.0;
    final hearts = List<Widget>.generate(
          lives,
          (_) => const Icon(Icons.favorite, size: 12, color: Colors.redAccent),);
    final diceWidgets = isCurrent
        ? (diceValues ?? []).map((v) => SizedBox(
            width: dieSize,
            height: dieSize,
            child: DiceFace(value: v),
          )).toList()
        : List.generate(dicePerPlayer, (_) => SizedBox(
            width: dieSize,
            height: dieSize,
            
          ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isCurrent ? 20 : 14,
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, children: hearts),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: diceWidgets)),
      ],
    );
  }
}