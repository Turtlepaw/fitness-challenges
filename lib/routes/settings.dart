import 'package:fitness_challenges/constants.dart';
import 'package:fitness_challenges/routes/profile.dart';
import 'package:fitness_challenges/utils/common.dart';
import 'package:fitness_challenges/utils/health.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../components/challenges/confirmDialog.dart';
import '../components/debug_panel.dart';
import '../components/loader.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _isSystemHealthAutorized = false;
  bool _isWatchLoading = false;
  bool _isSysHealthLoading = false;
  bool _isRefreshing = false;
  late String username;
  late PocketBase pb;
  late HealthType? healthType;

  final FlutterWearOsConnectivity _flutterWearOsConnectivity =
      FlutterWearOsConnectivity();

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

  void _getHealthType() async {
    var type = await HealthTypeManager().getHealthType();

    setState(() {
      healthType = type;
    });
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
    await Health().requestAuthorization(types,
        permissions: [HealthDataAccess.READ, HealthDataAccess.READ]);

    final result = await _checkHealthPermissions();

    if (result == true) {
      if (mounted) {
        debugPrint("Health connect permissions granted");
        HealthTypeManager().setHealthType(HealthType.systemManaged);

        await Provider.of<HealthManager>(context, listen: false)
            .fetchHealthData(context: context);

        setState(() {
          healthType = HealthType.systemManaged;
        });
      }
    } else {
      debugPrint("Health connect permissions not granted");
    }
  }

  Future<bool> _checkHealthPermissions() async {
    setState(() {
      _isLoading = true;
    });

    if (mounted) {
      final p = Provider.of<HealthManager>(context, listen: false);
      p.fetchHealthData();
      p.checkConnectionState();
    } else {
      debugPrint("not mounted");
    }

    try {
      await Future.delayed(const Duration(seconds: 2));
      final result = await Health().hasPermissions(types);

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
      // Handle error
      debugPrint(error.toString());

      if (error is MissingPluginException) {
        setState(() {
          _isAvailable = false;
        });
      }

      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _connectWearOS() async {
    setState(() {
      _isWatchLoading = true;
    });

    await _flutterWearOsConnectivity.configureWearableAPI();

    List<DataItem> allDataItems =
        await _flutterWearOsConnectivity.getAllDataItems();
    debugPrint(allDataItems.map((e) => e.mapData).join(","));
    if (mounted) {
      Provider.of<HealthManager>(context, listen: false)
          .fetchHealthData(context: context);
    }

    HealthTypeManager().setHealthType(HealthType.watch);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      healthType = HealthType.watch;
      _isWatchLoading = false;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pb = Provider.of<PocketBase>(context, listen: false);
    final theme = Theme.of(context);
    final health = Provider.of<HealthManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [
          DebugPanel()
        ],
      ),
      body: ListView(
        children: [
          buildCard(
            [
              Row(
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
                  const SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Logged in as $username",
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: _requestLogoutConfirmation,
                            child: const Text("Logout"),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                              onPressed: _openProfileEditor,
                              tooltip: "Edit Profile",
                              icon: Icon(
                                Symbols.edit_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                              )),
                          // IconButton.filledTonal(
                          //     onPressed: _openProfileEditor,
                          //     tooltip: "Delete Account",
                          //     icon: Icon(
                          //       Symbols.delete_forever_rounded,
                          //       color: theme.colorScheme.onPrimaryContainer,
                          //     ))
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            flex: 0,
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
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.steps_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text("${formatNumber(health.steps as int)} steps")
                          ],
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
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: theme.colorScheme.error),
                            )
                          ],
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterChip(
                            onSelected: (_isAvailable
                                ? _connectSystemHealthPlatform
                                : null),
                            label: Text(health.capabilities
                                    .contains(HealthType.systemManaged)
                                ? ((health.isConnected &&
                                        healthType == HealthType.systemManaged)
                                    ? "Connected"
                                    : HealthTypeManager.formatType(
                                        HealthType.systemManaged))
                                : "Unavailable"),
                            selected: healthType == HealthType.systemManaged,
                            avatar: _isSysHealthLoading &&
                                    health.capabilities
                                        .contains(HealthType.systemManaged)
                                ? const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    strokeCap: StrokeCap.round,
                                  )
                                : null,
                            showCheckmark: !_isSysHealthLoading,
                          ),
                          // const SizedBox(
                          //   width: 10,
                          // ),
                          // FilterChip(
                          //   label: Text(
                          //       HealthTypeManager.formatType(HealthType.watch)),
                          //   onSelected:
                          //       health.capabilities.contains(HealthType.watch)
                          //           ? ((isSelected) => _connectWearOS())
                          //           : null,
                          //   selected: healthType == HealthType.watch,
                          //   avatar: _isWatchLoading &&
                          //           health.capabilities
                          //               .contains(HealthType.watch)
                          //       ? const CircularProgressIndicator(
                          //           strokeWidth: 3,
                          //           strokeCap: StrokeCap.round,
                          //         )
                          //       : null,
                          //   showCheckmark: !_isWatchLoading,
                          // ),
                          const SizedBox(
                            width: 5,
                          ),
                          IconButton.outlined(
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
                                      color: theme.colorScheme.onSurface,
                                    ))
                        ],
                      )
                    ], height: 195),
            ),
          )
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

  Widget buildCard(List<Widget> children, { double? height }) {
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
