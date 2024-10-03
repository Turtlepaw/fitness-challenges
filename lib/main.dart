import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fitness_challenges/components/bottomSheet.dart';
import 'package:fitness_challenges/components/challenge.dart';
import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/components/navBar.dart';
import 'package:fitness_challenges/pb.dart';
import 'package:fitness_challenges/routes/create.dart';
import 'package:fitness_challenges/routes/join.dart';
import 'package:fitness_challenges/routes/settings.dart';
import 'package:fitness_challenges/routes/splash.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/health.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:fitness_challenges/utils/wearManager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:relative_time/relative_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'login.dart';

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
    transitionDuration: Duration(milliseconds: 150),
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

final _router =
    GoRouter(initialLocation: '/', navigatorKey: _rootNavigatorKey, routes: [
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
                context.go('/login');
              }
            }
          })
      /*FlutterSplashScreen.fadeIn(
            backgroundColor: Theme.of(context).colorScheme.surface,
            childWidget: SizedBox(
              height: 250,
              width: 250,
              child: Icon(
                Symbols.rocket_launch_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 1000,
              ),
            ),
            asyncNavigationCallback: () async {
              var pb = Provider.of<PocketBase>(context, listen: false);
              await Future.delayed(const Duration(seconds: 100));
              if (context.mounted) {
                if (pb.authStore.isValid) {
                  // User is logged in, navigate to home
                  context.go('/home');
                } else {
                  // User is not logged in, navigate to login
                  context.go('/login');
                }
              }
            }),*/
      ),
  GoRoute(
    path: '/login',
    pageBuilder: defaultPageBuilder(const LoginPage()),
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
      )
    ],
  )
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
    try {
      print("Native called background task: $task");

      print("Syncing...");
      final pb = await initializePocketbase();
      if (!pb.authStore.isValid) return Future.value(false);
      final manager = ChallengeProvider(pb: pb);
      final healthManager = HealthManager(manager, pb);
      await manager.init();
      await Health().configure(useHealthConnectIfAvailable: true);
      await healthManager.checkConnectionState();
      await healthManager.fetchHealthData();
      print("Sync complete, ${healthManager.steps}");

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

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (var challenge in manager.challenges) {
        var storedRankingState = prefs.getInt(challenge.id);
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
          print(currentPosition);

          // -1 = ended
          if (challenge.getBoolValue("ended") &&
    storedRankingState != null &&
    storedRankingState != -1) {
  await flutterLocalNotificationsPlugin.show(
      challenge.id.hashCode,
      "Challenge complete! ✨",
      "See how you finished ${challenge.getStringValue("name")} (${storedRankingState})",
      notificationDetails,
      payload: challenge.id);

  // Set to -1 to mark the user as notified about the challenge end
  currentPosition = -1;
  prefs.setInt(challenge.id, currentPosition); // Update right after notification
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

          prefs.setInt(challenge.id, currentPosition);
        }
      }

      print("Notification sent"); //simpleTask will be emitted here.
      return Future.value(true);
    } catch (err, stackTrace) {
      print(err);
      debugPrintStack(stackTrace: stackTrace);
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pb = await initializePocketbase();
  final manager = ChallengeProvider(pb: pb);
  final healthManager = HealthManager(manager, pb);
  manager.init();
  healthManager.checkConnectionState();
  //healthManager.fetchHealthData();
  Health().configure(useHealthConnectIfAvailable: true);
  final wearManager = WearManager(pb).sendAuthentication();

  // Background work
  if (kDebugMode) {
    Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode: true);
  } else {
    Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
    );
  }

  Workmanager().registerPeriodicTask("background-sync", "BackgroundSync",
      frequency: const Duration(hours: 1));
  print("registered bg work");
  if (pb.authStore.isValid)
    Workmanager().registerOneOffTask(
        "background-sync-one-time", "BackgroundSyncOneTime");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => manager),
        Provider<PocketBase>.value(
          value: pb,
        ),
        ChangeNotifierProvider.value(
          value: healthManager,
        )
      ],
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.deepPurple, brightness: Brightness.dark);

  late bool isLoggedIn; // Track login status locally
  late PocketBase pb;
  String? subscribedId;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    isLoggedIn = pb.authStore.isValid; // Initialize with current status

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
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          RelativeTimeLocalizations.delegate
        ],
        supportedLocales: [
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
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
          iconTheme: const IconThemeData(
              color: Colors.white, fill: 1, weight: 400, opticalSize: 24),
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
    pb = Provider.of<PocketBase>(context, listen: false);
  }

  void _showBottomSheet(BuildContext context) {
    showFlexibleBottomSheet(
        minHeight: 0,
        initHeight: 0.2,
        maxHeight: 0.3,
        useRootScaffold: true,
        useRootNavigator: true,
        context: context,
        builder: _buildBottomSheet,
        anchors: [0, 0.2],
        isSafeArea: true,
        bottomSheetBorderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ));
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
    showDialog(
      context: context,
      builder: (context) => JoinDialog(pb: pb),
    );
  }

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final challengeProvider =
        Provider.of<ChallengeProvider>(context, listen: true);
    final mediaQuery = MediaQuery.of(context);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.

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
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text("No challenges...")],
                ),
              ),
            const SizedBox(height: 25)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(context),
        tooltip: 'Create or join',
        child: Icon(
          Symbols.add,
          size: 30,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
    return BottomSheetBuilder(scrollController: scrollController, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Card.filled(
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      _showCreateModal(context);
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Symbols.draw_rounded,
                                size: 30,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  "Create a challenge",
                                  style: theme.textTheme.titleLarge,
                                ),
                              )
                            ],
                          ),
                        )),
                  )),
              Card.filled(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    _showJoinModal(context);
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Symbols.group_add_rounded,
                              size: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Text(
                                "Join a challenge",
                                style: theme.textTheme.titleLarge,
                              ),
                            )
                          ],
                        ),
                      )),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await challengeProvider.reloadChallenges(context);
                  var nav = Navigator.of(context);
                  nav.pop();
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
          ))
    ]);
  }
}
