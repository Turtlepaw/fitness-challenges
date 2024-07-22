import 'dart:convert';
import 'dart:ffi';

import 'package:fitness_challenges/manager.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/utils/data.dart';
import 'package:fitness_challenges/utils/bingo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

class CreateDialog extends StatefulWidget {
  final PocketBase pb;

  const CreateDialog({super.key, required this.pb});

  @override
  _CreateDialogState createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog> {
  var loading = false;
  final form = FormGroup({
    type: FormControl<int>(validators: [Validators.required]),
    title: FormControl<String>(validators: [Validators.required]),
    date: FormControl<DateTime>(validators: [Validators.required]),
    autoEnd: FormControl<bool>(value: false),
    difficulty: FormControl<int>(
      value: 2,
    )
  });

  void _handleCreate() async {
    setState(() {
      loading = true;
    });
    bool autoEndValue = form.control(autoEnd).value;
    try {
      var challenge = BingoDataManager(usersBingoData: [
        UserBingoData(
          userId: widget.pb.authStore.model.id,
          activities:
            Bingo().generateBingoActivities(
              DifficultyExtension.of(form.control(difficulty).value)
            ),
        ),
      ]);

      await widget.pb.collection("challenges").create(
          body: {
            "name": form.control(title).value,
            "type": form.control(type).value,
            "users": [widget.pb.authStore.model.id],
            "endDate": autoEndValue == true ? "auto" :
            form.control(date).value.toString(),
            "difficulty": form.control(difficulty).value,
            "host": widget.pb.authStore.model.id,
            "winner": null,
            "ended": false,
            "data": jsonEncode(challenge.toJson())
          }
      );
      if(mounted){
        Provider.of<ChallengeProvider>(context, listen: false).reloadChallenges();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge created'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch(error){
      if (kDebugMode) {
        print(error);
      }

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create challenge'),
          ),
        );
      }
      setState(() {
        loading = false;
      });
    }
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
                  ReactiveFormConsumer(
                    builder: (context, form, widget) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: loading
                            ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeCap: StrokeCap.round,
                              strokeWidth: 3.0,),
                          ),
                        )
                            : TextButton(
                            onPressed: form.valid ? _handleCreate : null,
                            child: const Text("Create")),
                      );
                    },
                  )
                ],

                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: const Text("Create Challenge"),
              ),
              body: CreateWidget(),
            )));
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Challenge",
                    style: theme.typography.englishLike.labelLarge,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...challenges.asMap().entries.map((entry) {
                        final c = entry.value;
                        final index = entry.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: FilterChip(
                            avatar:
                            form
                                .control(type)
                                .value == index ? null : Icon(c.icon),
                            label: Text(c.name),
                            onSelected: index == 0 ? (value) {
                              form
                                  .control(type)
                                  .value = index;
                            } : null,
                            selected: form
                                .control(type)
                                .value == index,
                          ),
                        );
                      }),
                    ],
                  )
                ],
              )));
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(
                      width: 10,
                    ),
                    FilterChip(
                        selected: form
                            .control(autoEnd)
                            .value,
                        onSelected: (value) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...Difficulty.values.map((l) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: FilterChip(
                            label: Text(_getDifficultyLabel(l.index)),
                            onSelected: (value) {
                              form
                                  .control(difficulty)
                                  .value = l.index;
                            },
                            selected: form
                                .control(difficulty)
                                .value == l.index,
                          ),
                        );
                      }),
                    ],
                  )
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
