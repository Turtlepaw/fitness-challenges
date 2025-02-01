import 'package:fitness_challenges/components/communityChallenge.dart';
import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/components/privacy.dart';
import 'package:fitness_challenges/components/userPreview.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

const hideUsername = "hide_username";

class _CommunityPageState extends State<CommunityPage> {
  bool _isLoading = true;
  List<RecordModel> challenges = List.empty(growable: true);
  late PocketBase pb;
  bool consentAccepted = true;
  bool hideUsername = false;

  @override
  initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getPublicChallenges();
    consentAccepted = (pb.authStore.model as RecordModel?)
            ?.getBoolValue("featureCommunityConsent") ??
        false;
  }

  Future<void> getPublicChallenges() async {
    final newChallenges = await pb
        .collection(Collection.challenges)
        .getFullList(filter: "public=true", expand: "users");

    setState(() {
      challenges = newChallenges;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(consentAccepted ? 'Community' : 'Community'),
      ),
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: consentAccepted ? buildPage(theme) : buildConsentPage(theme)),
    );
  }

  Widget buildConsentPage(ThemeData theme) {
    return Stack(children: [
      ListView(
        children: [
          const SizedBox(
            height: 25,
          ),
          Align(
            // Use Align with Alignment.center
            alignment: Alignment.center,
            child: Column(
              // Use Column for vertical alignment
              mainAxisSize: MainAxisSize.min,
              // Prevent Column from taking full height
              children: [
                const Icon(Symbols.group_rounded, size: 60),
                Text("Community", style: theme.textTheme.headlineLarge),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "Welcome to community, where you can participate in challenges with other users.",
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 15,
                ),
                Text("Privacy Controls", style: theme.textTheme.headlineSmall),
                const SizedBox(
                  height: 15,
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: PrivacyControls(
                        alignment: CrossAxisAlignment.center,
                        showOnly: const [
                          PrivacyControl.hideUsernameInCommunity
                        ],
                        onChanged: (control, value) {
                          if (control ==
                              PrivacyControl.hideUsernameInCommunity) {
                            print(
                                "Hide username in community changed to $value");
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                hideUsername = value;
                              });
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text("You'll appear as", style: theme.textTheme.titleLarge),
                    const SizedBox(
                      height: 15,
                    ),
                    IntrinsicWidth(
                        child: UserPreview(
                      forceRandomUsername: hideUsername,
                    ))
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.only(bottom: 25, top: 15),
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  pb
                      .collection("users")
                      .update((pb.authStore.model as RecordModel).id, body: {
                    "featureCommunityConsent": true,
                  });

                  setState(() {
                    consentAccepted = true;
                  });
                },
                label: const Text('Continue'),
                //icon: const Icon(Symbols.check),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget buildPage(ThemeData theme) {
    return ListView(
      children: <Widget>[
        if (_isLoading)
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: LoadingBox(
                  width: MediaQuery.of(context).size.width - 30, height: 150),
            );
          })
        else if (challenges.isNotEmpty)
          ...challenges.map((value) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: CommunityChallenge(challenge: value, pb: pb),
            );
          })
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Symbols.travel_explore_rounded,
                  size: 60,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "No community challenges",
                  style: theme.textTheme.headlineSmall,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "We're always creating new community challenges though, so check back here!",
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 25)
      ],
    );
  }

  double getWidth(BoxConstraints constraints) {
    if (constraints.maxWidth < 500) {
      return constraints.maxWidth - 10; // Fill the width on phones with margin
    } else {
      return 500; // Limit to ~200 on larger devices
    }
  }

  Widget buildCard(List<Widget> children, {double? height}) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = getWidth(constraints);

      return Center(
          child: Container(
        constraints: BoxConstraints(minHeight: height ?? 0.0),
        width: width,
        child: Card.outlined(
          //clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ));
    });
  }
}
