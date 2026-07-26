import 'package:flutter/foundation.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/profile_response.dart';
import 'package:lexor_shared/lexor_shared.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileResponse? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get('/Profile');
      profile = ProfileResponse.fromJson(data);
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String email,
    required String phoneNumber,
    required String address,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.put(
        '/Profile',
        body: {
          'email': email,
          'phoneNumber': phoneNumber,
          'address': address,
        },
      );
      profile = ProfileResponse.fromJson(data);
      return true;
    } catch (e) {
      error = messageFor(e);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
