import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CreateModal extends ModalRoute<void> {
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
  Widget buildPage(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,) {
    return const Material(
      type: MaterialType.transparency,
      child: CreateWidget(),
    );
  }

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,) {
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

class CreateDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
        child: Scaffold(
            appBar: AppBar(
              // TRY THIS: Try changing the color here to a specific color (to
              // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
              // change color while the other colors stay the same.
              //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              leading: GestureDetector(
                child: const Icon(Symbols.close_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text("Create Challenge"),
            ),
            body: const CreateWidget()));
  }
}

class CreateWidget extends StatefulWidget {
  const CreateWidget({super.key});

  @override
  _CreateWidgetState createState() => _CreateWidgetState();
}

class _CreateWidgetState extends State<CreateWidget> {
  Challenge? challengeSelected;
  TextEditingController titleController = TextEditingController();
  DateTimeRange? dateRange;
  bool endWhenComplete = false;
  int difficulty = 2;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildChallengeSelector(theme),
          _buildTextFields(theme),
          _buildDatePickers(theme),
          _buildDifficultyLevels(theme)
        ],
      ),
    );
  }

  Widget buildChallengeSelector(ThemeData theme) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ConstraintsTransformBox(
            constraintsTransform: (constraints) =>
                BoxConstraints(
                  maxWidth: constraints.maxWidth > 450 ? 400 : constraints
                      .maxWidth,
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Text(
                    "Challenge",
                    style: theme.typography.englishLike.labelLarge,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.elliptical(14, 12)),
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: 80,
                        autoPlay: challengeSelected == null,
                        // onPageChanged: (index, reason) {
                        //   setState(() {
                        //     _current = index; // Update selected index
                        //   });
                        // },
                      ),
                      items: challenges.map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            return GestureDetector(
                              // Add GestureDetector for click
                              onTap: () {
                                setState(() {
                                  challengeSelected = i;
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
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AnimatedCrossFade(
                                            firstChild: Icon(i.icon, size: 35),
                                            secondChild: const Icon(
                                                Symbols.check_rounded,
                                                size: 35),
                                            crossFadeState: challengeSelected == i
                                                ? CrossFadeState.showSecond
                                                : CrossFadeState.showFirst,
                                            duration: const Duration(
                                                milliseconds:
                                                100), // Adjust duration as needed
                                          ),
                                          const SizedBox(width: 15),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment
                                                .start,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                i.name,
                                                style: theme
                                                    .typography.englishLike
                                                    .titleLarge,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                i.description,
                                                style: theme
                                                    .typography.englishLike
                                                    .labelMedium,
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
                ],
              )
            ),
          );
        });
  }

  Widget _buildTextFields(ThemeData theme) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ConstraintsTransformBox(
              constraintsTransform: (constraints) =>
                  BoxConstraints(
                    maxWidth:
                    constraints.maxWidth > 450 ? 400 : constraints.maxWidth,
                  ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Text(
                      "Details",
                      style: theme.typography.englishLike.labelLarge,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Title',
                        icon: Icon(Symbols.description_rounded),
                      ),
                      controller: titleController,
                    )
                  ],
                ),
              ));
        });
  }

  Widget _buildDatePickers(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
          child: Column(
            children: [
              Text(
                "Start & End Date",
                style: theme.typography.englishLike.labelLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(
                      onPressed: () {
                        (endWhenComplete
                            ? showDatePicker(
                            context: context,
                            firstDate:
                            DateTime.now().add(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 2)))
                            : showDateRangePicker(
                          context: context,
                          firstDate:
                          DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        ))
                            .then((value) {
                          setState(() {
                            if (value is DateTimeRange) {
                              dateRange = value;
                            } else if (value is DateTime) {
                              dateRange =
                                  DateTimeRange(start: value, end: value);
                            }
                          });
                        });
                      },
                      label: Text(
                        dateRange == null
                            ? "Set ${endWhenComplete == false
                            ? "Dates"
                            : "Start"}"
                            : _formatRange(),
                      )),
                  SizedBox(
                    width: 10,
                  ),
                  FilterChip(
                      selected: endWhenComplete,
                      onSelected: (value) {
                        setState(() {
                          endWhenComplete = value;
                        });
                      },
                      label: const Text(
                        "End when complete",
                      ))
                ],
              ),
            ],
          )),
    );
  }

  Widget _buildDifficultyLevels(ThemeData theme) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Difficulty",
                  style: theme.typography.englishLike.labelLarge,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...[1, 2, 3].map((l) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: FilterChip(
                          label: Text(_getDifficultyLabel(l)),
                          onSelected: (value) {
                            setState(() {
                              difficulty = l;
                            });
                          },
                          selected: difficulty == l,
                        ),
                      );
                    }),
                  ],
                )
              ],
            )
        )
    );
  }

  String _formatRange() {
    if (dateRange == null) return "";
    final format = new DateFormat('MMM dd');

    if (endWhenComplete) {
      return "Starts ${format.format(dateRange!.start)}";
    } else {
      return "${format.format(dateRange!.start)} – ${format.format(
          dateRange!.end)}";
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return "Easy";
      case 2:
        return "Medium";
      case 3:
        return "Hard";
      default:
        return "Unknown"; // Handle cases outside 1, 2, 3
    }
  }
}
