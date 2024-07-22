import 'package:flutter/material.dart';

class LoadingBox extends StatefulWidget {
  final double width;
  final double height;

  const LoadingBox({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  _FadingColorAnimationState createState() => _FadingColorAnimationState();
}

class _FadingColorAnimationState extends State<LoadingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<Color?>? _colorAnimation; // Use a nullable type
  static const duration = Duration(seconds: 1);

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
    var theme = Theme.of(context);
    _colorAnimation = ColorTween(
      begin: theme.colorScheme.surfaceContainer,
      end: theme.colorScheme.surfaceContainerHighest,
    ).animate(_animationController);
  }

  @override
  void didUpdateWidget(LoadingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      _animationController.repeat(reverse: true); // Restart the animation on widget updates
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the animation is initialized before building the widget
    if (_colorAnimation == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _colorAnimation!,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation!.value,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
