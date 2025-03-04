import 'dart:math';

import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:fitness_challenges/components/dialog/userDialog.dart';
import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/components/userPreview.dart';
import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/gen/assets.gen.dart';
import 'package:fitness_challenges/routes/challenges/bingo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:relative_time/relative_time.dart';

import '../components/dialog/codeDialog.dart';
import '../components/dialog/confirmDialog.dart';
import '../components/dialog/userListDialog.dart';
import '../types/collections.dart';
import '../utils/challengeManager.dart';
import '../utils/common.dart';
import '../utils/manager.dart';
import '../utils/sharedLogger.dart';
import '../utils/steps/data.dart';

class ChallengeDialog extends StatefulWidget {
  final String challenge;

  const ChallengeDialog({super.key, required this.challenge});

  @override
  _ChallengeDialogState createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog> {
  final formatter = NumberFormat('#,###');
  RecordModel? _challenge;
  bool _isDialogOpen = false;
  bool _hasSubmittedFeedback = false;
  late ConfettiController _controller;
  Future<void> Function()? _unsubscribe;
  late PocketBase pb;

  @override
  initState() {
    super.initState();
    //pb = Provider.of<PocketBase>(context);

    _controller = ConfettiController(duration: const Duration(seconds: 8));
    //getChallenge();
    print("Dialog init");
  }

  Future<void> getChallenge() async {
    final data = await pb
        .collection(Collection.challenges)
        .getOne(widget.challenge, expand: "users");
    setState(() {
      _challenge = data;
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // Run your code here
    print('Dialog opened');
    pb = Provider.of<PocketBase>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await pb
        .collection(Collection.challenges)
        .getOne(widget.challenge, expand: "users");
    setState(() {
      _challenge = data;
    });
    subscribe();
  }

  void subscribe() async {
    if (_unsubscribe != null) {
      return Provider.of<SharedLogger>(context, listen: false)
          .debug("Unsubscribe func is not null");
    }

    final unsubscribe = await pb
        .collection("challenges")
        .subscribe(widget.challenge, (newValue) {
      final logger = Provider.of<SharedLogger>(context, listen: false);
      logger.debug("Update received in dialog");
      Provider.of<ChallengeProvider>(context, listen: false)
          .saveExisting(newValue.record!);
      if (mounted && newValue.record != null) {
        setState(() {
          _challenge = newValue.record!;
        });
      } else {
        logger.debug(
            "Not mounted, not updating dialog (realtime _ChallengeDialogState)");
      }
    }, expand: "users");

    setState(() {
      _unsubscribe = unsubscribe;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_unsubscribe != null) _unsubscribe!();
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
      final data = await pb
          .collection(Collection.challenges)
          .getOne(widget.challenge, expand: "users");
      setState(() {
        _isDialogOpen = false;
        _challenge = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = _challenge;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: Tooltip(
            message: "Close",
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: challenge == null ? 15 : 5),
              child: challenge == null
                  ? const LoadingBox(width: 80, height: 30)
                  : MenuAnchor(
                      menuChildren: <Widget>[
                        if (challenge.getDataValue("host") ==
                            pb.authStore.model?.id)
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.person_add),
                            child: Text("Invite Users",
                                style: theme.textTheme.bodyLarge),
                            onPressed: () => _openDialog(CodeDialog(
                              pb: pb,
                              challenge: challenge,
                            )),
                          ),
                        if (challenge.getDataValue("host") ==
                            pb.authStore.model?.id)
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.group),
                            child: Text("Manage Users",
                                style: theme.textTheme.bodyLarge),
                            onPressed: () => _openDialog(UserListDialog(
                              pb: pb,
                              challenge: challenge,
                            )),
                          ),
                        if (challenge.getDataValue("host") ==
                            pb.authStore.model?.id)
                          MenuItemButton(
                            leadingIcon: const Icon(
                              Icons.access_time_filled_rounded,
                            ),
                            child: Text(
                              "End Challenge",
                              style: theme.textTheme.bodyLarge,
                            ),
                            onPressed: () => _openDialog(ConfirmDialog(
                              icon: Icons.access_time_filled_rounded,
                              title: "End Challenge",
                              description:
                                  "But, everyone's been having so much fun! This wil permanently end the challenge.",
                              onConfirm: () async {
                                DateTime currentUtcTime = DateTime.now()
                                    .toUtc(); // Get current UTC time
                                DateTime futureTime = currentUtcTime
                                    .add(const Duration(days: 7)); // Add 7 days

                                await pb
                                    .collection(Collection.challenges)
                                    .update(challenge.id, body: {
                                  'ended': true,
                                  'deleteDate': futureTime.toIso8601String(),
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Challenge ended'),
                                    ),
                                  );
                                  final nav = Navigator.of(context);
                                  nav.pop();
                                }
                              },
                            )),
                          ),
                        if (challenge.getDataValue("host") ==
                            pb.authStore.model?.id)
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
                                await pb
                                    .collection(Collection.challenges)
                                    .delete(challenge.id);
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
                                final id = pb.authStore.model?.id;
                                final data = Manager.fromChallenge(challenge)
                                    .removeUser(id)
                                    .toJson();
                                await pb
                                    .collection(Collection.challenges)
                                    .update(challenge.id,
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
                        return Tooltip(
                          message: "Options",
                          child: IconButton(
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            icon: const Icon(Icons.more_vert),
                          ),
                        );
                      },
                    ),
            )
          ],
          title: Text(challenge == null
              ? "Loading..."
              : challenge.getStringValue("name")),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: challenge == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Center(
                    heightFactor: 1,
                    child: LoadingBox(
                        width: MediaQuery.of(context).size.width - 30,
                        height: 200),
                  ),
                )
              : switch (challenge.getIntValue("type")) {
                  0 => BingoCardWidget(
                      buildTopDetails: (context) => _buildTopDetails(
                          context, challenge.getStringValue("winner")),
                      buildBottomDetails: _buildBottomDetails,
                      challenge: challenge,
                    ),
                  1 => _buildStepsCards(context),
                  _ => const Text("unknown challenge type")
                },
        ),
      ),
    );
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
        _challenge?.expand["users"]?.firstWhereOrNull((u) => u.id == winnerId);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_challenge!.getBoolValue("ended") && user != null)
          Center(
              child: Align(
            alignment: Alignment.center,
            child: Stack(
              children: [
                Flexible(
                    child: Row(
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
                    InkWell(
                      onTap: () => _openDialog(UserDialog(
                        pb: pb,
                        user: user,
                      )),
                      borderRadius: BorderRadius.circular(
                          6), // Ensures the ripple respects the borderRadius
                      splashColor: theme.colorScheme.primary
                          .withOpacity(0.1), // Optional: Customize splash color
                      child: Ink(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                              6), // Applies the border radius
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        child: Text(
                          trimString(getUsernameFromUser(user),
                              maxUsernameLengthShort),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(
                      "is the winner",
                      style: Theme.of(context).textTheme.titleMedium,
                    ))
                  ],
                )),
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

  String getChallengeStatus(dynamic challenge) {
    final format = DateFormat('EEEE, MMMM d'); // Your date format

    switch (challenge.getBoolValue("ended")) {
      case true:
        final deleteDate = DateTime.parse(challenge.getDataValue("deleteDate"));
        return "This challenge has ended and will be deleted ${deleteDate.relativeTime(context)} (${format.format(deleteDate)})";
      case false:
        if (challenge.getBoolValue("autoEnd")) {
          return "Ends when complete"; // Handle autoEnd case
        } else {
          final endDate = DateTime.parse(challenge.getDataValue("endDate"));
          return "Ends ${endDate.relativeTime(context)} (${format.format(endDate)})";
        }
      default:
        return ""; // Handle any unexpected cases
    }
  }

  Widget _buildBottomDetails(BuildContext context) {
    final format = DateFormat('EEEE, MMMM d');
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(
          height: 15,
        ),
        Column(
          children: [
            Text(
              getChallengeStatus(_challenge),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (_challenge!.getBoolValue("ended"))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Card.outlined(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                        child: Column(children: [
                          AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOut,
                              child: _hasSubmittedFeedback
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Column(
                                        children: [
                                          SvgPicture.asset(
                                            Assets.images.notoAwesome,
                                            width: 50,
                                          ),
                                          const SizedBox(height: 15),
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
                                          child: SizedBox(
                                            //height: 100,
                                            child: EmojiFeedback(
                                              enableFeedback: true,
                                              animDuration: const Duration(
                                                  milliseconds: 300),
                                              onChangeWaitForAnimation: true,
                                              //initialRating: 0,
                                              customLabels: const [
                                                "Terrible",
                                                "Bad",
                                                "Okay",
                                                "Good",
                                                "Great"
                                              ],
                                              curve: Curves.easeOutBack,
                                              emojiPreset: notoAnimatedEmojis,
                                              inactiveElementScale: .9,
                                              tapScale: .8,
                                              onChanged: (value) async {
                                                if (value == null) return;
                                                await pb
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
                                                  "user": pb.authStore.model.id,
                                                  "challenge": _challenge!.id,
                                                  "ratingId": value
                                                });

                                                await Future.delayed(
                                                    const Duration(
                                                        milliseconds: 300));
                                                setState(() {
                                                  _hasSubmittedFeedback = true;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                        ])),
                  )),
            const SizedBox(
              height: 20,
            )
          ],
        )
      ],
    );
  }

  Widget _buildStepsCards(BuildContext context) {
    var theme = Theme.of(context);
    final jsonMap = _challenge!.getDataValue<Map<String, dynamic>>("data");
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
        final maxUsernameLength =
            (constraints.maxWidth / MAX_USERNAME_LENGTH).floor();

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            shrinkWrap:
                true, // This will make the ListView take the height of its content
            physics:
                const ClampingScrollPhysics(), // You can adjust the scroll behavior if needed
            children: [
              _buildTopDetails(context, userTotals.first['userId'] as String),
              ...userTotals.mapIndexed((index, data) {
                var user = _challenge!.expand["users"]!
                    .firstWhere((u) => u.id == data['userId']);

                return Card(
                  clipBehavior: Clip.hardEdge,
                  elevation: 4.0, // Add elevation for better visual depth
                  color: theme.colorScheme.primary,
                  child: InkWell(
                    highlightColor: theme.colorScheme.primary,
                    onTap: () => _openDialog(UserDialog(
                      pb: pb,
                      user: user,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // if (_challenge!.getBoolValue("ended") && index == 0)
                          //   Row(
                          //     children: [
                          //       const SizedBox(width: 5),
                          //       Icon(
                          //         Symbols.trophy_rounded,
                          //         color: theme.colorScheme.onPrimary,
                          //         size: 26,
                          //       ),
                          //       const SizedBox(width: 10),
                          //     ],
                          //   ),
                          // Position Indicator
                          Text(
                            "${index + 1}.",
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 20),
                          AdvancedAvatar(
                            name: getUsernameFromUser(user),
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
                            trimString(
                                getUsernameFromUser(user), maxUsernameLength),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.onPrimary),
                          ),
                          // Center
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${formatInt(data['totalValue'] as int)}",
                                  style: theme.textTheme.titleMedium?.copyWith(
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
}
