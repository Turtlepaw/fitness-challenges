import 'package:fitness_challenges/manager.dart';
import 'package:fitness_challenges/types/challenges.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:fitness_challenges/utils/manager.dart';
import 'package:fitness_challenges/utils/steps/data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../constants.dart';

class JoinDialog extends StatefulWidget {
  final PocketBase pb;

  const JoinDialog({super.key, required this.pb});

  @override
  _JoinDialogState createState() => _JoinDialogState();
}

class _JoinDialogState extends State<JoinDialog> {
  bool _isDialogLoading = true;
  bool _isHealthAvailable = true;
  bool _isJoining = false;

  // Form definition
  final form = FormGroup({
    joinCode: FormControl<String>(validators: [Validators.required]),
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

    try {
      final result = await Health().hasPermissions(types);
      if (result == false) {
        setState(() {
          _isHealthAvailable = false;
        });
      }
    } catch (error) {
      if (error is MissingPluginException) {
        setState(() {
          _isHealthAvailable = false;
        });
      }
    } finally {
      setState(() {
        _isDialogLoading = false;
      });
    }
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
                      child: Text("Cancel")),
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
              Symbols.error_circle_rounded_error_rounded,
              color: theme.colorScheme.error,
              size: 45,
            ),
            const SizedBox(height: 10),
            Text(
              "You must connect a health service before joining a challenge",
              style: theme.typography.englishLike.titleLarge,
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
    try {
      String joinCodeValue = form.control(joinCode).value;

      final joinData = await widget.pb.send("/api/hooks/join",
          method: "POST",
          query: {"code": joinCodeValue, "id": widget.pb.authStore.model?.id});

      // Add user to data
      final userId = widget.pb.authStore.model?.id;
      final type = TypesExtension.of(joinData['type']);
      final dataManager = Manager.fromData(joinData['data'], type);
      if (!dataManager.data.any((value) => value.userId == userId)) {
        if (type == Types.steps) {
          final data =
              StepsDataManager.fromJson(joinData['data']).addUser(userId);

          await widget.pb
              .collection(Collection.challenges)
              .update(joinData['id'], body: {'data': data.toJson()});
        } else {
          debugPrint("Failed to add user to data");
        }
      } else {
        // the user data already exists
        // we don't need to create a entry
        debugPrint("User data already exists, skipping Manager#addUser");
      }

      if (mounted) {
        Provider.of<ChallengeProvider>(context, listen: false)
            .reloadChallenges(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined challenge'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (mounted) {
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
      setState(() {
        _isJoining = false;
      });
    }
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