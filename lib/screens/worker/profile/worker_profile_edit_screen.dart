import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../models/user.dart';
import '../../../Animations/FadeAnimation.dart';

class WorkerProfileEditScreen extends StatefulWidget {
  const WorkerProfileEditScreen({super.key});

  @override
  State<WorkerProfileEditScreen> createState() => _WorkerProfileEditScreenState();
}

class _WorkerProfileEditScreenState extends State<WorkerProfileEditScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController designationCtrl;
  late TextEditingController wageCtrl;

  File? pickedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    
    nameCtrl = TextEditingController(text: user?.name ?? "");
    phoneCtrl = TextEditingController(text: user?.phone ?? "");
    emailCtrl = TextEditingController(text: user?.email ?? "");
    addressCtrl = TextEditingController(text: user?.address ?? "");
    designationCtrl = TextEditingController(text: user?.designation ?? "");
    wageCtrl = TextEditingController(text: user?.wage?.toString() ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: theme.isDark ? Colors.black : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.isDark ? Colors.white : Colors.black),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: theme.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeAnimation(
              child: _avatarSection(theme, user),
            ),
            const SizedBox(height: 30),

            _inputField("Full Name", nameCtrl, theme),
            const SizedBox(height: 15),
            _inputField("Phone Number", phoneCtrl, theme),
            const SizedBox(height: 15),
            _inputField("Email", emailCtrl, theme),
            const SizedBox(height: 15),
            _inputField("Address", addressCtrl, theme),
            const SizedBox(height: 15),
            _inputField("Designation", designationCtrl, theme),
            const SizedBox(height: 15),
            _inputField("Wage", wageCtrl, theme, TextInputType.number),

            const SizedBox(height: 30),

            FadeAnimation(
              child: ElevatedButton(
                onPressed: () async {
                  double? wage;
                  if (wageCtrl.text.isNotEmpty) {
                    wage = double.tryParse(wageCtrl.text);
                  }

                  await userProvider.updateWorkerProfile(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    email: emailCtrl.text,
                    address: addressCtrl.text,
                    designation: designationCtrl.text,
                    wage: wage,
                    imageFile: pickedImage,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: const Color(0xFFFFD300),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection(ThemeProvider theme, User? user) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.isDark ? Colors.black45 : Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      pickedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          user.profilePhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD300),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark ? Colors.black45 : Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.black,
                ),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, ThemeProvider theme, [TextInputType keyboardType = TextInputType.text]) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? Colors.black45 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: theme.isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.isDark ? Colors.white70 : Colors.grey[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        pickedImage = File(img.path);
      });
    }
  }
}