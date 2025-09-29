import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../data/models/user_model.dart';

class EditProfileView extends GetView<ProfileController> {
  final UserModel user;

  const EditProfileView({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.updateProfile(
                            fullNameController.text,
                            emailController.text,
                          );
                        },
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save'),
                )),
          ],
        ),
      ),
    );
  }
}
