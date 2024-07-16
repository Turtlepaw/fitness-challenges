import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TutorialOverlay extends ModalRoute<void> {
  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: 350); // Adjust duration

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    return StatefulBuilder( // Use StatefulBuilder to manage state
      builder: (context, setState) {
        Challenge? _challenge;

        return Material(
          type: MaterialType.transparency,
          child: _buildOverlayContent(context, setState, _challenge),
        );
      },
    );
  }

  Widget _buildOverlayContent(
      BuildContext context,
      StateSetter setState,
      Challenge? _challenge
      ) {
    var theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 25,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 35,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.elliptical(14, 12)),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 80,
                      autoPlay: true,
                      // onPageChanged: (index, reason) {
                      //   setState(() {
                      //     _current = index; // Update selected index
                      //   });
                      // },
                    ),
                    items: challenges.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return GestureDetector( // Add GestureDetector for click
                            onTap: () {
                              print("now ${i.name}");
                              setState(() {
                                _challenge = i;
                              });
                            },
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _challenge == i ?
                                          Symbols.check_rounded : i.icon,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 15),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              i.name,
                                              style: theme.typography.englishLike.titleLarge,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              i.description,
                                              style: theme.typography.englishLike.labelMedium,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation with longer duration
    Animation<double> fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    // Slide animation for entering
    Animation<Offset> slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    // Slide animation for exiting (reversed and going further up)
    Animation<Offset> slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5), // Adjust -0.5 for desired upward distance
    ).animate(CurvedAnimation(
      parent: secondaryAnimation, // Use secondaryAnimation for exit
      curve: Curves.easeOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: animation.status == AnimationStatus.forward
            ? slideInAnimation
            : slideOutAnimation,
        child: child,
      ),
    );
  }
}
