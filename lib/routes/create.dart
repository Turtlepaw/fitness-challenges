import 'dart:convert';

import 'package:fitness_challenges/components/dialog/confirmDialog.dart';
import 'package:fitness_challenges/components/error.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:fitness_challenges/utils/bingo/manager.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pair/pair.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../components/common.dart';
import '../constants.dart';
import '../utils/health.dart';

class CreateDialog extends StatefulWidget {
  final PocketBase pb;

  const CreateDialog({super.key, required this.pb});

  @override
  _CreateDialogState createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog> {
  bool _isDialogLoading = true;
  late bool _isHealthAvailable;
  bool _isCreating = false;

  // Form definition
  final form = FormGroup({
    type: FormControl<int>(validators: [Validators.required], value: 1),
    title: FormControl<String>(validators: [Validators.required]),
    date: FormControl<DateTime>(validators: []),
    autoEnd: FormControl<bool>(value: false),
    difficulty: FormControl<int>(value: 1)
  });

  @override
  void initState() {
    super.initState();
    _checkHealthPlugin();
  }

  Future<void> _checkHealthPlugin() async {
    setState(() {
      _isDialogLoading = true;
    });

    final health = Provider.of<HealthManager>(context, listen: false);
    final state = health.isConnected;
    setState(() {
      _isHealthAvailable = state;
      _isDialogLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
        formGroup: form,
        child: Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              leading: Tooltip(
                message: "Exit",
                child: IconButton(
                  icon: const Icon(Symbols.close_rounded),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => ConfirmDialog(
                            icon: Symbols.delete_rounded,
                            title: "Discard challenge?",
                            description:
                                "Are you sure you want to discard what you've entered.",
                            isDestructive: true,
                            onConfirm: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            }));
                  },
                ),
              ),
              // actions: <Widget>[
              //   ReactiveFormConsumer(
              //     builder: (context, form, widget) => _isCreating
              //         ? const Padding(
              //             padding: EdgeInsets.only(right: 25),
              //             child: SizedBox(
              //               width: 15,
              //               height: 15,
              //               child: CircularProgressIndicator(
              //                 strokeCap: StrokeCap.round,
              //                 strokeWidth: 3.2,
              //               ),
              //             ))
              //         : TextButton(
              //             onPressed: (form.valid && _isHealthAvailable)
              //                 ? _handleCreate
              //                 : null,
              //             child: const Text("Create"),
              //           ),
              //   )
              // ],
              title: const Text("Start a challenge"),
            ),
            body: _isDialogLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(strokeCap: StrokeCap.round),
                  )
                : (_isHealthAvailable
                    ? CreateWidget(
                        onCreate: (_isHealthAvailable) ? _handleCreate : null,
                        isCreating: _isCreating,
                      )
                    : ErrorMessage(
                        title: errorMessages[ErrorMessages.noHealthConnected]!,
                        action: (theme) => FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go("/settings");
                          },
                          child: Text("Go to settings"),
                        ),
                      )),
          ),
        ));
  }

  void _handleCreate() async {
    setState(() {
      _isCreating = true;
    });

    bool autoEndValue = form.control(autoEnd).value;
    try {
      final challenge = switch (form.control(type).value) {
        0 => BingoDataManager([
            UserBingoData(
              userId: widget.pb.authStore.model.id,
              activities: Bingo().generateBingoActivities(
                  DifficultyExtension.of(form.control(difficulty).value)),
            ),
          ]).toJson(),
        1 => StepsDataManager([
            UserStepsData(userId: widget.pb.authStore.model.id, entries: [])
          ]).toJson(),
        _ => throw UnimplementedError(),
      };

      await widget.pb.collection("challenges").create(body: {
        "name": form.control(title).value,
        "type": form.control(type).value,
        "users": [widget.pb.authStore.model.id],
        "endDate": autoEndValue == true
            ? null
            : pbDateFormat.format(form.control(date).value),
        "difficulty": form.control(difficulty).value,
        "host": widget.pb.authStore.model.id,
        "winner": null,
        "ended": false,
        "data": jsonEncode(challenge),
        "autoEnd": autoEndValue
      });

      if (mounted) {
        await Provider.of<ChallengeProvider>(context, listen: false)
            .reloadChallenges(context);

        await Provider.of<HealthManager>(context, listen: false)
            .fetchHealthData(context: context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge created and synced'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create challenge'),
          ),
        );
      }
      setState(() {
        _isCreating = false;
      });
    }
  }
}

const type = "type";
const title = "title";
const date = "dates";
const autoEnd = "auto_end";
const difficulty = "difficulty";

class CreateWidget extends StatefulWidget {
  const CreateWidget(
      {super.key, required this.onCreate, required this.isCreating});

  final void Function()? onCreate;
  final bool isCreating;

  @override
  CreateWidgetState createState() => CreateWidgetState();
}

enum Pages {
  challengeType,
  challengeTitle,
  challengeDate,
  challengeDifficulty,
  review
}

final pageMap = {
  Pages.challengeType: 0,
  Pages.challengeTitle: 1,
  Pages.challengeDate: 2,
  Pages.challengeDifficulty: 3,
  Pages.review: 4,
};

final difficultySupportedChallenges = [0];

class CreateWidgetState extends State<CreateWidget> {
  Pages currentPage = pageMap.keys.first; // Track the current page

  // Move to the next page
  void nextPage() {
    setState(() {
      currentPage = Pages.values[(Pages.values.indexOf(currentPage) + 1)
          .clamp(0, Pages.values.length - 1)];
    });
  }

  void jumpTo(int page) {
    setState(() {
      currentPage = Pages.values[page];
    });
  }

  // Move to the previous page
  void previousPage() {
    var page = (Pages.values.indexOf(currentPage) - 1)
        .clamp(0, Pages.values.length - 1);

    final formGroup = ReactiveForm.of(context) as FormGroup;
    if (page == pageMap[Pages.challengeDifficulty] &&
        !difficultySupportedChallenges
            .contains(formGroup.control(type).value)) {
      page -= 1;
    }

    setState(() {
      currentPage = Pages.values[page];
    });
  }

  Pair<int, int> getAmountOfPages() {
    var pages = pageMap.entries.length - 1;
    var activePage = pageMap.values.toList().indexOf(pageMap[currentPage]!);

    final formGroup = ReactiveForm.of(context) as FormGroup;
    print(
        !difficultySupportedChallenges.contains(formGroup.control(type).value));
    if (!difficultySupportedChallenges
        .contains(formGroup.control(type).value)) {
      pages -= 1;
      if (activePage >= pageMap[Pages.challengeDifficulty]!) activePage -= 1;
    }

    return Pair(pages, activePage);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildPageContent(theme),
              ),
            ),
            const SizedBox(height: 20),
            _buildNavigationButtons(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(ThemeData theme) {
    switch (currentPage) {
      case Pages.challengeType:
        return buildChallengeSelector(theme);
      case Pages.challengeTitle:
        return _buildTextFields(theme);
      case Pages.challengeDate:
        return _buildDatePickers(context, theme);
      case Pages.challengeDifficulty:
        return _buildDifficultyLevels(theme);
      case Pages.review:
        return buildReviewAndComplete(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        ElevatedButton.icon(
          onPressed: currentPage == Pages.challengeType ? null : previousPage,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        // Next Button
        // ElevatedButton.icon(
        //   onPressed: [Pages.challengeDate, Pages.challengeType].contains(currentPage) ? null : nextPage,
        //   icon: const Icon(Icons.arrow_forward),
        //   label: const Text('Next'),
        // ),
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              "${getAmountOfPages().value}/${getAmountOfPages().key}",
              style: theme.textTheme.bodyLarge,
            ))
      ],
    );
  }

  Widget buildChallengeSelector(ThemeData theme) {
    return ReactiveFormConsumer(builder: (context, form, widget) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.animated_images_rounded,
                size: 50,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Select a challenge to play",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(
                height: 20,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, // Space between chips horizontally
                runSpacing: 1, // Space between chips vertically
                children: [
                  ...challenges.asMap().entries.map((entry) {
                    final c = entry.value;
                    final index = entry.key;
                    if(index == 0) return const SizedBox();
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          width: 1.1,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias, // Clip the ripple
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        leading: Icon(c.icon),
                        title: Row(
                          children: [
                            Text(c.name),
                            if (index == 0)
                              const NewTag()
                          ],
                        ),
                        onTap: index == 1 || index == 0
                            ? () {
                                form.control(type).value = index;

                                nextPage();
                              }
                            : null,
                        subtitle: Text(c.description),
                        trailing: index == 1 || index == 0
                            ? const Icon(Symbols.arrow_forward_rounded)
                            : const Icon(Symbols.close_rounded),
                      ),
                    );
                  }),
                ],
              ),
              // const SizedBox(
              //   height: 10,
              // ),
              // Center(
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(
              //           Symbols.info_rounded,
              //         color: theme.colorScheme.primary,
              //         size: 20,
              //       ),
              //       const SizedBox(width: 6),
              //       Text(
              //           "We're still building some challenges.",
              //         style: theme.typography.englishLike.labelMedium?.copyWith(
              //             color: theme.colorScheme.onSurface
              //         ),
              //       )
              //     ],
              //   ),
              // )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTextFields(ThemeData theme) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const Icon(
              Symbols.edit_square_rounded,
              size: 40,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Set a title for your challenge",
              style: theme.textTheme.titleLarge,
            ),
            Text(
              "This will be visible to everyone.",
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.80)),
            ),
            const SizedBox(
              height: 30,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 300,
                    child: ReactiveTextField(
                      formControlName: title,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Title',
                      ),
                    )),
                const SizedBox(
                  height: 10,
                ),
                ReactiveFormConsumer(builder: (context, form, widget) {
                  return FilledButton.icon(
                    label: const Text("Looks good"),
                    onPressed: form.control(title).valid
                        ? () {
                            nextPage();
                          }
                        : null,
                    icon: Icon(
                      Symbols.arrow_forward_rounded,
                      color: form.control(title).valid
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(.38),
                    ),
                  );
                })
              ],
            )
          ],
        ),
      );
    });
  }

  int? dateType = 0;

  TextStyle? asDisabled(TextStyle? textTheme, ThemeData theme) {
    return textTheme?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.38),
    );
  }

  bool isDateValid(FormGroup form) {
    if (form.control(autoEnd).value == false &&
        form.control(date).value == null)
      return false;
    else
      return true;
  }

  Widget _buildDatePickers(BuildContext context, ThemeData theme) {
    final autoEndChallengeTypes = [0];

    return ReactiveFormConsumer(builder: (context, form, widget) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Symbols.edit_calendar_rounded,
                size: 40,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Set the end date for your challenge",
                style: theme.textTheme.titleLarge,
              ),
              Text(
                "After the challenge has ended, it will be deleted a week after.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.80)),
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10, // Space between chips horizontally
                      runSpacing: 0,
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              width: 1.1,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias, // Clip the ripple
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            leading: Icon(Icons.auto_awesome_rounded,
                                color: autoEndChallengeTypes
                                        .contains(form.control(type).value)
                                    ? null
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.38)),
                            title: Text("Automatically end",
                                style: autoEndChallengeTypes
                                        .contains(form.control(type).value)
                                    ? null
                                    : asDisabled(
                                        theme.textTheme.bodyLarge, theme)),
                            onTap: autoEndChallengeTypes
                                    .contains(form.control(type).value)
                                ? () {
                                    setState(() {
                                      dateType = 1;
                                      form.control(autoEnd).value = true;
                                    });
                                  }
                                : null,
                            subtitle: Text(
                                autoEndChallengeTypes
                                        .contains(form.control(type).value)
                                    ? "End the challenge when there's a winner"
                                    : "Not supported for this challenge",
                                style: autoEndChallengeTypes
                                        .contains(form.control(type).value)
                                    ? null
                                    : asDisabled(
                                        theme.textTheme.bodyMedium, theme)),
                            trailing: Radio(
                                value: 1,
                                groupValue: dateType,
                                onChanged: autoEndChallengeTypes
                                        .contains(form.control(type).value)
                                    ? (v) {}
                                    : null),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: dateType == 0
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                    bottom: Radius.circular(8))
                                : BorderRadius.circular(20),
                            side: BorderSide(
                              width: 1.1,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias, // Clip the ripple
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            leading: const Icon(Symbols.calendar_clock_rounded),
                            title: const Text("Custom end date"),
                            onTap: () {
                              setState(() {
                                dateType = 0;
                                form.control(autoEnd).value = false;
                              });
                            },
                            subtitle: const Text(
                                "Set a custom date for the challenge to end"),
                            trailing: Radio(
                                value: 0,
                                groupValue: dateType,
                                onChanged: (v) {}),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          // Animation duration
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.05),
                                  // Slight upward start
                                  end: Offset.zero, // Final position
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: dateType == 0
                              ? Card(
                                  key: const ValueKey('custom_end_card'),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20),
                                        top: Radius.circular(8)),
                                    side: BorderSide(
                                      width: 1.1,
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  // Clip the ripple
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                    title: Text(form.control(date).value == null
                                        ? "No end date selected"
                                        : _formatRange(form)),
                                    onTap: () {
                                      showDatePicker(
                                              context: context,
                                              firstDate: DateTime.now()
                                                  .add(const Duration(days: 2)),
                                              lastDate: DateTime.now().add(
                                                  const Duration(
                                                      days: 365 * 2)))
                                          .then((value) {
                                        form.control(autoEnd).value = false;
                                        form.control(date).value = value;
                                      });
                                    },
                                    subtitle: const Text(
                                        "Date for the challenge to end, tap to change."),
                                  ),
                                )
                              : const SizedBox
                                  .shrink(), // Empty widget when not visible
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ReactiveFormConsumer(builder: (context, form, widget) {
                      return FilledButton.icon(
                        label: const Text("Looks good"),
                        onPressed: dateType != null && isDateValid(form)
                            ? () {
                                if (difficultySupportedChallenges
                                    .contains(form.control(type).value)) {
                                  nextPage();
                                } else {
                                  jumpTo(4);
                                }
                              }
                            : null,
                        icon: Icon(
                          Symbols.arrow_forward_rounded,
                          color: dateType != null && isDateValid(form)
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withOpacity(.38),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDifficultyLevels(ThemeData theme) {
    return ReactiveFormConsumer(builder: (context, form, widget) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.elevation_rounded,
                size: 40,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Set the challenge's difficulty",
                style: theme.textTheme.titleLarge,
              ),
              Text(
                "Adjust how hard the challenge will be for everyone",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.80)),
              ),
              const SizedBox(
                height: 30,
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10, // Space between chips horizontally
                    runSpacing: 10, //
                    children: [
                      ...Difficulty.values.map((l) {
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              width: 1.1,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias, // Clip the ripple
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            //leading: Icon(c.icon),
                            selected: form.control(difficulty).value == l.index,
                            title: Text(_getDifficultyLabel(l.index)),
                            onTap: () {
                              form.control(difficulty).value = l.index;
                            },
                            trailing: Radio(
                                value: l.index,
                                groupValue: form.control(difficulty).value,
                                onChanged: (v) {}),
                          ),
                        );
                        return FilterChip(
                          label: Text(_getDifficultyLabel(l.index)),
                          onSelected: form.control(type).value == 1
                              ? null
                              : (value) {
                                  form.control(difficulty).value = l.index;
                                },
                          selected: form.control(difficulty).value == l.index,
                        );
                      }),
                      ReactiveFormConsumer(builder: (context, form, widget) {
                        return FilledButton.icon(
                          label: const Text("Looks good"),
                          onPressed: dateType != null && isDateValid(form)
                              ? () {
                                  nextPage();
                                }
                              : null,
                          icon: Icon(
                            Symbols.arrow_forward_rounded,
                            color: dateType != null && isDateValid(form)
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(.38),
                          ),
                        );
                      }),
                    ],
                  ))
            ],
          )));
    });
  }

  Widget buildReviewAndComplete(ThemeData theme) {
    return ReactiveFormConsumer(builder: (context, form, _) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.data_check_rounded,
                size: 40,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Review and create",
                style: theme.textTheme.titleLarge,
              ),
              Text(
                "Quickly check what you've entered is correct.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.80)),
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10, // Space between chips horizontally
                    runSpacing: 10, //
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            width: 1.1,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias, // Clip the ripple
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 30),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                listItem(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Symbols.subject_rounded,
                                        size: 15,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                          "Title: \"${form.control(title).value}\"",
                                          style: theme.textTheme.bodyLarge),
                                    ],
                                  ),
                                ),
                                listItem(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        challenges
                                            .elementAt(form.control(type).value)
                                            .icon,
                                        size: 15,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                          "Challenge: ${challenges.elementAt(form.control(type).value).name}",
                                          style: theme.textTheme.bodyLarge)
                                    ],
                                  ),
                                ),
                                if (difficultySupportedChallenges
                                    .contains(form.control(type).value))
                                  listItem(
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Symbols.elevation_rounded,
                                          size: 15,
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                            "Difficulty: ${_getDifficultyLabel(form.control(difficulty).value)}",
                                            style: theme.textTheme.bodyLarge),
                                      ],
                                    ),
                                  ),
                                listItem(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Symbols.calendar_clock_rounded,
                                        size: 15,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                          form.control(autoEnd).value
                                              ? "Automatically ends"
                                              : _formatRange(form),
                                          style: theme.textTheme.bodyLarge),
                                    ],
                                  ),
                                ),
                              ]),
                        ),
                      ),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        leading: Icon(Symbols.lightbulb_2_rounded,
                            color: theme.colorScheme.primary),
                        title: const Text(
                            "You can invite people to join after you finish creating the challenge."),
                      ),
                      // ListTile(
                      //   contentPadding: const EdgeInsets.symmetric(
                      //       horizontal: 20),
                      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      //   leading: const Icon(Symbols.share_rounded),
                      //   title: const Text("Create a link to invite people now"),
                      //   onTap: () {
                      //     setState(() {
                      //       dateType = 0;
                      //       form.control(autoEnd).value = false;
                      //     });
                      //   },
                      //   trailing: Checkbox(value: true, onChanged: (v){}),
                      // ),
                      ReactiveFormConsumer(builder: (context, form, _) {
                        return FilledButton.icon(
                          label: widget.isCreating
                              ? SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 2.5,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Text("Create"),
                          onPressed: dateType != null &&
                                  isDateValid(form) &&
                                  form.valid
                              ? widget.onCreate
                              : null,
                          icon: widget.isCreating
                              ? null
                              : Icon(
                                  Symbols.check_rounded,
                                  color: dateType != null && isDateValid(form)
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface
                                          .withOpacity(.38),
                                ),
                        );
                      }),
                      if (form.errors.isNotEmpty) Text(form.errors.toString())
                    ],
                  ))
            ],
          )));
    });
  }

  Widget listItem(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100), color: Colors.grey),
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 8),
          ),
          child
        ],
      ),
    );
  }

  String _formatRange(FormGroup form) {
    var dateRange = form.control(date).value;
    if (dateRange == null) return "";
    final format = DateFormat('MMM dd');

    return "Ends ${format.format(dateRange)}";
    // if (form.control(autoEnd).value) {
    //   return "Starts ${format.format(dateRange!.start)}";
    // } else {
    //   return "${format.format(dateRange!.start)} – ${format.format(dateRange!.end)}";
    // }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 0:
        return "Easy";
      case 1:
        return "Medium";
      case 2:
        return "Hard";
      default:
        return "Unknown"; // Handle cases outside 1, 2, 3
    }
  }
}
