import 'package:flutter/material.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Introduction'),
      ),
      body: Column(
        children: [
          CarouselView(itemExtent: 330, shrinkExtent: 200, children: [
            ...["Create step challenges"].map((data) => Container(
                  child: Column(
                    children: [Text(data)],
                  ),
                ))
          ])
        ],
      ),
    );
  }
}
