import 'package:flutter/material.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/emptybar.png', // Ensure this path is correct
              fit: BoxFit.cover,
            ),
          ),
          // Role selection sprites
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select a Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5B45D),
                  ),
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 0,
                  children: List.generate(4, (index) {
                    return GestureDetector(
                      onTap: () {
                        // Handle role selection
                        print('Role $index selected');
                      },
                      child: Image.asset(
                        'assets/galexport.png', // Replace with your sprite image paths
                        height: 200,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
