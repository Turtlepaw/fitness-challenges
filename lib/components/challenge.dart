import 'package:fitness_challenges/components/userPreview.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:overlap_stack/overlap_stack.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

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
  bool _isDialogOpen = false; // Track dialog open state

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    subscribe();
  }

  void subscribe() {
    widget.pb.collection("challenges").subscribe(widget.challenge.id, (newValue) {
      if (mounted) {
        print("Got update (${newValue.action})");
        Provider.of<ChallengeProvider>(context, listen: false)
            .saveExisting(newValue.record!);
        setState(() {
          _challenge = newValue.record!;
        });
      }
    }, expand: "users");
  }

  @override
  void dispose() {
    widget.pb.collection(Collection.challenges).unsubscribe(widget.challenge.id);
    super.dispose();
  }

  void openDialog(BuildContext context) {
    setState(() {
      _isDialogOpen = true; // Track dialog state explicitly
    });

    context.push("/challenge/${_challenge.id}");
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return ChallengeDialog(challenge: _challenge, pb: widget.pb);
    //   },
    //   useSafeArea: false,
    // ).then((_) async {
    //   setState(() {
    //     _isDialogOpen = false;
    //   });
    //
    //   final data = await widget.pb
    //       .collection(Collection.challenges)
    //       .getOne(_challenge.id, expand: "users");
    //   if (mounted) {
    //     setState(() {
    //       _challenge = data;
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width;
        if (constraints.maxWidth < 400) {
          width = constraints.maxWidth - 30; // Fill the width on phones with margin
        } else {
          width = 300; // Limit to ~300 on larger devices
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            // Border container
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHigh,
                width: 1.1,
                style: BorderStyle.solid,
              ),
            ),
            child: Material(
              color: theme.colorScheme.surfaceContainerLow, // Background color
              borderRadius: BorderRadius.circular(15),
              clipBehavior: Clip.antiAlias, // Ensures clipping for ripple
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
                          itemLimit: 5,
                          children: _challenge.expand["users"]!.map((user) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Avatar(user: user),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

class Avatar extends StatelessWidget {
  final RecordModel user;
  final double size;
  const Avatar({super.key, required this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdvancedAvatar(
      size: size,
      name: getUsernameFromUser(user),
      autoTextSize: true,
      style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}