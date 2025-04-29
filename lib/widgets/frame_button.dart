import 'package:flutter/material.dart';

class ImageButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double size;
  final double borderRadius;
  final double scaleFactor;
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 600,
    this.borderRadius = 16,
    this.scaleFactor = 0.9,
    this.textStyle,
  });

  @override
  _ImageButtonState createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = widget.scaleFactor;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void OnHover(HoverDetains details) {
    setState(() {
      _scale = widget.scaleFactor;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
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
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                "assets/frame2.png",
                width: widget.size,
                fit: BoxFit.cover,
              ),
              SizedBox(
                width: widget.size,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/crown.png', // Replace with your image
                      height: widget.size * 0.2, // Scales with button size
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Text(
                          widget.label,
                          style: (widget.textStyle ??
                                  const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ))
                              .copyWith(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 4
                              ..color =
                                  Color(0xFFC3822C), // Bright gold outline
                          ),
                        ),
                        Text(
                          widget.label,
                          style: widget.textStyle ??
                              const TextStyle(
                                color: Color(0xFF5E2D12),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
