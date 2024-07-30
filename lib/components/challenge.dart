import 'dart:convert';

import 'package:fitness_challenges/components/challenges/codeDialog.dart';
import 'package:fitness_challenges/components/challenges/confirmDialog.dart';
import 'package:fitness_challenges/components/challenges/userDialog.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:fitness_challenges/utils/manager.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../manager.dart';

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._challenge.expand["users"]!.map((user) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: AdvancedAvatar(
                              name: user.getStringValue("username"),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          );
                        }).toList()
                      ],
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
    );
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

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    subscribe();
  }

  void subscribe() {
    widget.pb.collection("challenges").subscribe(widget.challenge.id,
        (newValue) {
      setState(() {
        _challenge = newValue.record!;
      });
    }, expand: "users");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Symbols.close_rounded),
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
                      widget.pb.authStore.model?.id) MenuItemButton(
                    leadingIcon: const Icon(Symbols.passkey_rounded),
                    child:
                        Text("Invite Users", style: theme.textTheme.bodyLarge),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => CodeDialog(
                        pb: widget.pb,
                        challenge: _challenge,
                      ),
                    ),
                  ),
                  if (_challenge.getDataValue("host") ==
                      widget.pb.authStore.model?.id) MenuItemButton(
                    leadingIcon: const Icon(Symbols.group_rounded),
                    child:
                    Text("Manage Users", style: theme.textTheme.bodyLarge),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => UserDialog(
                        pb: widget.pb,
                        challenge: _challenge,
                      ),
                    ),
                  ),
                  if (_challenge.getDataValue("host") ==
                      widget.pb.authStore.model?.id)
                    MenuItemButton(
                      leadingIcon: Icon(
                        Symbols.delete_rounded,
                        color: theme.colorScheme.error,
                      ),
                      child: Text(
                        "Delete",
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => ConfirmDialog(
                          isDestructive: true,
                          icon: Symbols.delete_rounded,
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
                        ),
                      ),
                    )
                  else
                    MenuItemButton(
                      leadingIcon: Icon(
                        Symbols.logout_rounded,
                        color: theme.colorScheme.error,
                      ),
                      child: Text(
                        "Leave",
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => ConfirmDialog(
                          isDestructive: true,
                          icon: Symbols.logout_rounded,
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
                        ),
                      ),
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
                    icon: const Icon(Symbols.more_vert_rounded),
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
        return Container(
          padding: const EdgeInsets.all(10.0),
          child: ListView.builder(
            itemCount: userTotals.length,
            itemBuilder: (context, index) {
              var data = userTotals[index];
              var user = _challenge.expand["users"]!
                  .firstWhere((u) => u.id == data['userId']);

              return Card(
                elevation: 4.0, // Add elevation for better visual depth
                color: theme.colorScheme.primary,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                        user.getStringValue("username"),
                        // Use username as full name
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: theme.colorScheme.onPrimary),
                      ),
                      // Center
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${formatter.format(data['totalValue'])} steps",
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
            },
          ),
        );
      },
    );
  }

  Widget _buildBingoCard(BuildContext context) {
    var theme = Theme.of(context);
    Map<String, dynamic> jsonMap = _challenge.getDataValue("data");
    final manager = BingoDataManager.fromJson(jsonMap);
    final bingoActivities = manager.usersBingoData.firstWhere((value) {
      return value.userId == widget.pb.authStore.model.id;
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor();

        return Container(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount > 1 ? crossAxisCount : 1,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
            ),
            itemCount: bingoActivities.activities.length,
            itemBuilder: (context, index) {
              return Card(
                  clipBehavior: Clip.hardEdge,
                  color: theme.colorScheme.primary,
                  child: InkWell(
                    splashColor: theme.colorScheme.onPrimary.withAlpha(30),
                    onTap: bingoActivities.activities[index].type !=
                            BingoDataType.filled
                        ? () {
                            final data = manager.updateUserBingoActivity(
                                widget.pb.authStore.model.id,
                                index,
                                BingoDataType.filled);
                            if (data != null) {
                              widget.pb.collection("challenges").update(
                                  _challenge.id,
                                  body: {"data": jsonEncode(data.toJson())});
                            }
                          }
                        : null,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            bingoActivities.activities[index].type.asIcon(),
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bingoActivities.activities[index].amount.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.colorScheme.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          ),
        );
      },
    );
  }
}
