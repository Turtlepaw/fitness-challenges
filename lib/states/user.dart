import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class UserModel extends ChangeNotifier {
  RecordAuth? _data;
  bool _isLoggedIn = false; // Explicitly track login status

  RecordAuth? get data => _data;
  bool get isLoggedIn => _isLoggedIn;

  void login(RecordAuth userData) {
    _data = userData;
    _isLoggedIn = true; // Set isLoggedIn to true on successful login
    notifyListeners();
  }

  void logout() {
    _data = null;
    _isLoggedIn = false; // Set isLoggedIn to false on logout
    notifyListeners();
  }
}