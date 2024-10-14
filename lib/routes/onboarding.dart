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
        appBar: AppBar(
          title: const Text('Introduction'),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const Icon(
                  Symbols.rocket_launch_rounded,
                  size: 70,
                ),
                const SizedBox(height: 20),
                // Add some space between the icon and the text
                Text(
                  "Your fitness journey starts here.",
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                  softWrap: true, // Allows the text to wrap
                  overflow: TextOverflow
                      .visible, // Prevent overflow, and add ellipsis if text is too long
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(width: 1.1, color: theme.colorScheme.surfaceContainerHighest)),
                  color: theme.colorScheme.surfaceContainer,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.heart_check_rounded, size: 50),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Works with Health Connect",
                                style: theme.textTheme.headlineSmall,
                                overflow: TextOverflow
                                    .visible, // Optionally, handle text overflow
                              ),
                              Text(
                                "Play challenges, with any fitness tracker.",
                                style: theme.textTheme.bodyLarge,
                                overflow: TextOverflow
                                    .visible, // Optionally, handle text overflow
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Card(
                //   color: theme.colorScheme.surfaceContainer,
                //   margin:
                //       const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //         vertical: 15, horizontal: 20),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Icon(Symbols.globe_rounded, size: 50),
                //         const SizedBox(width: 15),
                //         Expanded(
                //           child: Column(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               MarkdownBody(
                //                 data:
                //                     "Completely [open-source](https://github.com/Turtlepaw/fitness-challenges)",
                //                 styleSheet: MarkdownStyleSheet(
                //                     p: theme.textTheme.headlineSmall),
                //                 onTapLink: (a, b, c) {
                //                   if (b != null) launchUrl(Uri.parse(b));
                //                 },
                //               ),
                //               Text(
                //                 "Edit any part of our app on Github.",
                //                 style: theme.textTheme.bodyLarge,
                //                 overflow: TextOverflow
                //                     .visible, // Optionally, handle text overflow
                //               ),
                //             ],
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(
                  height: 30,
                ),
                CarouselSlider(
                  options: CarouselOptions(
                      height: 250.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3)),
                  items: [
                    const Pair(Symbols.steps_rounded,
                        "Play step challenges. Together."),
                    const Pair(Symbols.deployed_code_history_rounded,
                        "Support a developing [open-source](https://github.com/Turtlepaw/fitness-challenges) app."),
                    const Pair(Symbols.lock_rounded,
                        "Private, secure, and transparent."),
                  ].map((i) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                            alignment: Alignment.centerLeft,
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(horizontal: 8.0),
                            padding: EdgeInsets.symmetric(
                                horizontal: 35, vertical: 30),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                width: 1.1, color: theme.colorScheme.surfaceContainerHighest
                            )),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  i.key,
                                  size: 80,
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                MarkdownBody(
                                  data: i.value,
                                  styleSheet: MarkdownStyleSheet(
                                      p: theme.textTheme.headlineMedium),
                                  onTapLink: (a, b, c) {
                                    if (b != null) launchUrl(Uri.parse(b));
                                  },
                                )
                              ],
                            ));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            Positioned(
              bottom: 16, // Adjust as needed
              right: 16, // Adjust as needed
              child: FilledButton(
                onPressed: () {
                  context.push("/login");
                },
                child: Text('Get Started'),
              ),
            ),
          ],
        ));
  }
}
