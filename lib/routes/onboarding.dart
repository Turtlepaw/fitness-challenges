import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pair/pair.dart';
import 'package:url_launcher/url_launcher.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  _OnboardingState createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 70),
                        const Icon(
                          Symbols.rocket_launch_rounded,
                          size: 70,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Your fitness journey starts here.",
                            style: theme.textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Flexible(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                width: 1.1,
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            color: theme.colorScheme.surfaceContainer,
                            shadowColor: Colors.transparent,
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Container(
                              height: 115,
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Symbols.heart_check_rounded, size: 50),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Works with Health Connect",
                                          style: theme.textTheme.headlineSmall,
                                        ),
                                        Text(
                                          "Play challenges with any fitness tracker.",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 310.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                          ),
                          items: [
                            const Pair(Symbols.steps_rounded, "Play step challenges. Together."),
                            const Pair(Symbols.playing_cards_rounded, "Play bingo with a fitness twist."),
                            const Pair(Symbols.deployed_code_history_rounded, "Support a developing [open-source](https://github.com/Turtlepaw/fitness-challenges) app."),
                            const Pair(Symbols.lock_rounded, "Private, secure, and transparent."),
                          ].map((i) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  alignment: Alignment.centerLeft,
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      width: 1.1,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        i.key,
                                        size: 80,
                                      ),
                                      const SizedBox(height: 15),
                                      MarkdownBody(
                                        data: i.value,
                                        styleSheet: MarkdownStyleSheet(p: theme.textTheme.headlineMedium),
                                        onTapLink: (a, b, c) {
                                          if (b != null) launchUrl(Uri.parse(b));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const Spacer(), // Pushes content up and keeps button at the bottom
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 25, top: 15),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: BorderDirectional(
                  top: BorderSide(
                    color: theme.colorScheme.surfaceContainerHighest,
                    width: 1.1
                  )
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 125, // Desired width for the button
                    child: FilledButton(
                      onPressed: () {
                        context.push("/login");
                      },
                      child: const Text('Get Started'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

