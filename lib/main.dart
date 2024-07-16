import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fitness_challenges/components/bottomSheet.dart';
import 'package:fitness_challenges/create.dart';
import 'package:fitness_challenges/login.dart';
import 'package:fitness_challenges/pb.dart';
import 'package:fitness_challenges/states/user.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pb = await initializePocketbase();

  runApp(
    Provider<PocketBase>.value(
      value: pb,
      child: ChangeNotifierProvider(
        // Add ChangeNotifierProvider here
        create: (context) => UserModel(),
        child: const App(),
      ),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  // ...@override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  late bool isLoggedIn; // Track login status locally
  late PocketBase pb;

  @override
  void initState() {
    super.initState();
    pb = Provider.of<PocketBase>(context, listen: false);
    isLoggedIn = pb.authStore.isValid; // Initialize with current status

    // Listen for changes in auth status
    pb.authStore.onChange.listen((e) {
      setState(() {
        isLoggedIn = pb.authStore.isValid; // Update isLoggedIn
      });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
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
        home: Builder(
          builder: (context) => isLoggedIn
              ? MyHomePage(title: 'Home', pb: pb) // If isLoggedIn is true
              : LoginPage(pb: pb), // If isLoggedIn is false
        ),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.pb});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final PocketBase pb;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _showBottomSheet() {
    showFlexibleBottomSheet(
      minHeight: 0,
      initHeight: 0.3,
      maxHeight: 0.4,
      context: context,
      builder: _buildBottomSheet,
      anchors: [0, 0.3],
      isSafeArea: true,
      bottomSheetBorderRadius: const BorderRadius.all(
        Radius.circular(20),
      ),
    );
  }

  void _showCreateModal(BuildContext context) {
    var nav = Navigator.of(context);
    nav.pop();
    nav.push(TutorialOverlay());
  }

  @override
  Widget build(BuildContext context) {
    PocketBase pb = widget.pb;
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton.tonal(
                onPressed: () {
                  pb.authStore.clear();
                },
                child: const Text("Logout")),
            Text(
                "Logged in as ${pb.authStore.model?.getDataValue("username")}"),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
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
    var theme = Theme.of(context);
    return BottomSheetBuilder(scrollController: scrollController, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showCreateModal(context),
                child: Card.filled(
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
                                style: theme.typography.englishLike.titleLarge,
                              ),
                            )
                          ],
                        ),
                      )),
                ),
              ),
              Card.filled(
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
                              style: theme.typography.englishLike.titleLarge,
                            ),
                          )
                        ],
                      ),
                    )),
              ),
            ],
          ))
    ]);
  }
}
