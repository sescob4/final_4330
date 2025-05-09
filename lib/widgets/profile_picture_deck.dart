import 'package:flutter/material.dart';

class PlayerProfileSimple extends StatelessWidget {
  final int roleNumber;
  final bool isCurrentTurn;

  const PlayerProfileSimple({
    required this.roleNumber,
    required this.isCurrentTurn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrentTurn ? Colors.amber : Colors.white54,
          width: 2,
        ),
        image: DecorationImage(
          image: AssetImage('assets/role${roleNumber}_profile.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
