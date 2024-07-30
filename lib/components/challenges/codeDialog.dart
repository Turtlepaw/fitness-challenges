import 'package:fitness_challenges/components/loader.dart';
import 'package:fitness_challenges/types/collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:share_plus/share_plus.dart';

class CodeDialog extends StatefulWidget {
  final PocketBase pb;
  final RecordModel challenge;

  const CodeDialog({super.key, required this.pb, required this.challenge});

  @override
  _CodeDialogState createState() => _CodeDialogState();
}

class _CodeDialogState extends State<CodeDialog> {
  bool _isLoading = false;
  late bool _isEnabled;
  late String _code;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isEnabled = widget.challenge.getStringValue("joinCode").trim().isNotEmpty;
      _code = widget.challenge.getStringValue("joinCode").trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var dialogWidth = MediaQuery.of(context).size.width * 0.8; // 80% of screen width
    return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: const EdgeInsets.only(top: 5, left: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Invite Users",
                        style: theme.textTheme.headlineSmall,
                      ),
                      Switch(
                        value: _isEnabled, onChanged: _isLoading ? null : (bool value) async {
                        setState(() {
                          _isLoading = true;
                        });

                        if (value == true) {
                          var res = await widget.pb.send(
                              "/api/hooks/regenerate_code",
                              method: "POST",
                              query: {
                                'id': widget.challenge.id
                              }
                          );

                          await Future.delayed(const Duration(seconds: 1));
                          setState(() {
                            _code = res['uniqueCode'];
                            _isEnabled = true;
                          });
                        } else {
                          widget.pb.collection(Collection.challenges).update(widget.challenge.id, body: {
                            'joinCode': ''
                          });

                          setState(() {
                            _code = '';
                            _isEnabled = false;
                          });
                        }

                        setState(() {
                          _isLoading = false;
                        });
                      },
                      )
                    ],
                  )
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isLoading
                      ? LoadingBox(
                      width: dialogWidth - 32, // Subtract padding
                      height: 70
                  )
                      : Text(
                    _code.isEmpty ? "No code" : _code,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if (!_isLoading && _code.trim().isNotEmpty) IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _code));
                    },
                    icon: const Icon(Symbols.content_copy_rounded),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed: (!_isLoading && _code.trim().isNotEmpty) ? () async {
                      await Share.share(_code.toString());
                    } : null,
                    icon: Icon(Symbols.share_rounded, color: (!_isLoading && _code.trim().isNotEmpty) ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.38)),
                  ),
                  const SizedBox(width: 5),
                  FilledButton(
                    onPressed: _handleClose,
                    child: const Text("Close"),
                  )
                ],
              )
            ],
          ),
        )
    );
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }
}

