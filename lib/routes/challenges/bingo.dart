import 'package:confetti/confetti.dart'; // Import the confetti package
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fitness_challenges/components/userPreview.dart';
import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/utils/health.dart';
import 'package:fitness_challenges/utils/sharedLogger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../../components/dialog/userDialog.dart';
import '../../types/collections.dart';
import '../../utils/bingo/data.dart';
import '../../utils/common.dart';

class BingoCardWidget extends StatefulWidget {
  final Widget Function(BuildContext) buildTopDetails;
  final Widget Function(BuildContext) buildBottomDetails;
  final RecordModel? challenge;

  const BingoCardWidget(
      {super.key,
      required this.buildTopDetails,
      required this.buildBottomDetails,
      required this.challenge});

  @override
  _BingoCardWidgetState createState() => _BingoCardWidgetState();
}

class _BingoCardWidgetState extends State<BingoCardWidget> {
  late ConfettiController _confettiController;
  List<bool> _completedCards = [];
  List<bool> _isAnimating = [];
  UserBingoData? _selectedBingoData;
  dynamic selectedUser;
  late PocketBase pb;
  late BingoDataManager manager;
  late RecordModel _challenge;
  late SharedLogger logger;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    pb = Provider.of<PocketBase>(context, listen: false);
    logger = Provider.of<SharedLogger>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeState();
  }

  @override
  void didUpdateWidget(covariant BingoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.challenge != oldWidget.challenge) {
      _initializeState();
    }
  }

  void _initializeState() {
    if (widget.challenge == null) return;

    _challenge = widget.challenge!;
    Map<String, dynamic> jsonMap = _challenge.getDataValue("data");
    manager = BingoDataManager.fromJson(jsonMap);

    _selectedBingoData = manager.data.firstWhere(
      (value) => value.userId == pb.authStore.model?.id,
      orElse: () => UserBingoData(userId: "", activities: []),
    );

    selectedUser = _getSelectedUser();

    // Preserve state if possible, or initialize
    if (_completedCards.isEmpty ||
        _completedCards.length != _selectedBingoData!.activities.length) {
      _completedCards = List<bool>.generate(
        _selectedBingoData!.activities.length,
        (index) =>
            _selectedBingoData!.activities[index].type == BingoDataType.filled,
      );
    }

    if (_isAnimating.isEmpty ||
        _isAnimating.length != _selectedBingoData!.activities.length) {
      _isAnimating =
          List<bool>.filled(_selectedBingoData!.activities.length, false);
    }
  }

  dynamic _getSelectedUser() {
    return _challenge.expand["users"]?.firstWhere(
          (u) => u.id == _selectedBingoData?.userId,
          orElse: () => pb.authStore.model!,
        ) ??
        pb.authStore.model;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            widget.buildTopDetails(context),
            _buildSelectedUserCard(theme),
            _buildBingoGrid(theme),
            _buildHealthBlocks(theme),
            _buildOtherUsersCards(manager),
            widget.buildBottomDetails(context),
          ],
        );
      },
    );
  }

  Widget _buildHealthBlocks(ThemeData theme) {
    final health = Provider.of<HealthManager>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 1, // Space between items horizontally
        runSpacing: 5, // Set this to 0 to minimize space between rows
        alignment: WrapAlignment.start, // Align items at the start
        children: [
          _buildDataBlock(BingoDataType.steps, health.steps),
          _buildDataBlock(BingoDataType.calories, health.calories),
          _buildDataBlock(BingoDataType.distance, health.distance),
          _buildDataBlock(BingoDataType.water, health.water),
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 15),
      child: Row(
        children: [
          const Icon(Symbols.playing_cards_rounded),
          const SizedBox(width: 10),
          Text(
            "${selectedUser.id == pb.authStore.model?.id ? "Your" : "${getUsernameFromUser(selectedUser)}'s"} bingo card",
            style: theme.textTheme.headlineSmall,
          )
        ],
      ),
    );
  }

  Widget _buildDataBlock(BingoDataType type, num? amount) {
    var theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      // Minimal padding
      margin: const EdgeInsets.all(2),
      // Minimal margin
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: theme.colorScheme.surfaceContainerHigh,
            width: 1.1,
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignCenter,
          )),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Minimize row size
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            type.asIcon(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4), // Smaller space between icon and text
          Text(
            "${formatNumber(amount ?? 0)} ${type.asString()}",
            textAlign: TextAlign.center, // Center the text
          ),
        ],
      ),
    );
  }

  Widget _buildBingoGrid(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
          width: 1.1,
        ),
      ),
      // First get the screen width to calculate tile sizes
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 20.0; // Account for padding
          final tileWidth = (availableWidth - (4 * 5.0)) / 5;
          final tileHeight = tileWidth / 0.73;

          // Then use SingleChildScrollView for vertical scrolling
          return SingleChildScrollView(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5.0,
                childAspectRatio: tileWidth / tileHeight,
              ),
              itemCount: _selectedBingoData!.activities.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final isWinningTile =
                (_selectedBingoData?.winningTiles ?? []).contains(index);

                return _buildBingoTile(index, theme, isWinningTile: isWinningTile);
              },
            ),
          );
        },
      ),
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
        if (a.userId == currentUserId) return -1; // Put the current user first
        if (b.userId == currentUserId) return 1; // Put other users after
        return 0; // Keep the order of others unchanged
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text indicating that this is the section for other users
        Padding(
          padding: const EdgeInsets.only(left: 5, top: 15, bottom: 5),
          child: Row(
            children: [
              const Icon(Symbols.group_rounded),
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
              final isSelected =
                  userBingoData.userId == _selectedBingoData?.userId;
              final user = _challenge!.expand["users"]!
                  .firstWhere((u) => u.id == userBingoData.userId);

              return Card.outlined(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: theme.colorScheme.primary.withAlpha(30),
                  onLongPress: () => _openDialog(UserDialog(
                    pb: pb,
                    user: user,
                  )),
                  onTap: () {
                    setState(() {
                      _selectedBingoData = userBingoData;
                      selectedUser = user;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    constraints: const BoxConstraints(minWidth: 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AdvancedAvatar(
                          name: getUsernameFromUser(user),
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
                          trimString(getUsernameFromUser(user), 11),
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

  Widget _buildBingoTile(int index, ThemeData theme, {bool isWinningTile = false}) {
    final activity = _selectedBingoData!.activities[index];
    final isCompleted = _completedCards[index];
    final isAllowed = (activity.type != BingoDataType.filled &&
        selectedUser.id == pb.authStore.model?.id) && isPurchasable(Provider.of<HealthManager>(context), activity);

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedScale(
          scale: _isAnimating[index] ? 1.3 : (isWinningTile ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 300),
          child: AnimatedRotation(
            turns: _isAnimating[index] ? 0.02 : 0,
            duration: const Duration(milliseconds: 350),
            child: Container(
              margin: const EdgeInsets.all(3), // Slightly increased
              decoration: BoxDecoration(
                border: isWinningTile
                    ? Border.all(
                  color: theme.colorScheme.primaryContainer,
                  style: BorderStyle.solid,
                  width: 3.5, // Slightly increased
                )
                    : null,
                color: isWinningTile
                    ? theme.colorScheme.primary
                    : (isAllowed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.9)),
                borderRadius: BorderRadius.circular(10), // Increased
              ),
              child: InkWell(
                onTap: isAllowed ? () => _handleTileTap(index) : null,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0), // Increased
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWinningTile
                              ? Symbols.star_rounded
                              : activity.type.asIcon(),
                          size: 28, // Increased
                          color: isWinningTile
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimary,
                        ),
                        if (!isWinningTile) const SizedBox(height: 6), // Increased
                        if (!isWinningTile)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatNumber(activity.amount),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith( // Changed to labelMedium
                                color: isWinningTile
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onPrimary,
                                fontWeight: isWinningTile
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (isWinningTile)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: 0.3,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10), // Increased to match
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.secondary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    center: Alignment.center,
                    radius: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openDialog(Widget dialog) {
    showDialog(
      context: context,
      builder: (context) => dialog,
    ).then((_) async {
      if(widget.challenge == null) return;
      //TODO: move to a provider based update system
      final data = await pb
          .collection(Collection.challenges)
          .getOne(widget.challenge!.id, expand: "users");
      setState(() {
        _challenge = data;
      });
    });
  }

  bool isPurchasable(HealthManager health, BingoDataActivity activity) {
    return switch(activity.type){
      BingoDataType.steps => (health.steps ?? 0) >= activity.amount,
      BingoDataType.calories => (health.calories ?? 0) >= activity.amount,
      BingoDataType.distance => (health.distance ?? 0) >= activity.amount,
      BingoDataType.water => (health.water ?? 0) >= activity.amount,
      BingoDataType.filled => false,
      BingoDataType.azm => false //throw UnimplementedError(),
    };
  }

  Future<void> _handleTileTap(int index) async {
    setState(() {
      _isAnimating[index] = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      var data = await manager.updateUserBingoActivity(
        pb.authStore.model?.id,
        index,
        BingoDataType.filled,
      );

      // Debugging the updated user data
      print(
          "Updated Activities: ${data?.getUser(pb.authStore.model?.id).activities}");

      if (data != null) {
        Map<String, dynamic> body = {};
        // Check if user won
        final winningTiles = data.checkIfUserHasWon(5, pb.authStore.model?.id);
        final oldWinner = _challenge.getStringValue("winner", null) as String?;
        if (winningTiles.isNotEmpty) {
          data = data.setWinningTilesOf(pb.authStore.model.id, winningTiles);
          if(oldWinner == null || oldWinner.isEmpty) body['winner'] = pb.authStore.model.id;
          if(_challenge.getBoolValue("autoEnd") == true) {
            body['ended'] = true;
            final date = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).add(const Duration(days: 14));
            body['deleteDate'] = pbDateFormat.format(date);
          };
          logger.debug("User ${pb.authStore.model.id} won!");
        }

        body['data'] = data.toJson();

        final updatedChallenge = await pb.collection("challenges").update(
              _challenge.id,
              body: body,
              expand: "users",
            );

        setState(() {
          _challenge = updatedChallenge;
          _completedCards[index] = true;
          _isAnimating[index] = false;
          selectedUser = _getSelectedUser(); // Update selected user
        });
      }
    } catch (e) {
      logger.error("Error: $e");
      setState(() {
        _isAnimating[index] = false;
      });
    }
  }
}
