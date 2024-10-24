import 'package:fitness_challenges/components/communityChallenge.dart';
import 'package:fitness_challenges/components/loader.dart';
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

class _CommunityPageState extends State<CommunityPage> {
  bool _isLoading = true;
  List<RecordModel> challenges = List.empty(growable: true);
  late PocketBase pb;

  @override
  initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    getPublicChallenges();
  }

  Future<void> getPublicChallenges() async {
    final newChallenges = await pb.collection(Collection.challenges).getFullList(
      filter: "public=true",
      expand: "users"
    );

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
        title: const Text('Community'),
      ),
      body: ListView(
        children: <Widget>[
          if (_isLoading)
            ...List.generate(3, (index) {
              return Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                  Icon(Symbols.travel_explore_rounded, size: 60, color: theme.colorScheme.onSurfaceVariant,),
                  const SizedBox(height: 5,),
                  Text("No community challenges", style: theme.textTheme.headlineSmall,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("We're always creating new community challenges though, so check back here!", style: theme.textTheme.bodyLarge, textAlign: TextAlign.center,),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 25)
        ],
      ),
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
