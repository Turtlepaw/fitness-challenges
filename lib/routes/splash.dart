import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() asyncFunction; // Add this line

  const SplashScreen({super.key, required this.asyncFunction}); // Modify constructor

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Fade in
    setState(() {
      _visible = true;
    });
    await Future.delayed(const Duration(seconds: 1)); // Duration for fade-in

    // Wait for additional time (optional) before starting fade-out
    await Future.delayed(const Duration(seconds: 2));

    // Fade out
    setState(() {
      _visible = false;
    });
    await Future.delayed(const Duration(seconds: 1)); // Duration for fade-out

    // Execute async function
    await widget.asyncFunction();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          child: Icon(
            Symbols.rocket_launch_rounded,
            color: theme.colorScheme.onSurface,
            size: 85,
          ), // Replace with your logo
        ),
      ),
    );
  }
}