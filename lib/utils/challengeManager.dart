import 'package:fitness_challenges/utils/health.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

class ChallengeProvider with ChangeNotifier {
  final PocketBase pb;
  ChallengeProvider({required this.pb});

  List<RecordModel> _challenges = [];
  bool _isLoading = false;

  List<RecordModel> get challenges => _challenges;
  bool get isLoading => _isLoading;

  void init() {
    print("ChallengeProvider init called");
    if (pb.authStore.isValid) {
      fetchChallenges();
    } else {
      pb.authStore.onChange.listen((e) {
        print("Auth Store changed");
        fetchChallenges();
      });
    }
  }

  Future<void> fetchChallenges() async {
    if (!pb.authStore.isValid) {
      print("Auth token invalid, aborting fetch");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await pb.collection("challenges").getFullList(
          filter: "users.id ?= '${pb.authStore.model?.id}'", expand: "users");

      print("Challenges fetched: $response");
      _challenges = response;
    } catch (e) {
      print("Error fetching challenges: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveExisting(RecordModel model) async {
    int index = _challenges.indexWhere((data) => data.id == model.id);

    if (index != -1) {
      // Replace the item while keeping its position
      _challenges[index] = model;
    } else {
      // If the item is not found, you can add it (optional)
      _challenges.add(model);
    }

    notifyListeners(); // Notify listeners about the change
  }

  Future<void> reloadChallenges(BuildContext context) async {
    _challenges = [];
    notifyListeners();
    await fetchChallenges();
    notifyListeners();
    //if(context.mounted){
    //Provider.of<HealthManager>(context, listen: false).fetchHealthData();
    //}
  }
}
