import 'package:fitness_challenges/components/common.dart';
import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/components/privacy.dart';
import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/routes/profile.dart';
import 'package:fitness_challenges/utils/bingo/data.dart';
import 'package:fitness_challenges/utils/common.dart';
import 'package:fitness_challenges/utils/health.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../components/debug_panel.dart';
import '../components/dialog/confirmDialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isAvailable = true;
  bool _isSystemHealthAutorized = false;
  bool _isWatchLoading = false;
  bool _isSysHealthLoading = false;
  bool _isRefreshing = false;
  late String username;
  late PocketBase pb;
  HealthType? healthType;

  @override
  initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);

    _checkHealthPermissions();
    username = (pb.authStore.model as RecordModel)
        .getStringValue("username", "unknown");

    //subscribe();
    _getHealthType();
  }

  @override
  void didChangeDependencies() {
    pb.collection("users").authRefresh();
    super.didChangeDependencies();
  }

  void _getHealthType() async {
    var type = await HealthTypeManager().getHealthType();

    if (mounted) {
      setState(() {
        healthType = type;
      });
    }
  }

  void subscribe() {
    pb.collection("users").subscribe(pb.authStore.model.id, (value) {
      if (value.record != null) {
        setState(() {
          username = value.record!.getStringValue("username");
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pb.collection("users").unsubscribe();
  }

  Future<void> _connectSystemHealthPlatform(bool _) async {
    final result =
        await Health().requestAuthorization(types, permissions: permissions);

    if (result == true) {
      if (mounted) {
        debugPrint("Health connect permissions granted");
        await HealthTypeManager().setHealthType(HealthType.systemManaged);

        setState(() {
          //healthType = HealthType.systemManaged;
          _isRefreshing = true;
        });

        Future.delayed(const Duration(seconds: 1));

        var result = await Provider.of<HealthManager>(context, listen: false)
            .fetchHealthData(context: context);

        setState(() {
          if (result == true) healthType = HealthType.systemManaged;
          _isRefreshing = false;
        });
      } else {
        debugPrint("Not mounted");
      }
    } else {
      debugPrint("Health connect permissions not granted");
    }
  }

  Future<bool> _checkHealthPermissions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result =
          await Health().hasPermissions(types, permissions: permissions);

      if (result == true) {
        setState(() {
          _isSystemHealthAutorized = true;
        });
        return true;
      } else {
        setState(() {
          _isSystemHealthAutorized = false;
        });
        return false;
      }
    } catch (error) {
      debugPrint('Error in _checkHealthPermissions: $error');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final health = Provider.of<HealthManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [DebugPanel()],
      ),
      body: CustomScrollView(
        key: GlobalKey(debugLabel: "Settings Page"),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 5, bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Symbols.person_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Text("Your Profile", style: theme.textTheme.titleLarge)
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: buildCard(
              [
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  width: MediaQuery.of(context).size.width - 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AdvancedAvatar(
                        name: pb.authStore.model?.getStringValue("username"),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onPrimary),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        size: 50,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Logged in as $username",
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: _requestLogoutConfirmation,
                                child: const Text("Logout"),
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message: "Edit Profile",
                                child: IconButton.filled(
                                    onPressed: _openProfileEditor,
                                    tooltip: "Edit Profile",
                                    icon: Icon(
                                      Symbols.edit_rounded,
                                      color: theme.colorScheme.onPrimary,
                                    )),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 15, bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Symbols.ecg_heart_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Text("Health Data", style: theme.textTheme.titleLarge)
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isLoading
                    ? LayoutBuilder(builder: (context, constraints) {
                        final width = getWidth(constraints);
                        return SizedBox(
                          width: width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                child: LoadingBox(
                                  height: 195,
                                  width: MediaQuery.of(context).size.width,
                                  radius: 12,
                                ),
                              )
                            ],
                          ),
                        );
                      })
                    : buildCard([
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 75,
                          child: Column(children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15)
                                      .copyWith(bottom: 5),
                              child: Text(
                                _isAvailable
                                    ? (healthType != null
                                        ? "Health connected via ${HealthTypeManager.formatType(healthType)}"
                                        : "Connect a health platform")
                                    : "Health unavailable",
                                style: theme.textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (healthType == null)
                              const Text(
                                "Connect a health platform to create and join challenges",
                                textAlign: TextAlign.center,
                              )
                            else if (health.steps != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    buildDataBlock(BingoDataType.steps,
                                        health.steps!, theme),
                                    buildDataBlock(BingoDataType.calories,
                                        health.calories!, theme),
                                    buildDataBlock(BingoDataType.distance,
                                        health.distance!, theme),
                                    buildDataBlock(BingoDataType.water,
                                        health.water!, theme),
                                  ],
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.refresh_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    getErrorText(),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.error),
                                  )
                                ],
                              ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilterChip(
                                  onDeleted: healthType != null
                                      ? () {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          HealthTypeManager().clearHealthType();
                                          setState(() {
                                            _isLoading = false;
                                            healthType = null;
                                          });
                                        }
                                      : null,
                                  onSelected: (_isAvailable
                                      ? _connectSystemHealthPlatform
                                      : null),
                                  label: Text(health.capabilities
                                          .contains(HealthType.systemManaged)
                                      ? ((health.isConnected &&
                                              healthType ==
                                                  HealthType.systemManaged)
                                          ? "Connected"
                                          : HealthTypeManager.formatType(
                                              HealthType.systemManaged))
                                      : "Unavailable"),
                                  selected:
                                      healthType == HealthType.systemManaged,
                                  avatar: _isSysHealthLoading &&
                                          health.capabilities.contains(
                                              HealthType.systemManaged)
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 3,
                                          strokeCap: StrokeCap.round,
                                        )
                                      : null,
                                  showCheckmark: !_isSysHealthLoading,
                                ),
                                const SizedBox(width: 5),
                                Tooltip(
                                  message: "Sync",
                                  child: IconButton.outlined(
                                      onPressed: () async {
                                        setState(() {
                                          _isRefreshing = true;
                                        });
                                        await health.fetchHealthData();
                                        await health.checkConnectionState();
                                        setState(() {
                                          _isRefreshing = false;
                                        });
                                      },
                                      icon: _isRefreshing
                                          ? const SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                strokeCap: StrokeCap.round,
                                              ),
                                            )
                                          : Icon(
                                              Symbols.refresh_rounded,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            )),
                                )
                              ],
                            )
                          ]),
                        )
                      ], height: 195, widthFactor: 0.88),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 15, bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Symbols.visibility_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Text("Privacy", style: theme.textTheme.titleLarge),
                  const NewTag()
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const PrivacyControls(),
            ),
          )),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDataBlock(BingoDataType type, num amount, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      // Minimal padding
      margin: const EdgeInsets.all(2),
      // Minimal margin
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: theme.colorScheme.surfaceContainerHighest,
            width: 1.1,
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignCenter,
          )),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Minimize row size
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            type.asIcon(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4), // Smaller space between icon and text
          Text(
            "${formatNumber(amount)} ${type.asString()}",
            textAlign: TextAlign.center, // Center the text
          ),
        ],
      ),
    );
  }

  String getErrorText() {
    if (!_isSystemHealthAutorized && healthType == HealthType.systemManaged) {
      return "Permissions not granted";
    } else {
      return "Not synced";
    }
  }

  double getWidth(BoxConstraints constraints) {
    if (constraints.maxWidth < 500) {
      return constraints.maxWidth - 10; // Fill the width on phones with margin
    } else {
      return 500; // Limit to ~200 on larger devices
    }
  }

  Widget buildCard(List<Widget> children,
      {double? height, num widthFactor = 0.8}) {
    return LayoutBuilder(builder: (context, constraints) {
      final width =
          constraints.maxWidth * widthFactor; // Calculate adaptive width
      final theme = Theme.of(context);

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints:
              BoxConstraints(minHeight: height ?? 0.0, maxWidth: width),
          width: width,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
                width: 1.1,
                style: BorderStyle.solid,
                strokeAlign: BorderSide.strokeAlignCenter,
              )),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              // Align content to the left
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      );
    });
  }

  void _openProfileEditor() {
    final pb = Provider.of<PocketBase>(context, listen: false);
    showDialog(
            context: context,
            builder: (context) => ProfileDialog(pb: pb),
            useSafeArea: false)
        .then((_) => {
              setState(() {
                username = (pb.authStore.model as RecordModel)
                    .getStringValue("username");
              })
            });
  }

  void _requestLogoutConfirmation() {
    final pb = Provider.of<PocketBase>(context, listen: false);
    showDialog(
        context: context,
        builder: (context) => ConfirmDialog(
              isDestructive: true,
              icon: Icons.logout,
              title: "Logout",
              description: "Are you sure you want to logout?",
              onConfirm: () async {
                pb.authStore.clear();
                context.go("/introduction");
              },
            ),
        useSafeArea: false);
  }
}
