import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/manager.dart';
import 'package:fitness_challenges/utils/sharedLogger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../components/error.dart';
import '../utils/health.dart';

class JoinDialog extends StatefulWidget {
  final PocketBase pb;
  final String? inviteCode;

  const JoinDialog({super.key, required this.pb, this.inviteCode});

  @override
  _JoinDialogState createState() => _JoinDialogState();
}

class _JoinDialogState extends State<JoinDialog> {
  bool _isDialogLoading = true;
  late bool _isHealthAvailable;
  bool _isJoining = false;

  // Form definition
  final form = FormGroup({
    joinCode: FormControl<String>(validators: [
      Validators.required,
      Validators.minLength(6),
      Validators.maxLength(6)
    ]),
  });

  @override
  void initState() {
    super.initState();
    _checkHealthPlugin();
  }

  @override
  void didChangeDependencies() {
    if (widget.inviteCode != null) {
      setState(() {
        form.control(joinCode).value = widget.inviteCode;
      });
    }
    super.didChangeDependencies();
  }

  Future<void> _checkHealthPlugin() async {
    setState(() {
      _isDialogLoading = true;
    });

    final health = Provider.of<HealthManager>(context, listen: false);
    final state = health.isConnected;
    setState(() {
      _isHealthAvailable = state;
      _isDialogLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return ReactiveForm(
      formGroup: form,
      child: Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: Tooltip(
              message: "Exit",
              child: IconButton(
                icon: const Icon(Symbols.close_rounded),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      if (_isHealthAvailable)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 5, left: 10, bottom: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Symbols.person_add_rounded),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Join a challenge",
                                    style: theme.textTheme.headlineSmall,
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Join a challenge using an invite code or link.",
                                style: theme.textTheme.bodyLarge,
                              )
                            ],
                          ),
                        ),
                      if (_isDialogLoading)
                        const Center(
                          child: CircularProgressIndicator(
                              strokeCap: StrokeCap.round),
                        )
                      else if (_isHealthAvailable)
                        const JoinWidget()
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: ErrorMessage(
                            title:
                                errorMessages[ErrorMessages.noHealthConnected]!,
                            action: (theme) => FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go("/settings");
                              },
                              child: const Text("Go to settings"),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isHealthAvailable) const SizedBox(height: 15),
                if (_isHealthAvailable)
                  SafeArea(
                      bottom: true,
                      top: false,
                      left: false,
                      right: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.tonal(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 10),
                          ReactiveFormConsumer(
                            builder: (context, form, widget) => FilledButton(
                              onPressed: form.valid
                                  ? () {
                                      _handleJoin();
                                    }
                                  : null,
                              child: _isJoining
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeCap: StrokeCap.round,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text("Join"),
                            ),
                          ),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleJoin() async {
    setState(() {
      _isJoining = true;
    });
    handleJoin(form.control(joinCode).value, widget.pb, context);
    setState(() {
      _isJoining = false;
    });
  }
}

Future<bool> handleJoin(
    String joinCodeValue, PocketBase pb, BuildContext context) async {
  final sharedLogger = Provider.of<SharedLogger>(context, listen: false);
  try {
    final joinData = await pb.send("/api/hooks/join",
        method: "POST",
        query: {"code": joinCodeValue, "id": pb.authStore.model?.id});

    // Add user to data
    final userId = pb.authStore.model?.id;
    final type = TypesExtension.of(joinData['type']);
    final dataManager = Manager.fromData(joinData['data'], type);
    if (!dataManager.data.any((value) => value.userId == userId)) {
      if (type == Types.steps || type == Types.bingo) {
        final data = Manager.fromData(joinData['data'], type).addUser(userId);

        await pb
            .collection(Collection.challenges)
            .update(joinData['id'], body: {'data': data.toJson()});
      } else {
        sharedLogger.error("Failed to add user to data");
      }
    } else {
      // the user data already exists
      // we don't need to create a entry
      sharedLogger.debug("User data already exists, skipping Manager#addUser");
    }

    if (context.mounted) {
      await Provider.of<ChallengeProvider>(context, listen: false)
          .reloadChallenges(context);

      await Provider.of<HealthManager>(context, listen: false)
          .fetchHealthData(context: context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined challenge'),
        ),
      );
      Navigator.of(context).pop();
    }

    return true;
  } catch (error, stackTrace) {
    if (kDebugMode) {
      sharedLogger.error('Error: $error, ($stackTrace)');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (context.mounted) {
      var message = "Failed to join challenge";
      if (error is ClientException) {
        message = error.response['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }

    return false;
  }
}

const joinCode = "join_code";

final errors = {"join_code": "Join code"};

class JoinWidget extends StatelessWidget {
  const JoinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final highlighted = theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.9),
        //color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500);
    final defaultText = theme.textTheme.bodyLarge
        ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75));

    return Column(
      children: [
        _buildTextFields(theme),
        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Symbols.info_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 20),
              Flexible(
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: "Invite codes should look like ",
                        style: defaultText),
                    TextSpan(
                        text:
                            'https://fitnesschallenges.vercel.app/invite/THDRD5',
                        style: highlighted),
                    TextSpan(text: " or ", style: defaultText),
                    TextSpan(text: 'THDRD5', style: highlighted)
                  ]),
                ),
              )
            ],
          ),
        ),
        ReactiveFormConsumer(
          builder: (context, form, w) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              // Animation duration
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.05),
                      // Slight upward start
                      end: Offset.zero, // Final position
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: form.errors.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20)
                          .add(const EdgeInsets.only(top: 15)),
                      child: Row(
                        children: [
                          Icon(Symbols.warning_rounded,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 20),
                          Flexible(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "${form.errors.length} error${form.errors.length > 1 ? "s" : ""}: ",
                                    style: defaultText?.copyWith(
                                        color: theme.colorScheme.error),
                                  ),
                                  ...form.errors.keys
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    print(form.errors);
                                    int index = entry.key;
                                    String error = entry.value;
                                    return TextSpan(
                                      children: [
                                        TextSpan(
                                          text: error.replaceAll("_", " "),
                                          style: highlighted,
                                        ),
                                        if (index < form.errors.keys.length - 1)
                                          TextSpan(
                                            text: ", ",
                                            style: defaultText,
                                          ),
                                      ],
                                    );
                                  }).expand((span) => span.children ?? []),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : const SizedBox()),
        ),
        //FilledButton(onPressed: (){}, child: Text("Create"))
      ],
    );
  }

  Widget _buildTextFields(ThemeData theme) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return ConstraintsTransformBox(
          constraintsTransform: (constraints) => BoxConstraints(
                maxWidth:
                    constraints.maxWidth > 450 ? 400 : constraints.maxWidth,
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ReactiveTextField(
                  formControlName: joinCode,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Code',
                    icon: Icon(Symbols.passkey_rounded),
                  ),
                )
              ],
            ),
          ));
    });
  }
}
