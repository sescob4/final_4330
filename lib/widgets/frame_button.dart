import 'package:flutter/material.dart';

class ImageButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double size;
  final double borderRadius;
  final double scaleFactor;
  final String crownImagePath;
  final TextStyle? textStyle;
  final double fontSize;
  final double fontScale;

  const ImageButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 600,
    this.borderRadius = 16,
    this.scaleFactor = 0.9,
    required this.crownImagePath,
    this.textStyle,
    this.fontSize = 28,
    this.fontScale = 0.5, // Controls relative font sizing
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            final buttonSize = availableHeight < availableWidth
                ? availableHeight
                : availableWidth;

            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    "assets/frame2.png",
                    width: buttonSize,
                    height: buttonSize,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(
                    width: buttonSize,
                    height: buttonSize,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          widget.crownImagePath,
                          height: buttonSize * 0.4,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: buttonSize * 0.02),
                        Stack(
                          children: [
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: (widget.textStyle ??
                                      TextStyle(
                                        fontSize:
                                            widget.fontSize * widget.fontScale,
                                        fontWeight: FontWeight.bold,
                                      ))
                                  .copyWith(
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 4 * widget.fontScale
                                  ..color = const Color(0xFFC3822C),
                              ),
                            ),
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: widget.textStyle ??
                                  TextStyle(
                                    color: const Color(0xFF5E2D12),
                                    fontSize: widget.fontSize * widget.fontScale,
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
            );
          },
        ),
      ),
    );
  }
}
