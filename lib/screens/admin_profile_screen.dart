import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../Animations/FadeAnimation.dart';
import '../models/user.dart';
import '../services/image_service.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final User? user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: theme.isDark ? Colors.black : const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            color: theme.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileBanner(user: user!, theme: theme),
            const SizedBox(height: 18),

            FadeAnimation(child: _ProfileDetails(user: user, theme: theme)),
            const SizedBox(height: 18),

            FadeAnimation(child: _ProfileOptions(theme: theme)),
            const SizedBox(height: 20),

            FadeAnimation(child: _LogoutTile(theme: theme)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ===============================
// Profile Banner + Avatar + Edit Button
// ===============================
class _ProfileBanner extends StatelessWidget {
  final User user;
  final ThemeProvider theme;

  const _ProfileBanner({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 190,
            width: double.infinity,
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
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email ?? "No email",
                  style: TextStyle(
                    color: theme.isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin_profile_edit');
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
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Edit Profile",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: -40,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                final image = await ImageService.pickImageAsData();
                if (image == null) return;

                await Provider.of<UserProvider>(context, listen: false)
                    .updateAdminProfilePhoto(image);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                      ? Image.network(user.profilePhoto!, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// Profile Details Card
// ===============================
class _ProfileDetails extends StatelessWidget {
  final User user;
  final ThemeProvider theme;
  const _ProfileDetails({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0D0D0D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailItem(Icons.phone_outlined, user.phone, theme),
          const SizedBox(height: 12),
          _detailItem(Icons.email_outlined, user.email ?? "No email", theme),
          const SizedBox(height: 12),
          _detailItem(Icons.location_on_outlined, user.address ?? "No address", theme),
          const SizedBox(height: 12),
          _detailItem(Icons.badge_outlined, user.designation ?? "No designation", theme),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String value, ThemeProvider theme) {
    return Row(
      children: [
        Icon(icon, color: theme.isDark ? Colors.white70 : Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ===============================
// Settings / Menu Options
// ===============================
class _ProfileOptions extends StatelessWidget {
  final ThemeProvider theme;
  const _ProfileOptions({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0D0D0D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _menuTile(Icons.settings, "Settings", context, '/settings', theme),
          const Divider(height: 1),
          _menuTile(Icons.credit_card, "Billing Details", context, '/billing', theme),
          const Divider(height: 1),
          _menuTile(Icons.group, "User Management", context, '/workers', theme),
          const Divider(height: 1),
          _menuTile(Icons.info_outline, "App Info", context, '/info', theme),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, BuildContext context, String route,
      ThemeProvider theme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.isDark ? Colors.white12 : Colors.grey[200],
        child: Icon(icon, color: theme.isDark ? Colors.white : Colors.black),
      ),
      title: Text(title,
          style: TextStyle(
            color: theme.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          )),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: theme.isDark ? Colors.white54 : Colors.grey),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}

// ===============================
// Logout Tile
// ===============================
class _LogoutTile extends StatelessWidget {
  final ThemeProvider theme;
  const _LogoutTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0D0D0D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.isDark ? Colors.white12 : Colors.grey[200],
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: Text("Logout",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            )),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: theme.isDark ? Colors.white54 : Colors.grey),
        onTap: () {
          // TODO: Implement logout functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logout functionality to be implemented")),
          );
        },
      ),
    );
  }
}