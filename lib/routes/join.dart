import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/challengeManager.dart';
import 'package:fitness_challenges/utils/manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../utils/health.dart';

class JoinDialog extends StatefulWidget {
  final PocketBase pb;

  const JoinDialog({super.key, required this.pb});

  @override
  _JoinDialogState createState() => _JoinDialogState();
}

class _JoinDialogState extends State<JoinDialog> {
  bool _isDialogLoading = true;
  late bool _isHealthAvailable;
  bool _isJoining = false;

  // Form definition
  final form = FormGroup({
    joinCode: FormControl<String>(validators: [Validators.required, Validators.minLength(6), Validators.maxLength(6)]),
  });

  @override
  void initState() {
    super.initState();
    _checkHealthPlugin();
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
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Join Challenge",
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                        "Join a challenge using a code.",
                        style: theme.textTheme.bodyLarge,
                      )
                ),
              ),
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: IconButton(
              //     icon: const Icon(Symbols.close_rounded),
              //     onPressed: () {
              //       Navigator.of(context).pop();
              //     },
              //   ),
              // ),
              if (_isDialogLoading)
                const Center(
                    child:
                        CircularProgressIndicator(strokeCap: StrokeCap.round))
              else
                _isHealthAvailable
                    ? const JoinWidget()
                    : _buildHealthUnavailable(context),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel")),
                  const SizedBox(width: 15),
                  ReactiveFormConsumer(
                      builder: (context, form, widget) => FilledButton(
                          onPressed: form.valid
                              ? () {
                                  _handleJoin();
                                }
                              : null,
                          child: _isJoining
                              ? SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeCap: StrokeCap.round,
                                    color: theme.colorScheme.onPrimary,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text("Join")))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthUnavailable(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_circle_rounded,
              color: theme.colorScheme.error,
              size: 45,
            ),
            const SizedBox(height: 10),
            Text(
              "You must connect a health service before joining a challenge",
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            )
          ],
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

Future<bool> handleJoin(String joinCodeValue, PocketBase pb, BuildContext context) async {
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
        final data =
        Manager.fromData(joinData['data'], type).addUser(userId);

        await pb
            .collection(Collection.challenges)
            .update(joinData['id'], body: {'data': data.toJson()});
      }else {
        debugPrint("Failed to add user to data");
      }
    } else {
      // the user data already exists
      // we don't need to create a entry
      debugPrint("User data already exists, skipping Manager#addUser");
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
      debugPrint('Error: $error');
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

class JoinWidget extends StatelessWidget {
  const JoinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextFields(theme)
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
