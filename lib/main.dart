   import 'package:app_links/app_links.dart';
import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fitness_challenges/components/bottomSheet.dart';
import 'package:fitness_challenges/components/challenge.dart';
import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/components/navBar.dart';
import 'package:fitness_challenges/pb.dart';
import 'package:fitness_challenges/routes/challenge.dart';
import 'package:fitness_challenges/routes/community.dart';
import 'package:fitness_challenges/routes/create.dart';
import 'package:fitness_challenges/routes/join.dart';
import 'package:fitness_challenges/routes/onboarding.dart';
import 'package:fitness_challenges/routes/settings.dart';
import 'package:fitness_challenges/routes/splash.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/health.dart';
import 'package:fitness_challenges/utils/sharedLogger.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:fitness_challenges/utils/wearManager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:relative_time/relative_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import 'routes/login.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Page<dynamic> Function(BuildContext, GoRouterState) defaultPageBuilder<T>(
        Widget child) =>
    (BuildContext context, GoRouterState state) {
      return buildPageWithDefaultTransition<T>(
        context: context,
        state: state,
        child: child,
      );
    };

final _router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final pb = Provider.of<PocketBase>(context, listen: false);
      final isLoggedIn = pb.authStore.isValid;
      // Prevent logged in users from accessing onboarding
      if (isLoggedIn && state.fullPath == '/introduction') {
        return '/home';
      }
      // Prevent non-authenticated users from accessing home
      if (!isLoggedIn && state.fullPath == '/home') {
        return '/introduction';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => SplashScreen(asyncFunction: () async {
                if (context.mounted) {
                  var pb = Provider.of<PocketBase>(context, listen: false);

                  if (pb.authStore.isValid) {
                    // User is logged in, navigate to home
                    context.go('/home');
                  } else {
                    // User is not logged in, navigate to login
                    context.go('/introduction');
                  }
                }
              })
          ),
      GoRoute(
        path: '/login',
        pageBuilder: defaultPageBuilder(const LoginPage()),
      ),
      GoRoute(
        path: '/introduction',
        pageBuilder: defaultPageBuilder(const Onboarding()),
      ),
      GoRoute(
          path: '/challenge/:id',
          pageBuilder: (context, state) {
            return defaultPageBuilder(
                    ChallengeDialog(challenge: state.pathParameters['id']!))(
                context, state);
          }),
      GoRoute(
        path: '/invite',
        pageBuilder: (context, state) {
          return defaultPageBuilder(JoinDialog(
                  pb: Provider.of<PocketBase>(context, listen: false)))(
              context, state);
        },
      ),
      GoRoute(
        path: '/invite/:id',
        onExit: (context, state) {
          context.go('/home');
          return true;
        },
        pageBuilder: (context, state) {
          return defaultPageBuilder(JoinDialog(
            pb: Provider.of<PocketBase>(context, listen: false),
            inviteCode: state.pathParameters['id'],
          ))(context, state);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
              child: Scaffold(
            bottomNavigationBar: CustomNavigationBar(state: state),
            body: child,
          ));
        },
        routes: [
          GoRoute(
              pageBuilder: defaultPageBuilder(const HomePage(title: "Home")),
              path: '/home'),
          GoRoute(
            path: '/settings',
            pageBuilder: defaultPageBuilder(const SettingsPage()),
          ),
          GoRoute(
            path: '/community',
            pageBuilder: defaultPageBuilder(const CommunityPage()),
          ),
        ],
      ),

    ]);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = SharedLogger();
    try {
      logger.debug("Native called background task: $task");
      logger.debug("Syncing...");

      final pb = await initializePocketbase();
      if (!pb.authStore.isValid) return Future.value(false);
      final type = await HealthTypeManager().getHealthType();
      if (type == null) {
        logger.debug("Health type not set, canceling work");
        return Future.value(false);
      }

      final manager = ChallengeProvider(pb: pb);
      final healthManager = HealthManager(manager, pb, logger: logger);
      await manager.init();
      await Health().configure();
      await healthManager.checkConnectionState();
      await healthManager.fetchHealthData();
      logger.debug("Sync complete, ${healthManager.steps}");

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notif');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: notificationTapBackground);

      // Show notification
      // We just need to show syncing notifications
      // and specialized
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('challenge_updates', 'Challenge Updates',
              channelDescription: 'Receive updates to your joined challenges',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority);
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      final prefs = SharedPreferencesAsync();
      for (var challenge in manager.challenges) {
        var storedRankingState = await prefs.getInt(challenge.id);
        if (challenge.getIntValue("type") == 1) {
          final jsonMap = challenge.getDataValue<Map<String, dynamic>>("data");
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
          userTotals.sort((a, b) =>
              (b['totalValue'] as int).compareTo(a['totalValue'] as int));

          int getUserPosition() {
            for (int i = 0; i < userTotals.length; i++) {
              if (userTotals[i]['userId'] == pb.authStore.model.id) {
                return i + 1;
              }
            }
            return -2;
          }

          var currentPosition = getUserPosition();
          if (currentPosition == -2) continue;

          bool isTop = currentPosition == 1; // Assuming top position is rank 1
          logger.debug("Current position: $currentPosition");

          // 0 or -1 = ended
          if (storedRankingState != null && storedRankingState == 0) {
            debugPrint(
                "Challenge ended and notification already sent, no action needed");
            return Future.value(true);
          } else if (challenge.getBoolValue("ended") &&
              storedRankingState != null &&
              storedRankingState != 0) {
            await flutterLocalNotificationsPlugin.show(
                challenge.id.hashCode,
                "Challenge complete! ✨",
                "See how you finished ${challenge.getStringValue("name")} (${storedRankingState})",
                notificationDetails,
                payload: challenge.id);

            // Set to 0 to mark the user as notified about the challenge end
            currentPosition = 0;
            await prefs.setInt(
                challenge.id, 0); // Update right after notification
          } else if (isTop &&
              (storedRankingState == null || storedRankingState > 1)) {
            // User reached the top
            await flutterLocalNotificationsPlugin.show(
                challenge.id.hashCode,
                "You're first! 🏆",
                "You're at the top of ${challenge.getStringValue("name")}",
                notificationDetails,
                payload: challenge.id);
          } else if (!isTop &&
              storedRankingState != null &&
              storedRankingState == 1) {
            await flutterLocalNotificationsPlugin.show(
                challenge.id.hashCode,
                "Keep going! 🔥",
                "You're not longer at the top of ${challenge.getStringValue("name")}",
                notificationDetails,
                payload: challenge.id);
          }

          await prefs.setInt(challenge.id, currentPosition);
        }
      }

      logger.debug("Notification sent"); //simpleTask will be emitted here.
      return Future.value(true);
    } catch (err, stackTrace) {
      logger.error(err.toString());
      debugPrintStack(stackTrace: stackTrace);
      return Future.value(false);
    }
  });
}

void checkLaunchIntent() async {
  final receivedIntent = await ReceiveIntent.getInitialIntent();

  if (receivedIntent != null &&
      receivedIntent.action == 'android.intent.action.VIEW_PERMISSION_USAGE') {
    launchUrl(Uri.parse(
        "https://gist.github.com/Turtlepaw/e14d65c181a071b4facfc1aef323b2d4"));
  } else {
    // App was launched normally
    print('Launched normally');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //GoogleFonts.config.allowRuntimeFetching = false;
  final logger = SharedLogger();
  final pb = await initializePocketbase();
  final manager = ChallengeProvider(pb: pb);
  final healthManager = HealthManager(manager, pb, logger: logger);
  manager.init();
  healthManager.checkConnectionState();
  Future.delayed(const Duration(seconds: 1), () {
    healthManager.fetchHealthData();
  });
  Health().configure();
  final wearManager = WearManager(pb).sendAuthentication(logger);
  checkLaunchIntent();

  // Background work
  if (kDebugMode) {
    Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode: true);
    Workmanager().registerOneOffTask("single-sync", "BackgroundSingleSync");
  } else {
    Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
    );
  }

  Workmanager().registerPeriodicTask("background-sync", "BackgroundSync",
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 15));
  logger.debug("Background sync registered");
  if (pb.authStore.isValid) {
    Workmanager().registerOneOffTask(
        "background-sync-one-time", "BackgroundSyncOneTime");
  }

  debugPrint = (String? message, {int? wrapWidth}) {
    logger.debug(message ?? "#debugPrint called with no message");
    print(message); // Redirect to print in release mode
  };

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => manager),
        Provider<PocketBase>.value(
          value: pb,
        ),
        ChangeNotifierProvider.value(
          value: healthManager,
        ),
        Provider<SharedLogger>.value(
          value: logger,
        )
      ],
      child: const App(),
    ),
  );

  // Detect the system brightness (light or dark)
  final Brightness brightness =
      WidgetsBinding.instance.window.platformBrightness;

  // Set the system overlay based on brightness
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    statusBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
  ));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static final _color = Color(0xff15a4bc);
  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: _color);

  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: _color, brightness: Brightness.dark);

  late bool isLoggedIn; // Track login status locally
  late PocketBase pb;
  String? subscribedId;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    isLoggedIn = pb.authStore.isValid; // Initialize with current status

    final appLinks = AppLinks(); // AppLinks is singleton

    final sub = appLinks.uriLinkStream.listen((uri) {
      if (uri != null && uri.path == '/dialog') {
        if (uri != null && uri.pathSegments.isNotEmpty) {
          if (uri.pathSegments[0] == 'invite' && uri.pathSegments.length > 1) {
            showDialog(
              context: context,
              builder: (context) =>
                  JoinDialog(pb: pb, inviteCode: uri.pathSegments[1]),
            );
          }
        }
      }
    });

    if (isLoggedIn) {
      subscribeUserData();
      pb.collection("users").authRefresh();

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Listen for changes in auth status
    pb.authStore.onChange.listen((e) {
      if (pb.authStore.isValid) {
        subscribeUserData();
      } else if (subscribedId != null) {
        pb.collection("users").unsubscribe(subscribedId!);
      }

      // Check if the widget is still mounted
      if (mounted) {
        setState(() {
          isLoggedIn = pb.authStore.isValid; // Update isLoggedIn
        });
      }
    });
  }

  /// Enables realtime updates to user data.
  void subscribeUserData() {
    if (!pb.authStore.isValid) return;
    var id = pb.authStore.model.id;
    pb.collection("users").subscribe(id, (data) {
      if (data.record?.id == id) {
        pb.authStore.save(pb.authStore.token, data.record);
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp.router(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          RelativeTimeLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('es'), // Spanish
        ],
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        title: 'Fitness Challenges',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
          iconTheme: const IconThemeData(
              color: Colors.black, fill: 1, weight: 400, opticalSize: 24),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
          iconTheme: const IconThemeData(
            color: Colors.white,
            fill: 1,
            weight: 400,
            opticalSize: 24,
          ),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            bodyColor: (darkColorScheme ?? _defaultDarkColorScheme).onSurface,
            displayColor:
                (darkColorScheme ?? _defaultDarkColorScheme).onSurface,
          ),
        ),
        themeMode: ThemeMode.system,
      );
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _counter = 0;
  late PocketBase pb;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
  }

  void _showCreateModal(BuildContext context) {
    var nav = Navigator.of(context);
    nav.pop();
    showDialog(
        context: context,
        builder: (context) => CreateDialog(pb: pb),
        useSafeArea: false);
  }

  void _showJoinModal(BuildContext context) {
    var nav = Navigator.of(context);
    nav.pop();
    context.push('/invite');
    // showDialog(
    //   context: context,
    //   builder: (context) => JoinDialog(pb: pb),
    // );
  }

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final challengeProvider =
        Provider.of<ChallengeProvider>(context, listen: true);
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            if (challengeProvider.isLoading)
              ...List.generate(3, (index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: LoadingBox(
                      width: mediaQuery.size.width - 30, height: 150),
                );
              })
            else if (challengeProvider.challenges.isNotEmpty)
              ...challengeProvider.challenges.map((value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Challenge(challenge: value, pb: pb),
                );
              })
            else
              Center(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 30),
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHigh,
                      width: 1.1,
                      style: BorderStyle.solid,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    )),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.travel_explore_rounded,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 15),
                    Text("You aren't in any challenges yet.",
                        style: theme.textTheme.titleLarge),
                    Text("Create or join a challenge to get started.",
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 5),
                    FilledButton.tonalIcon(
                      onPressed: () => _showBottomSheet(context),
                      icon: const Icon(Symbols.stylus_note_rounded),
                      label: const Text("Create or join"),
                    )
                  ],
                ),
              )),
            const SizedBox(height: 25)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // haptic vibrations
          HapticFeedback.lightImpact();
          _showBottomSheet(context);
        },
        tooltip: 'Create or join',
        child: Icon(
          Symbols.add,
          size: 30,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _showBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Increase the base content height estimation
    final contentHeight =
        230.0; // Increased from 180 to account for all content + safe margins

    // Calculate the initial height ratio based on content, with a higher minimum
    final initHeight = (contentHeight / screenHeight).clamp(0.25, 0.4);

    showFlexibleBottomSheet(
      minHeight: 0,
      initHeight: initHeight,
      maxHeight: 0.5,
      useRootScaffold: true,
      useRootNavigator: true,
      context: context,
      builder: _buildBottomSheet,
      anchors: [0, initHeight],
      isSafeArea: false,
      bottomSheetColor: theme.colorScheme.surfaceContainer,
      bottomSheetBorderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    ScrollController scrollController,
    double bottomSheetOffset,
  ) {
    final challengeProvider =
        Provider.of<ChallengeProvider>(context, listen: true);
    var theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return BottomSheetBuilder(
            scrollController: scrollController,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Add this
                  children: [
                    buildSheetAction(
                        Symbols.draw_rounded, "Create a challenge", theme, () {
                      _showCreateModal(context);
                    }),
                    const SizedBox(height: 8), // Add consistent spacing
                    buildSheetAction(
                        Symbols.group_add_rounded, "Join a challenge", theme,
                        () {
                      _showJoinModal(context);
                    }),
                    const SizedBox(
                        height: 16), // Slightly larger spacing before button
                    TextButton(
                      onPressed: () async {
                        await challengeProvider.reloadChallenges(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.refresh_rounded,
                            size: 25,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Force refresh challenges",
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ]);
      },
    );
  }

  Widget buildSheetAction(
      IconData icon, String title, ThemeData theme, void Function() onPressed) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest,
          width: 1.1,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh, // Background color
        borderRadius: BorderRadius.circular(15), // Match border radius
        clipBehavior: Clip.antiAlias, // Ensure ripple is clipped
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: mediaQuery.size.width - 10,
            height: 60,
            child: Row(
              children: [
                const SizedBox(width: 30),
                Icon(
                  icon,
                  size: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
