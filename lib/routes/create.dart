import 'dart:convert';

import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:fitness_challenges/utils/bingo/manager.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
              leading: IconButton(
                icon: const Icon(Symbols.close_rounded),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              actions: <Widget>[
                ReactiveFormConsumer(builder: (context, form, widget) =>
                _isCreating
                    ? const Padding(
                    padding: EdgeInsets.only(right: 25),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeCap: StrokeCap.round, strokeWidth: 3.2,),
                    )
                )
                    : TextButton(
                  onPressed: (form.valid && _isHealthAvailable)
                      ? _handleCreate
                      : null,
                  child: const Text("Create"),
                ),
                )
              ],
              title: const Text("Create Challenge"),
            ),
            body: _isDialogLoading
                ? const Center(
              child: CircularProgressIndicator(strokeCap: StrokeCap.round),)
                : (
                _isHealthAvailable ? CreateWidget() : _buildHealthUnavailable(
                    context)
            ),
          ),
        ));
  }

  Widget _buildHealthUnavailable(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Symbols.error_circle_rounded,
              color: theme.colorScheme.error,
              size: 45,
            ),
            const SizedBox(height: 10),
            Text(
              "You must connect a health service before creating a challenge",
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  void _handleCreate() async {
    setState(() {
      _isCreating = true;
    });
    bool autoEndValue = form
        .control(autoEnd)
        .value;
    try {
      final challenge = switch (form
          .control(type)
          .value) {
        0 =>
            BingoDataManager([
              UserBingoData(
                userId: widget.pb.authStore.model.id,
                activities: Bingo().generateBingoActivities(
                    DifficultyExtension.of(form
                        .control(difficulty)
                        .value)),
              ),
            ]).toJson(),
        1 =>
            StepsDataManager([
              UserStepsData(userId: widget.pb.authStore.model.id, entries: [])
            ]).toJson(),
        _ => throw UnimplementedError(),
      };

      await widget.pb.collection("challenges").create(body: {
        "name": form
            .control(title)
            .value,
        "type": form
            .control(type)
            .value,
        "users": [widget.pb.authStore.model.id],
        "endDate":
        autoEndValue == true ? null : pbDateFormat.format(form
            .control(date)
            .value),
        "difficulty": form
            .control(difficulty)
            .value,
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

// class CreateWidget extends StatefulWidget {
//   const CreateWidget({super.key});
//
//   @override
//   _CreateWidgetState createState() => _CreateWidgetState();
// }

const type = "type";
const title = "title";
const date = "dates";
const autoEnd = "auto_end";
const difficulty = "difficulty";

class CreateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildChallengeSelector(theme),
            _buildTextFields(theme),
            _buildDatePickers(context, theme),
            _buildDifficultyLevels(theme),
            //FilledButton(onPressed: (){}, child: Text("Create"))
          ],
        ));
  }

  Widget buildChallengeSelector(ThemeData theme) {
    return ReactiveFormConsumer(builder: (context, form, widget) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Challenge Type",
                style: theme.typography.englishLike.labelLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, // Space between chips horizontally
                runSpacing: 10, // Space between chips vertically
                children: [
                  ...challenges
                      .asMap()
                      .entries
                      .map((entry) {
                    final c = entry.value;
                    final index = entry.key;
                    return FilterChip(
                      avatar: form
                          .control(type)
                          .value == index
                          ? null
                          : Icon(c.icon),
                      label: Text(c.name),
                      onSelected: index == 1 || index == 0
                          ? (value) {
                        form
                            .control(type)
                            .value = index;
                      }
                          : null,
                      selected: form
                          .control(type)
                          .value == index,
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
                    ReactiveTextField(
                      formControlName: title,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Title',
                        icon: Icon(Symbols.description_rounded),
                      ),
                    )
                  ],
                ),
              ));
        });
  }

  Widget _buildDatePickers(BuildContext context, ThemeData theme) {
    return ReactiveFormConsumer(builder: (context, form, widget) {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10, // Space between chips horizontally
                    runSpacing: 10,
                    children: [
                      FilterChip(
                          selected: form
                              .control(date)
                              .isNotNull,
                          onSelected: (v) {
                            showDatePicker(
                                context: context,
                                firstDate:
                                DateTime.now().add(const Duration(days: 2)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365 * 2)))
                                .then((value) {
                              form
                                  .control(autoEnd)
                                  .value = false;
                              form
                                  .control(date)
                                  .value = value;
                            });
                          },
                          label: Text(
                            form
                                .control(date)
                                .value == null
                                ? "Set End Date"
                                : _formatRange(form),
                          )),
                      FilterChip(
                          selected: form
                              .control(autoEnd)
                              .value,
                          onSelected: form
                              .control(type)
                              .value == 1
                              ? null
                              : (value) {
                            form
                                .control(autoEnd)
                                .value = value;
                            if (value) {
                              form
                                  .control(date)
                                  .value = null;
                            }
                          },
                          label: const Text(
                            "End when complete",
                          ))
                    ],
                  ),
                )
              ],
            )),
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
                  Text(
                    "Difficulty",
                    style: theme.typography.englishLike.labelLarge,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10, // Space between chips horizontally
                        runSpacing: 10, //
                        children: [
                          ...Difficulty.values.map((l) {
                            return FilterChip(
                              label: Text(_getDifficultyLabel(l.index)),
                              onSelected: form
                                  .control(type)
                                  .value == 1
                                  ? null
                                  : (value) {
                                form
                                    .control(difficulty)
                                    .value = l.index;
                              },
                              selected: form
                                  .control(difficulty)
                                  .value == l.index,
                            );
                          }),
                        ],
                      ))
                ],
              )));
    });
  }

  String _formatRange(FormGroup form) {
    var dateRange = form
        .control(date)
        .value;
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
