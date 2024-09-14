import 'package:fitness_challenges/components/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

const password = "password";
const username = "username";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late PocketBase pb;
  final form = FormGroup({
    username: FormControl<String>(
        //asyncValidators: [usernameValidator],
        validators: [Validators.required],
        value: ''),
    password: FormControl<String>(validators: [Validators.required, Validators.minLength(8)], value: ''),
  });

  bool showUsernameForm = false;
  bool isLoading = false;

  @override
  void initState() {
    pb = Provider.of<PocketBase>(context, listen: false);
  }

  Future<void> _setLoading([bool state = true]) async {
    setState(() {
      isLoading = state;
    });
  }

  Future<void> _signInWithGoogle() async {
    _setLoading();
    try {
      await pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          await launchUrl(url);
          _setLoading(false);
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

        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

        context.go("/home");
      }

      _setLoading(false);
    } catch (e) {
      print('Error doing OAuth2 URL: $e');
      _setLoading(false);
    }
  }

  Future<void> _signInWithUsername(String username, String password, bool isNewAccount) async {
    _setLoading();
    try {
      await pb.collection('users').authWithPassword(username, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in!'),
          ),
        );

        context.go("/home");
      }

      _setLoading(false);
    } catch (e) {
      print('Error doing OAuth2 URL:$e');
      if(isNewAccount){
        try {
          await pb.collection('users').create(body: {
            'username': username,
            'password': password,
            'passwordConfirm': password
          });

          await pb
              .collection('users')
              .authWithPassword(username, password);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created'),
              ),
            );

            context.go("/home");
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
      } else {
         if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Invalid password'),
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
    double? width = (screenWidth < 450 ? null : 400)?.toDouble();
    //final usernameValidator = UsernameValidator(pb: widget.pb);
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
                        },
                        pb: pb,
                      )
                    : _buildSignInButtons(width, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildUsernameForm(double width, ThemeData theme) {
  //   return Column(
  //     children: [
  //       SizedBox(
  //         width: width,
  //         child: Column(
  //           children: [
  //             // ReactiveTextField(
  //             //   formControlName: username,
  //             //   onSubmitted: (v) => form.focus(password),
  //             //   decoration: const InputDecoration(
  //             //     border: OutlineInputBorder(),
  //             //     labelText: 'Username',
  //             //     icon: Icon(Symbols.person_rounded),
  //             //   ),
  //             //   validationMessages: {
  //             //     ValidationMessage.required: (error) =>
  //             //         "Username must not be empty",
  //             //     "unique": (error) => "Username taken"
  //             //   },
  //             // ),
  //             // const SizedBox(height: 10),
  //             ReactiveTextField(
  //               formControlName: password,
  //               obscureText: true,
  //               decoration: const InputDecoration(
  //                 border: OutlineInputBorder(),
  //                 labelText: 'Password',
  //                 icon: Icon(Symbols.password_rounded),
  //                 hintText: 'Choose a strong password',
  //               ),
  //               validationMessages: {
  //                 ValidationMessage.required: (error) =>
  //                     "Password must not be empty",
  //               },
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               "Enter your details to sign in or create a new account.",
  //               style: theme.typography.englishLike.bodyMedium,
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 15),
  //             ReactiveFormConsumer(builder: (context, form, child) {
  //               return SizedBox(
  //                 width: width,
  //                 height: 50,
  //                 child: FilledButton(
  //                   style: FilledButton.styleFrom(),
  //                   onPressed: form.valid
  //                       ? () {
  //                           _signInWithUsername(
  //                             form.control("username").value,
  //                             form.control("password").value,
  //                           );
  //                         }
  //                       : null,
  //                   child: isLoading
  //                       ? SizedBox(
  //                           width: 20,
  //                           height: 20,
  //                           child: CircularProgressIndicator(
  //                             color: Theme.of(context).colorScheme.onPrimary,
  //                             strokeCap: StrokeCap.round,
  //                           ),
  //                         )
  //                       : Text(
  //                           'Continue',
  //                           style: theme.typography.englishLike.titleMedium
  //                               ?.copyWith(
  //                             color: form.valid
  //                                 ? theme.colorScheme.onPrimary
  //                                 : theme.colorScheme.onSurface
  //                                     .withOpacity(0.38),
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                 ),
  //               );
  //             })
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 15),
  //       TextButton(
  //         onPressed: () {
  //           setState(() {
  //             showUsernameForm = false;
  //           });
  //         },
  //         child: const Text('Back to Sign In Options'),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSignInButtons(double? width, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    return KeyedSubtree(
      key: const ValueKey<bool>(false),
      child: Column(
        children: [
          Text(
            "Welcome",
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "Compete with friends and family.",
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          AdaptiveBox(
            width: width,
            child: ReactiveTextField(
              formControlName: username,
              onChanged: (value) {
                form.control(username).value = value.value;
              },
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
            return AdaptiveBox(
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
                  style: theme.textTheme.titleMedium?.copyWith(
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
              SizedBox(width: screenWidth / 2.5, child: const Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "OR",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                  ),
                ),
              ),
              SizedBox(width: screenWidth / 2.5, child: const Divider()),
            ],
          ),
          const SizedBox(height: 15),
          AdaptiveBox(
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
                      style: theme.textTheme.titleMedium?.copyWith(
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

class AdaptiveBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;

  const AdaptiveBox({super.key, required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    print(width);
    if(width != null){
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    } else {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: child,
        ),
      );
    }
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
  final double? width;
  final FormGroup form;
  final bool isLoading;
  final Function(String, String, bool) onSignIn;
  final Function() onBack;
  final PocketBase pb;

  const _UsernameForm(
      {super.key,
      required this.width,
      required this.form,
      required this.isLoading,
      required this.onSignIn,
      required this.onBack,
      required this.pb});

  @override
  _UsernameFormState createState() => _UsernameFormState();
}

class _UsernameFormState extends State<_UsernameForm> {
  late Future<bool> _isNewAccountFuture;

  @override
  void initState() {
    super.initState();
    _isNewAccountFuture = _checkIsNewAccount();
  }

  Future<bool> _checkIsNewAccount() async {
    var data = widget.form.control(username).value;
    var result = await widget.pb
        .send("/api/hooks/check_username", query: {"username": data});
    await Future.delayed(const Duration(seconds: 1));
    return !result["taken"];
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return FutureBuilder<bool>(
      future: _isNewAccountFuture,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildContent(context, theme, snapshot),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, AsyncSnapshot<bool> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        key: const ValueKey('loading'),
        children: [
          AdaptiveBox(
            height: 80,
            width: widget.width,
            child: LoadingBox(width: double.infinity, height: 80),
          ),
          const SizedBox(height: 20),
          _buildInputs(theme, true),
        ],
      );
    } else if (snapshot.hasError) {
      return Center(key: const ValueKey('error'), child: Text('Error: ${snapshot.error}'));
    } else {
      bool isNewAccount = snapshot.data!;
      return Column(
        key: const ValueKey('content'),
        children: [
          AdaptiveBox(
            width: widget.width != null ? widget.width! - 20 : null,
            child: Column(
              children: [
                Text(
                  isNewAccount ? 'Create a new account' : 'Welcome back',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if(!isNewAccount)
                  Text(
                    'Enter your password to continue',
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            )
          ),
          const SizedBox(height: 20),
          _buildInputs(theme, isNewAccount),
        ],
      );
    }
  }

  Widget _buildInputs(ThemeData theme, bool isNewAccount) {
    return AdaptiveBox(
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
          const SizedBox(height: 15),
          ReactiveFormConsumer(builder: (context, form, child) {
            return AdaptiveBox(
              width: widget.width,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(),
                onPressed: form.valid
                    ? () {
                        widget.onSignIn(
                          form.control("username").value,
                          form.control("password").value,
                            isNewAccount
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
                        style:
                            theme.typography.englishLike.titleMedium?.copyWith(
                          color: form.valid
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withOpacity(0.38),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            );
          }),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              widget.onBack();
            },
            child: const Text('Back to Sign In Options'),
          ),
        ],
      ),
    );
  }
}
