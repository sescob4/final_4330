import 'package:flutter/material.dart';

class PlayerProfile extends StatelessWidget {
  final String name;
  final int roleNumber;
  final int lives;
  final bool isCurrentTurn;

  const PlayerProfile({
    required this.name,
    required this.roleNumber,
    required this.lives,
    required this.isCurrentTurn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              color: isCurrentTurn ? Colors.amber : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              lives,
              (_) => const Icon(
                Icons.favorite,
                size: 10,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}