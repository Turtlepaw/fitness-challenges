import 'package:fitness_challenges/components/loader.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

const password = "password";
const username = "username";

class LoginPage extends StatefulWidget {
  final PocketBase pb;

  const LoginPage({super.key, required this.pb});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showUsernameForm = false;
  bool isLoading = false;

  Future<void> _setLoading([bool state = true]) async {
    setState(() {
      isLoading = state;
    });
  }

  Future<void> _signInWithGoogle() async {
    _setLoading();
    try {
      await widget.pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          await launchUrl(url);
        },
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in!'),
          ),
        );
      }

      _setLoading(false);
    } catch (e) {
      print('Error doing OAuth2 URL: $e');
      _setLoading(false);
    }
  }

  Future<void> _signInWithUsername(String username, String password) async {
    _setLoading();
    try {
      await widget.pb.collection('users').authWithPassword(username, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in!'),
          ),
        );
      }

      _setLoading(false);
    } catch (e) {
      print('Error doing OAuth2 URL:$e');
      try {
        await widget.pb.collection('users').create(body: {
          'username': username,
          'password': password,
          'passwordConfirm': password
        });

        await widget.pb
            .collection('users')
            .authWithPassword(username, password);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created'),
            ),
          );
        }

        _setLoading(false);
      } catch (createError) {
        print('Error creating user: $createError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error creating account. Please try again.'),
            ),
          );
          _setLoading(false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double width = (screenWidth < 400 ? 250 : 400).toDouble();
    final usernameValidator = UsernameValidator(pb: widget.pb);
    final form = FormGroup({
      username: FormControl<String>(
          asyncValidators: [usernameValidator],
          validators: [Validators.required],
          value: ''),
      password:
          FormControl<String>(validators: [Validators.required], value: ''),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: ReactiveForm(
        formGroup: form,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: showUsernameForm
                    ? _UsernameForm(
                        width: width,
                        form: form,
                        isLoading: isLoading,
                        onSignIn: _signInWithUsername,
                        onBack: () {
                          setState(() {
                            showUsernameForm = false;
                          });
                        })
                    : _buildSignInButtons(width, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameForm(double width, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: width,
          child: Column(
            children: [
              // ReactiveTextField(
              //   formControlName: username,
              //   onSubmitted: (v) => form.focus(password),
              //   decoration: const InputDecoration(
              //     border: OutlineInputBorder(),
              //     labelText: 'Username',
              //     icon: Icon(Symbols.person_rounded),
              //   ),
              //   validationMessages: {
              //     ValidationMessage.required: (error) =>
              //         "Username must not be empty",
              //     "unique": (error) => "Username taken"
              //   },
              // ),
              // const SizedBox(height: 10),
              ReactiveTextField(
                formControlName: password,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  icon: Icon(Symbols.password_rounded),
                  hintText: 'Choose a strong password',
                ),
                validationMessages: {
                  ValidationMessage.required: (error) =>
                      "Password must not be empty",
                },
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your details to sign in or create a new account.",
                style: theme.typography.englishLike.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ReactiveFormConsumer(builder: (context, form, child) {
                return SizedBox(
                  width: width,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(),
                    onPressed: form.valid
                        ? () {
                            _signInWithUsername(
                              form.control("username").value,
                              form.control("password").value,
                            );
                          }
                        : null,
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeCap: StrokeCap.round,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: theme.typography.englishLike.titleMedium
                                ?.copyWith(
                              color: form.valid
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.38),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                );
              })
            ],
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () {
            setState(() {
              showUsernameForm = false;
            });
          },
          child: const Text('Back to Sign In Options'),
        ),
      ],
    );
  }

  Widget _buildSignInButtons(double width, ThemeData theme) {
    return KeyedSubtree(
      key: const ValueKey<bool>(false),
      child: Column(
        children: [
          Text(
            "Welcome",
            style: Theme.of(context).typography.englishLike.headlineMedium,
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "Start competing with friends and family.",
              style: Theme.of(context).typography.englishLike.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: width,
            child: ReactiveTextField(
              formControlName: username,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
                icon: Icon(Symbols.person_rounded),
              ),
              validationMessages: {
                ValidationMessage.required: (error) =>
                    "Username must not be empty",
                "unique": (error) => "Username taken"
              },
            ),
          ),
          const SizedBox(height: 20),
          ReactiveFormConsumer(builder: (context, form, child) {
            return SizedBox(
              width: width,
              height: 50,
              child: FilledButton(
                onPressed: form.control(username).valid
                    ? () {
                        setState(() {
                          showUsernameForm = true;
                        });
                      }
                    : null,
                child: Text(
                  'Continue with Username',
                  style: theme.typography.englishLike.titleMedium?.copyWith(
                    color: form.control(username).valid
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: width / 2.5, child: const Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "OR",
                  style: theme.typography.englishLike.labelLarge,
                ),
              ),
              SizedBox(width: width / 2.5, child: const Divider()),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: width,
            height: 50,
            child: FilledButton(
              onPressed: _signInWithGoogle,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeCap: StrokeCap.round,
                      ),
                    )
                  : Text(
                      'Continue with Google',
                      style: theme.typography.englishLike.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}

class UsernameValidator extends AsyncValidator<dynamic> {
  final PocketBase pb;

  const UsernameValidator({required this.pb});

  @override
  Future<Map<String, dynamic>?> validate(
      AbstractControl<dynamic> control) async {
    final error = {'unique': false};

    final isUniqueUsername = await _getUsernameUnique(control.value.toString());
    if (!isUniqueUsername) {
      control.markAsTouched();
      return error;
    }

    return null;
  }

  Future<bool> _getUsernameUnique(String username) async {
    var result = await pb
        .send("/api/hooks/check_username", query: {"username": username});
    return !result["taken"];
  }
}

// Extract _buildUsernameForm into a StatefulWidget
class _UsernameForm extends StatefulWidget {
  final double width;
  final FormGroup form;
  final bool isLoading;
  final Function(String, String) onSignIn;
  final Function() onBack;

  const _UsernameForm(
      {super.key,
      required this.width,
      required this.form,
      required this.isLoading,
      required this.onSignIn,
      required this.onBack});

  @override
  _UsernameFormState createState() => _UsernameFormState();
}

class _UsernameFormState extends State<_UsernameForm> {
  late Future<bool> _isNewAccountFuture;

  @override
  void initState(){
    super.initState();
    _isNewAccountFuture = _checkIsNewAccount();
  }

  Future<bool> _checkIsNewAccount() async {
    // Perform your asynchronous logic to determine if it's a new account
    // For example, check if a user record exists in your database
    // ...
    return Future.delayed(
      Duration(seconds: 10),
      () => true,
    ); // Or false, based on your logic
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return FutureBuilder<bool>(
      future: _isNewAccountFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              LoadingBox(width: widget.width - 10, height: 80),
              const SizedBox(height: 20),
              _buildInputs(theme),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          bool isNewAccount = snapshot.data!;
          return Column(
            children: [
              SizedBox(
                width: widget.width - 20,
                child: Text(
                  isNewAccount ? 'Create a new account' : 'Welcome back',
                  style: theme.typography.englishLike.displaySmall
                ),
              ),
              const SizedBox(height: 20),
              _buildInputs(theme),
            ],
          );
        }
      },
    );
  }

  Widget _buildInputs(ThemeData theme){
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          ReactiveTextField(
            formControlName: password,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
              icon: Icon(Symbols.password_rounded),
              hintText: 'Choose a strong password',
            ),
            validationMessages: {
              ValidationMessage.required: (error) =>
              "Password must not be empty",
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your details to sign in or create a new account.",
            style: theme.typography.englishLike.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ReactiveFormConsumer(builder: (context, form, child) {
            return SizedBox(
              width: widget.width,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(),
                onPressed: form.valid
                    ? () {
                  widget.onSignIn(
                    form.control("username").value,
                    form.control("password").value,
                  );
                }
                    : null,
                child: widget.isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                    strokeCap: StrokeCap.round,
                  ),
                )
                    : Text(
                  'Continue',
                  style: theme.typography.englishLike.titleMedium
                      ?.copyWith(
                    color: form.valid
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface
                        .withOpacity(0.38),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
          TextButton(
            onPressed: () {
              widget.onBack();
            },
            child: const Text('Back to Sign In Options'),
          ),
          TextButton(
            onPressed: () {

            },
            child: const Text('restart anim'),
          ),
        ],
      ),
    );
  }
}
