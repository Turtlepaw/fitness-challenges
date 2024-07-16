import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  final PocketBase pb;

  const LoginPage({super.key, required this.pb});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showUsernameForm = false;
  bool isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });
    try {
      await widget.pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          // or use something like flutter_custom_tabs to make the transitions between native and web content more seamless
          await launchUrl(url);
        }, // Pass the urlCallback function
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
        // Add createData, expand, or fields if needed
      );
    } catch (e) {
      // Handle error getting OAuth2 URL
      print('Error doing OAuth2 URL: $e');
    }
  }

  Future<void> _signInWithUsername(String username, String password) async {
    setState(() {
      isLoading = true;
    });
    try {
      await widget.pb.collection('users').authWithPassword(username, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in!'),
        ),
      );
    } catch (e) {
      // Handle error getting OAuth2 URL
      print('Error doing OAuth2 URL:$e');
      try {
        await widget.pb.collection('users').create(body: {
          'username': username, // Make sure these are strings
          'password': password,
          'passwordConfirm': password
        });

        await widget.pb
            .collection('users')
            .authWithPassword(username, password);
        // Consider adding success feedback here if needed
      } catch (createError) {
        print('Error creating user: $createError');
        if (mounted) {
          // Safe SnackBar display
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error creating account. Please try again.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double width = (screenWidth < 400 ? 250 : 400).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: showUsernameForm
                  ? _buildUsernameForm(width, theme)
                  : _buildSignInButtons(width, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameForm(double width, ThemeData theme) {
    final formKey = GlobalKey<FormState>(); // Form key for validation
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String? passwordError;

    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a password';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      return null; // Return null if valid
    }

    return KeyedSubtree(
        // Add a KeyedSubtree here
        key: const ValueKey<bool>(true),
        child: Column(
          children: [
            SizedBox(
                width: width,
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                          icon: Icon(Symbols.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        enableSuggestions: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                          icon: Icon(Symbols.password_rounded),
                          hintText: 'Choose a strong password',
                        ),
                        autocorrect: false,
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        passwordError ??
                            "Enter your details to sign in or create a new account.",
                        style: theme.typography.englishLike.bodyMedium
                            ?.copyWith(
                                color: passwordError != null
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: width,
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              // backgroundColor: passwordError == null &&
                              //     passwordController.text.isNotEmpty &&
                              //     usernameController.text.isNotEmpty
                              //     ? theme.colorScheme.primary
                              //     : theme
                              //         .disabledColor, // Change color based on validation
                              ),
                          onPressed: () {
                            if (passwordError == null &&
                                passwordController.text.isNotEmpty &&
                                usernameController.text.isNotEmpty) {
                              // Validate before sign-in
                              // If form is valid, proceed with sign-in
                              _signInWithUsername(
                                usernameController.text,
                                passwordController.text,
                              );
                            }
                          },
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    strokeCap: StrokeCap.round,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: theme
                                      .typography.englishLike.titleMedium
                                      ?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    // color: passwordError == null &&
                                    //     passwordController.text.isNotEmpty &&
                                    //     usernameController.text.isNotEmpty
                                    //     ? theme.colorScheme
                                    //         .onPrimary // Normal text color
                                    //     : theme.disabledColor, // Disabled text color
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                )),
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
        ));
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
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Start competing with friends and family.",
                style: Theme.of(context).typography.englishLike.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: width,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    showUsernameForm = true;
                  });
                },
                child: Text(
                  'Continue with Username',
                  style: theme.typography.englishLike.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
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
                child: Text(
                  'Continue with Google',
                  style: theme.typography.englishLike.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
