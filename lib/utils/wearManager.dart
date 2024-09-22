import 'dart:developer';

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:pocketbase/pocketbase.dart';

class WearManager {
  final PocketBase pb;
  final FlutterWearOsConnectivity flutterWearOsConnectivity =
      FlutterWearOsConnectivity();

  WearManager(this.pb);

  Future<bool> checkConnection() async {
    await flutterWearOsConnectivity.configureWearableAPI();
    var caps = await flutterWearOsConnectivity.getAllCapabilities();

    if (caps.containsKey("verify_wear_app")) {
      return true;
    } else {
      return false;
    }
  }

  Future<WearManager> sendAuthentication() async {
    final isConnected = await checkConnection();
    if (pb.authStore.isValid && isConnected) {
      print("Sending auth details");
      await flutterWearOsConnectivity.syncData(
          path: "/auth", data: {"token": pb.authStore.token}, isUrgent: true);
    }

    var devices = await flutterWearOsConnectivity.getConnectedDevices();

    if (devices.isNotEmpty) {
      flutterWearOsConnectivity
          .messageReceived(pathURI: Uri(path: "/auth_request"))
          .listen((message) {
            print(message);
        inspect(message);
      });
    }

    return this;
  }
}
