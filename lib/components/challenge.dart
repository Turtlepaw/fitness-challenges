import 'dart:math';

import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:fitness_challenges/components/challenges/codeDialog.dart';
import 'package:fitness_challenges/components/challenges/confirmDialog.dart';
import 'package:fitness_challenges/components/challenges/userDialog.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:fitness_challenges/utils/common.dart';
import 'package:fitness_challenges/utils/manager.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:overlap_stack/overlap_stack.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:relative_time/relative_time.dart';

import '../utils/challengeManager.dart';

class Challenge extends StatefulWidget {
  final RecordModel challenge;
  final PocketBase pb;

  const Challenge({super.key, required this.challenge, required this.pb});

  @override
  _ChallengeState createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge> {
  late RecordModel _challenge;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    subscribe();
  }

  void subscribe() {
    widget.pb.collection("challenges").subscribe(widget.challenge.id,
        (newValue) {
      print("Got update (${newValue.action})");
      Provider.of<ChallengeProvider>(context, listen: false)
          .saveExisting(newValue.record!);
      setState(() {
        _challenge = newValue.record!;
      });
    }, expand: "users");
  }

  @override
  void dispose() {
    super.dispose();
    widget.pb
        .collection(Collection.challenges)
        .unsubscribe(widget.challenge.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width;
        if (constraints.maxWidth < 400) {
          width =
              constraints.maxWidth - 30; // Fill the width on phones with margin
        } else {
          width = 300; // Limit to ~300 on larger devices
        }

        return Card.outlined(
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: InkWell(
            splashColor: theme.colorScheme.primary.withAlpha(30),
            onTap: () {
              openDialog(context);
            },
            child: SizedBox(
              width: width,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (_challenge.getBoolValue("ended"))
                      Row(
                        children: [
                          Text("Challenge has ended",
                              style: theme.textTheme.labelLarge)
                        ],
                      ),
                    if (_challenge.getBoolValue("ended"))
                      const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(challenges
                            .elementAt(_challenge.getIntValue("type"))
                            .icon),
                        const SizedBox(width: 10),
                        Text(
                          _challenge.getStringValue("name"),
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    OverlapStack(
                      align: OverlapStackAlign.start,
                      minSpacing: 1,
                      maxSpacing: 2.3,
                      itemSize: const Size(20, 40),
                      children: _challenge.expand["users"]!.map((user) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AdvancedAvatar(
                            name: user.getStringValue("username"),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.onPrimary),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void openDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ChallengeDialog(challenge: _challenge, pb: widget.pb);
      },
    ).then((_) async {
      final data = await widget.pb
          .collection(Collection.challenges)
          .getOne(_challenge.id, expand: "users");
      setState(() {
        _challenge = data;
      });
    });
  }
}

class ChallengeDialog extends StatefulWidget {
  final RecordModel challenge;
  final PocketBase pb;

  const ChallengeDialog({super.key, required this.challenge, required this.pb});

  @override
  _ChallengeDialogState createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog> {
  final formatter = NumberFormat('#,###');
  late RecordModel _challenge;
  bool _isDialogOpen = false;
  bool _hasSubmittedFeedback = false;
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 8));
    _challenge = widget.challenge;
    subscribe();
  }

  void subscribe() {
    widget.pb.collection("challenges").subscribe(widget.challenge.id,
        (newValue) {
      print("Got update (dialog)");
      Provider.of<ChallengeProvider>(context, listen: true)
          .saveExisting(newValue.record!);
      if (!_isDialogOpen) {
        setState(() {
          _challenge = newValue.record!;
        });
      }
    }, expand: "users");
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.pb
        .collection(Collection.challenges)
        .unsubscribe(widget.challenge.id);
    super.dispose();
  }

  void _openDialog(Widget dialog) {
    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      builder: (context) => dialog,
    ).then((_) async {
      //TODO: move to a provider based update system
      final data = await widget.pb
          .collection(Collection.challenges)
          .getOne(_challenge.id, expand: "users");
      setState(() {
        _isDialogOpen = false;
        _challenge = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: MenuAnchor(
                menuChildren: <Widget>[
                  if (_challenge.getDataValue("host") ==
                      widget.pb.authStore.model?.id)
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.person_add),
                      child: Text("Invite Users",
                          style: theme.textTheme.bodyLarge),
                      onPressed: () => _openDialog(CodeDialog(
                        pb: widget.pb,
                        challenge: _challenge,
                      )),
                    ),
                  if (_challenge.getDataValue("host") ==
                      widget.pb.authStore.model?.id)
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.group),
                      child: Text("Manage Users",
                          style: theme.textTheme.bodyLarge),
                      onPressed: () => _openDialog(UserDialog(
                        pb: widget.pb,
                        challenge: _challenge,
                      )),
                    ),
                  if (_challenge.getDataValue("host") ==
                      widget.pb.authStore.model?.id)
                    MenuItemButton(
                      leadingIcon: Icon(
                        Icons.delete,
                        color: theme.colorScheme.error,
                      ),
                      child: Text(
                        "Delete",
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                      onPressed: () => _openDialog(ConfirmDialog(
                        isDestructive: true,
                        icon: Icons.delete,
                        title: "Delete Challenge",
                        description:
                            "The challenge will be irreversibly deleted.",
                        onConfirm: () async {
                          await widget.pb
                              .collection(Collection.challenges)
                              .delete(_challenge.id);
                          if (context.mounted) {
                            Provider.of<ChallengeProvider>(context,
                                    listen: false)
                                .reloadChallenges(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Challenge deleted'),
                              ),
                            );
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.pop();
                          }
                        },
                      )),
                    )
                  else
                    MenuItemButton(
                      leadingIcon: Icon(
                        Icons.logout,
                        color: theme.colorScheme.error,
                      ),
                      child: Text(
                        "Leave",
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                      onPressed: () => _openDialog(ConfirmDialog(
                        isDestructive: true,
                        icon: Icons.logout,
                        title: "Leave Challenge",
                        description:
                            "You won't be able to rejoin without an invite code.",
                        onConfirm: () async {
                          final id = widget.pb.authStore.model?.id;
                          final data = Manager.fromChallenge(_challenge)
                              .removeUser(id)
                              .toJson();
                          await widget.pb
                              .collection(Collection.challenges)
                              .update(_challenge.id,
                                  body: {"users-": id, "data": data});

                          if (context.mounted) {
                            Provider.of<ChallengeProvider>(context,
                                    listen: false)
                                .reloadChallenges(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Left challenge'),
                              ),
                            );
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.pop();
                          }
                        },
                      )),
                    )
                ],
                builder: (BuildContext context, MenuController controller,
                    Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                  );
                },
              ),
            )
          ],
          title: Text(_challenge.getStringValue("name")),
        ),
        body: switch (_challenge.getIntValue("type")) {
          0 => _buildBingoCard(context),
          1 => _buildStepsCards(context),
          _ => const Text("unknown challenge type")
        },
      ),
    );
  }

  String trimString(String input, int maxCharacters) {
    if (input.length <= maxCharacters) {
      return input;
    } else {
      return '${input.substring(0, maxCharacters - 3)}...';
    }
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Widget _buildTopDetails(BuildContext context, String? winnerId) {
    _controller.play();
    final theme = Theme.of(context);
    final user =
        _challenge?.expand["users"]?.firstWhere((u) => u.id == winnerId);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_challenge.getBoolValue("ended") && user != null)
          Center(
              child: Align(
            alignment: Alignment.center,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      // Substitute for Symbols.trophy_rounded
                      color: theme.colorScheme.onSurface,
                      size: 26,
                    ),
                    const SizedBox(width: 15),
                    Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 1),
                      child: Text(
                        user.getStringValue("username", "Unknown"),
                        // Substitute for user.getStringValue("username")
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "is the winner",
                      style: Theme.of(context).textTheme.headlineSmall,
                    )
                  ],
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: ConfettiWidget(
                      blastDirectionality: BlastDirectionality.directional,
                      blastDirection: pi / 2,
                      gravity: 0.3,
                      colors: [
                        // Colors.green,
                        // Colors.blue,
                        // Colors.pink,
                        // Colors.orange,
                        // Colors.purple
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        theme.colorScheme.inversePrimary
                      ],
                      createParticlePath: drawStar,
                      confettiController: _controller,
                    ),
                  ),
                ),
              ],
            ),
          )),
        const SizedBox(
          height: 15,
        )
      ],
    );
  }

  Widget _buildBottomDetails(BuildContext context) {
    final format = DateFormat('MMMM dd');
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(
          height: 15,
        ),
        Column(
          children: [
            Text(
              switch (_challenge.getBoolValue("ended")) {
                true =>
                  "This challenge has ended and will be deleted ${DateTime.parse(_challenge.getDataValue("deleteDate")).relativeTime(context)}",
                false =>
                  "Ends ${DateTime.parse(_challenge.getDataValue("endDate")).relativeTime(context)}"
              },
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_challenge.getBoolValue("ended"))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Card.outlined(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                        child: Column(children: [
                          AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.easeOut,
                              child: _hasSubmittedFeedback
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Column(
                                        children: [
                                          Text(
                                            "Thanks for submitting feedback!",
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          Text(
                                            "Your feedback helps improve the app!",
                                            style: theme.textTheme.bodyLarge,
                                          )
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Text(
                                          "How was your experience?",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          child: EmojiFeedback(
                                            enableFeedback: true,
                                            animDuration: const Duration(
                                                milliseconds: 300),
                                            //initialRating: 0,
                                            customLabels: const [
                                              "Terrible",
                                              "Bad",
                                              "Okay",
                                              "Good",
                                              "Great"
                                            ],
                                            curve: Curves.easeOutBack,
                                            inactiveElementScale: .7,
                                            onChanged: (value) async {
                                              await widget.pb
                                                  .collection("feedback")
                                                  .create(body: {
                                                "rating": switch (value) {
                                                  1 => "Terrible",
                                                  2 => "Bad",
                                                  3 => "Okay",
                                                  4 => "Good",
                                                  5 => "Great",
                                                  _ => "Unknown"
                                                },
                                                "user": widget
                                                    .pb.authStore.model.id,
                                                "challenge": _challenge.id,
                                                "ratingId": value
                                              });

                                              await Future.delayed(
                                                  Duration(milliseconds: 300));
                                              setState(() {
                                                _hasSubmittedFeedback = true;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                        ])),
                  ))
          ],
        )
      ],
    );
  }

  Widget _buildStepsCards(BuildContext context) {
    var theme = Theme.of(context);
    final jsonMap = _challenge.getDataValue<Map<String, dynamic>>("data");
    final manager = StepsDataManager.fromJson(jsonMap);
    final userTotals = manager.data.map((userData) {
      final totalValue = userData.entries
          .map((entry) => entry.value) // Extract the values
          .fold(0, (sum, value) => sum + value); // Sum up the values
      return {
        'userId': userData.userId,
        'totalValue': totalValue,
      };
    }).toList();

    // Correctly sort by totalValue as an integer
    userTotals.sort(
        (a, b) => (b['totalValue'] as int).compareTo(a['totalValue'] as int));

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxUsernameLength = (constraints.maxWidth / 30).floor();

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              _buildTopDetails(context, userTotals.first['userId'] as String),
              ...userTotals.mapIndexed((index, data) {
                var user = _challenge.expand["users"]!
                    .firstWhere((u) => u.id == data['userId']);

                return Card(
                  elevation: 4.0, // Add elevation for better visual depth
                  color: theme.colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_challenge.getBoolValue("ended") && index == 0)
                          Row(
                            children: [
                              const SizedBox(width: 5),
                              Icon(
                                Symbols.trophy_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        // Position Indicator
                        Text(
                          "${index + 1}.",
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 20),
                        AdvancedAvatar(
                          name: user.getStringValue("username"),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.primary),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          size: 35,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          trimString(user.getStringValue("username"),
                              maxUsernameLength),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: theme.colorScheme.onPrimary),
                        ),
                        // Center
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${formatNumber(data['totalValue'] as int)} steps",
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary),
                              ),
                            ],
                          ),
                        ),
                        // User Avatar
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                );
              }),
              _buildBottomDetails(context)
            ],
          ),
        );
      },
    );
  }

  Widget _buildBingoCard(BuildContext context) {
    var theme = Theme.of(context);
    Map<String, dynamic> jsonMap = _challenge.getDataValue("data");
    final manager = BingoDataManager.fromJson(jsonMap);

    // Provide a default UserBingoData if not found
    final bingoActivities = manager.usersBingoData.firstWhere(
      (value) => value.userId == widget.pb.authStore.model?.id,
      orElse: () => UserBingoData(userId: "", activities: []),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor();

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              _buildTopDetails(context, null),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount > 1 ? crossAxisCount : 1,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: bingoActivities.activities.length,
                shrinkWrap: true,
                // Prevent unbounded height error
                //physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                itemBuilder: (context, index) {
                  final activity = bingoActivities.activities[index];

                  return Card(
                    clipBehavior: Clip.hardEdge,
                    color: theme.colorScheme.primary,
                    child: InkWell(
                      splashColor: theme.colorScheme.onPrimary.withAlpha(30),
                      onTap: activity.type != BingoDataType.filled
                          ? () {
                              final data = manager.updateUserBingoActivity(
                                widget.pb.authStore.model?.id,
                                index,
                                BingoDataType.filled,
                              );
                              if (data != null) {
                                widget.pb.collection("challenges").update(
                                    _challenge.id,
                                    body: {"data": data.toJson()});
                              } else {
                                debugPrint(
                                    "Manager#updateUserBingoActivity returned null");
                              }
                            }
                          : null,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activity.type.asIcon(),
                              size: 40,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activity.amount.toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildBottomDetails(context),
            ],
          ),
        );
      },
    );
  }
}
