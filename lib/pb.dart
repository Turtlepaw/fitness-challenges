import 'package:pocketbase/pocketbase.dart';
import'package:shared_preferences/shared_preferences.dart';
import 'constants.dart' as Constants;

Future<PocketBase> initializePocketbase() async {
  final prefs = await SharedPreferences.getInstance();
  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString('pb_auth'),
  );

  return PocketBase(Constants.apiUrl, authStore: store);
}