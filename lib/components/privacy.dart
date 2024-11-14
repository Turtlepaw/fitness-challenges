import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';

const hideUsername = "hide_username";

class PrivacyControls extends StatefulWidget {
  final void Function(PrivacyControl, bool)? onChanged;

  const PrivacyControls({this.onChanged, super.key});

  @override
  _PrivacyControlsState createState() => _PrivacyControlsState();
}

enum PrivacyControl { hideUsernameInCommunity, hideUsernameInPrivateChallenges }

class _PrivacyControlsState extends State<PrivacyControls> {
  final form = FormGroup({
    PrivacyControl.hideUsernameInCommunity.name:
        FormControl<bool>(validators: [Validators.required], value: false),
    PrivacyControl.hideUsernameInPrivateChallenges.name:
        FormControl<bool>(validators: [Validators.required], value: false),
  });
  late PocketBase pb;

  @override
  void initState() {
    pb = Provider.of<PocketBase>(context, listen: false);
    if(pb.authStore.model != null) setFormStates(pb.authStore.model);
    setupRealtime();
    super.initState();
  }

  void setupRealtime(){
    if(pb.authStore.model != null) {
      pb.collection("users").subscribe(pb.authStore.model.id, (model){
        if(model.record != null) setFormStates(model.record!);
      });
    }
  }

  void setFormStates(RecordModel model){
    setState(() {
      form.control(PrivacyControl.hideUsernameInCommunity.name).value = model.getBoolValue(
          PrivacyControl.hideUsernameInCommunity.name,
          false
      );
      form.control(PrivacyControl.hideUsernameInPrivateChallenges.name).value = model.getBoolValue(
          PrivacyControl.hideUsernameInPrivateChallenges.name,
          false
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: Column(
        children: [
          buildPrivacyControl(
              "Hide username in community",
              "Display your user ID instead of your username in the community",
              Symbols.disabled_visible_rounded,
              form.control(PrivacyControl.hideUsernameInCommunity.name).value,
                  (value) => _updatePrivacyControl(
                  PrivacyControl.hideUsernameInCommunity, value)),
          buildPrivacyControl(
              "Hide username in private challenges",
              "Display your user ID instead of your username in the invite only challenges",
              Symbols.shield_lock_rounded,
              form.control(PrivacyControl.hideUsernameInPrivateChallenges.name).value,
                  (value) => _updatePrivacyControl(
                  PrivacyControl.hideUsernameInPrivateChallenges, value)),
        ],
      ),
    );
  }

  void _updatePrivacyControl(PrivacyControl control, bool value) {
    if (widget.onChanged != null) {
      widget.onChanged!(control, value);
    }

    pb.collection("users").update((pb.authStore.model as RecordModel).id,
        body: {control.name: value});

    setState(() {
      form.control(control.name).value = value;
    });
  }

  Widget buildPrivacyControl(String name, String description, IconData icon,
      bool value, void Function(bool) onPressed) {
    return SizedBox(
      width: 410,
      child: Card(
        elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          clipBehavior: Clip.hardEdge,
          child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Icon(icon),
              title: Text(name),
              subtitle: Text(description),
              onTap: () {
                onPressed(!value);
              }, // Remove ! from !value
              trailing: Switch(
                value: value,
                onChanged: (value) {
                  onPressed(value);
                },
              ))),
    );
  }
}
