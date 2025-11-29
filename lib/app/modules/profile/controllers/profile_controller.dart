import 'dart:io' if (dart.library.html) 'package:classroom_mini/app/shared/controllers/io_stub.dart';
import 'package:classroom_mini/app/data/models/request/profile_request.dart';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../../data/services/profile_api_service.dart';
import '../../../data/services/api_service.dart';

class ProfileController extends GetxController {
  final ProfileApiService _apiService;

  ProfileController(this._apiService);

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _apiService.getProfile();
      if (response.success) {
        user.value = response.data.user;
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch profile: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(String fullName, String email) async {
    try {
      isLoading.value = true;
      final request = UpdateProfileRequest(fullName: fullName, email: email);
      final response = await _apiService.updateProfile(request);
      if (response.success) {
        user.value = response.data.user;
        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        Get.snackbar('Error', 'Failed to update profile');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        isLoading.value = true;
        
        // On web, use bytes directly; on mobile, use file path
        if (kIsWeb) {
          final Uint8List imageBytes = await image.readAsBytes();
          final String fileName = image.name;
          final response = await DioClient.uploadAvatarFromBytes(
            imageBytes,
            fileName,
          );
          if (response.success) {
            await getProfile();
            Get.snackbar('Success', 'Avatar uploaded successfully');
          } else {
            Get.snackbar('Error', response.message);
          }
        } else {
          final File imageFile = File(image.path);
          final response = await _apiService.uploadAvatar(imageFile);
          if (response.success) {
            await getProfile();
            Get.snackbar('Success', 'Avatar uploaded successfully');
          } else {
            Get.snackbar('Error', response.message);
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload avatar: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
