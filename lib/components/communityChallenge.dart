import 'package:collection/collection.dart';
import 'package:fitness_challenges/components/communityJoin.dart';
import 'package:fitness_challenges/components/userPreview.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:overlap_stack/overlap_stack.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../utils/challengeManager.dart';

class CommunityChallenge extends StatefulWidget {
  final RecordModel challenge;
  final PocketBase pb;

  const CommunityChallenge(
      {super.key, required this.challenge, required this.pb});

  @override
  _CommunityChallengeState createState() => _CommunityChallengeState();
}

class _CommunityChallengeState extends State<CommunityChallenge> {
  late RecordModel _challenge;
  Future<void> Function()? unsubscribeFunc;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    subscribe();
  }

  void subscribe() async {
    final func = await widget.pb
        .collection("challenges")
        .subscribe(widget.challenge.id, (newValue) {
      if (mounted) {
        setState(() {
          _challenge = newValue.record!;
        });
      }
    }, expand: "users");

    setState(() {
      unsubscribeFunc = func;
    });
  }

  @override
  void dispose() {
    if (unsubscribeFunc != null) unsubscribeFunc!();
    super.dispose();
  }

  void openDialog(BuildContext context) {
    final joinedChallenges = Provider.of<ChallengeProvider>(context, listen: false).challenges;
    final hasJoined = joinedChallenges.firstWhereOrNull((e) => e.id == _challenge.id) != null;

    if(hasJoined){
      context.push("/challenge/${_challenge.id}");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return CommunityJoinDialog(challenge: _challenge);
      },
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedChallenges = Provider.of<ChallengeProvider>(context).challenges;
    final hasJoined = joinedChallenges.firstWhereOrNull((e) => e.id == _challenge.id) != null;

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
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OverlapStack(
                            align: OverlapStackAlign.start,
                            minSpacing: 1,
                            maxSpacing: 2.3,
                            itemSize: const Size(20, 40),
                            itemLimit: 5,
                            children:
                                userListFromChallenge(_challenge).map((user) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: AdvancedAvatar(
                                  name: user,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        FilledButton(
                            onPressed: () {
                              openDialog(context);
                            },
                            child: hasJoined ? const Row(
                              children: [
                                Icon(Symbols.check_rounded),
                                SizedBox(width: 5),
                                Text("Joined")
                              ],
                            ) : const Text("Join"))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<String> userListFromChallenge(RecordModel challenge,
    {bool debugMode = false, int limit = 5}) {
  var items = challenge.expand["users"]!
      .map((user) => getUsernameFromUser(user))
      .toList(growable: true);
  if (debugMode) {
    items = List.filled(10, "User", growable: true);
  }

  if (items.length > limit) {
    final remaining = (items.length - limit + 1).abs();
    items = items.sublist(0, limit - 1);
    items.add("+$remaining");
  }

  return items;
}
