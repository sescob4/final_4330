import 'package:flutter/material.dart';

class ImageButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double size;
  final double borderRadius;
  final double scaleFactor; // New parameter for scaling
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 600,
    this.borderRadius = 16,
    this.scaleFactor = 0.9, // Default scale factor for shrinking
    this.textStyle,
  });

  @override
  _ImageButtonState createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  double _scale = 1.0; // Default scale value

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = widget.scaleFactor; // Shrink based on the scaleFactor
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // Reset scale back to normal
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0; // Reset scale in case the tap is canceled
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale, // Apply the scaling transformation here
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Use the same background image always
              Image.asset(
                "assets/frame.png",
                width: widget.size,
                fit: BoxFit.cover,
              ),
              Container(
                width: widget.size,
                color: Colors.black.withOpacity(0.3), // optional overlay
              ),
              Text(
                widget.label,
                style: widget.textStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
