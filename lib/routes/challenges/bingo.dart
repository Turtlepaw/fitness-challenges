import 'dart:math';

import 'package:confetti/confetti.dart'; // Import the confetti package
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../../utils/bingo/data.dart';

class BingoCardWidget extends StatefulWidget {
  final Widget Function(BuildContext) buildTopDetails;
  final Widget Function(BuildContext) buildBottomDetails;
  final RecordModel? challenge;
  const BingoCardWidget({super.key, required this.buildTopDetails, required this.buildBottomDetails, required this.challenge});

  @override
  _BingoCardWidgetState createState() => _BingoCardWidgetState();
}

class _BingoCardWidgetState extends State<BingoCardWidget> {
  late ConfettiController _confettiController;
  List<bool> _completedCards = [];
  List<bool> _isAnimating = [];
  late dynamic selectedUser; // Declare selectedUser here
  UserBingoData? _selectedBingoData;
  late PocketBase pb;
  late BingoDataManager manager;
  late RecordModel _challenge;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    pb = Provider.of<PocketBase>(context, listen: false);

    // Initialize the challenge, selected user, and animation states
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initializeState();
      });
    });
  }

  @override
  void didUpdateWidget(covariant BingoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if widget.challenge has changed
    if (widget.challenge != oldWidget.challenge) {
      // Reinitialize state if the challenge has changed
      setState(() {
        _initializeState(); // Reinitialize with the new challenge
      });
    }
  }

  void _initializeState() {
    _challenge = widget.challenge!;
    _selectedBingoData = _getSelectedBingoData();
    selectedUser = _getSelectedUser();
    Map<String, dynamic> jsonMap = _challenge.getDataValue("data");
    manager = BingoDataManager.fromJson(jsonMap);

    // Initialize _completedCards based on existing data
    _completedCards = List<bool>.generate(_selectedBingoData!.activities.length, (index) {
      return _selectedBingoData!.activities[index].type == BingoDataType.filled;
    });

    _isAnimating = List<bool>.filled(_selectedBingoData!.activities.length, false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update manager when dependencies change
    Map<String, dynamic> jsonMap = widget.challenge!.getDataValue("data");
    manager = BingoDataManager.fromJson(jsonMap);

    // Update state with the new challenge and completed cards
    setState(() {
      _initializeState(); // Reinitialize state whenever dependencies change
    });
  }

  dynamic _getSelectedUser() {
    // Retrieve the selected user based on _selectedBingoData or fallback to the current user
    return _challenge?.expand["users"]?.firstWhere(
          (u) => u.id == _selectedBingoData?.userId,
      orElse: () => pb.authStore.model!,
    ) ?? pb.authStore.model;
  }

  dynamic _getSelectedBingoData() {
    // Get the bingo data for the selected user, or default to the current user's data
    return BingoDataManager.fromJson(_challenge!.getDataValue("data")).data.firstWhere(
          (value) => value.userId == pb.authStore.model?.id,
      orElse: () => UserBingoData(userId: "", activities: []),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: [
              widget.buildTopDetails(context),

              // Display who owns the current bingo card
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    const Icon(
                        Symbols.playing_cards_rounded
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${selectedUser.id == pb.authStore.model?.id ? "Your" : "${selectedUser.getStringValue("username")}'s"} bingo card",
                      style: theme.textTheme.headlineSmall,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Main bingo card display based on the selected user's data
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainerHighest,
                    width: 1.1,
                    style: BorderStyle.solid,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  )
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 5.0,
                    mainAxisSpacing: 5.0,
                    childAspectRatio: 0.73,
                  ),
                  itemCount: _selectedBingoData!.activities.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final activity = _selectedBingoData!.activities[index];
                    final isCompleted = _completedCards[index];
                    final isAllowed = activity.type != BingoDataType.filled && selectedUser.id == pb.authStore.model?.id;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // This AnimatedContainer only handles scale and rotation
                        AnimatedScale(
                          scale: _isAnimating[index] ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          filterQuality: FilterQuality.high,
                          curve: Curves.easeInOut,
                          child: AnimatedRotation(
                            turns: _isAnimating[index] ? 0.02 : 0,
                            duration: const Duration(milliseconds: 350),
                            filterQuality: FilterQuality.high,
                            child: Card(
                              elevation: 5, // Add card elevation for a raised effect
                              color: !isAllowed ? theme.colorScheme.primary.withAlpha(210) : theme.colorScheme.primary, // Card handles color
                              clipBehavior: Clip.hardEdge,
                              child: InkWell(
                                onTap: isAllowed
                                    ? () async {
                                  setState(() {
                                    _isAnimating[index] = true;
                                  });

                                  // Simulate a delay to show the animation
                                  await Future.delayed(const Duration(milliseconds: 200));

                                  final data = manager.updateUserBingoActivity(
                                    pb.authStore.model?.id,
                                    index,
                                    BingoDataType.filled,
                                  );

                                  if (data != null) {
                                    final updatedChallenge = await pb.collection("challenges").update(
                                      _challenge!.id,
                                      body: {"data": data.toJson()},
                                      expand: "users",
                                    );
                                    setState(() {
                                      _challenge = updatedChallenge; // Update challenge state
                                      _completedCards[index] = true;
                                      _isAnimating[index] = false;
                                      //_confettiController.play(); // Start confetti animation
                                      selectedUser = _getSelectedUser(); // Update selected user
                                    });
                                  } else {
                                    debugPrint("Manager#updateUserBingoActivity returned null");
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
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Confetti effect for completed activity
                        if (isCompleted)
                          Positioned.fill(
                            child: ConfettiWidget(
                              confettiController: _confettiController,
                              blastDirectionality: BlastDirectionality.explosive,
                              numberOfParticles: 5,
                              gravity: 0.7,
                              shouldLoop: false,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                                theme.colorScheme.tertiary,
                              ], // Confetti colors
                              createParticlePath: (size) => drawStar(size),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Horizontal scroll of other users' bingo cards
              _buildOtherUsersCards(manager),

              widget.buildBottomDetails(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtherUsersCards(BingoDataManager manager) {
    var theme = Theme.of(context);

    // Get the current user's ID
    final currentUserId = pb.authStore.model?.id;

    // Sort the list so the current user comes first
    final sortedUsers = List.of(manager.data)
      ..sort((a, b) {
        // Sort by checking if the user ID matches the current user ID
        if (a.userId == currentUserId) return -1;  // Put the current user first
        if (b.userId == currentUserId) return 1;   // Put other users after
        return 0;                                  // Keep the order of others unchanged
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text indicating that this is the section for other users
        Padding(
          padding: const EdgeInsets.only(left: 5, top: 15, bottom: 5),
          child: Row(
            children: [
              const Icon(
                Symbols.group_rounded
              ),
              const SizedBox(width: 10),
              Text(
                "Other users",
                style: theme.textTheme.titleLarge,
              )
            ],
          ),
        ),

        // Horizontal list of other users' bingo cards
        Container(
          margin: const EdgeInsets.only(top: 5.0),
          height: 130.0, // Height for the horizontal card list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final userBingoData = sortedUsers[index];
              final isSelected = userBingoData.userId == _selectedBingoData?.userId;
              final user = _challenge!.expand["users"]!
                  .firstWhere((u) => u.id == userBingoData.userId);

              return Card.outlined(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: theme.colorScheme.primary.withAlpha(30),
                  onTap: () {
                    setState(() {
                      _selectedBingoData = userBingoData;
                      selectedUser = user;
                    });
                  },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      constraints: const BoxConstraints(
                        minWidth: 90
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AdvancedAvatar(
                            name: user.getStringValue("username"),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: selectedUser.id == user.id
                                ? Icon(
                              Symbols.check_rounded,
                              color: theme.colorScheme.onPrimary,
                            )
                                : null,
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            user.getStringValue("username"),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onSurfaceVariant
                                  .harmonizeWith(theme.colorScheme.primary)
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.id == currentUserId)
                            Text(
                              "You",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Optional: Custom particle shape for the confetti (stars)
  Path drawStar(Size size) {
    // Code for star-shape particle, using a custom Path
    final path = Path();
    final numberOfPoints = 5;
    final step = pi / numberOfPoints;
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final radius = min(halfWidth, halfHeight);
    for (int i = 0; i < numberOfPoints * 2; i++) {
      final isEven = i % 2 == 0;
      final r = isEven ? radius : radius / 2;
      final angle = i * step;
      final x = halfWidth + r * cos(angle);
      final y = halfHeight + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
