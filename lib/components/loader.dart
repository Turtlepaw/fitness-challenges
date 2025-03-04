import 'package:flutter/material.dart';

class LoadingBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const LoadingBox({
    Key? key,
    required this.width,
    required this.height,
    this.radius = 8,
  }) : super(key: key);

  @override
  _FadingColorAnimationState createState() => _FadingColorAnimationState();
}

class _FadingColorAnimationState extends State<LoadingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  static const duration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: duration,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensuring Theme.of(context) is accessed after initState
    var theme = Theme.of(context);
    print(
        theme.colorScheme.surfaceContainerHighest == theme.colorScheme.surface);
    _colorAnimation = ColorTween(
            begin: theme.colorScheme.surfaceContainerHighest,
            end: theme.colorScheme.surfaceContainerHigh)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
