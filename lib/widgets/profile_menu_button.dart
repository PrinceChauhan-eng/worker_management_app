import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../services/session_manager.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_profile_screen.dart'; // Import the new admin profile screen
import '../screens/settings_screen.dart';
import '../screens/auth/new_login_screen.dart';

class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    final completionPercentage = user.profileCompletionPercentage;
    final hasProfilePhoto = user.profilePhoto != null && user.profilePhoto!.isNotEmpty;
    final isAdmin = user.role == 'admin';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E88E5),
              backgroundImage: hasProfilePhoto
                  ? NetworkImage(user.profilePhoto!) as ImageProvider
                  : null,
              child: !hasProfilePhoto
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Profile completion indicator
            if (completionPercentage < 100)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: completionPercentage >= 70
                        ? Colors.green
                        : completionPercentage >= 40
                            ? Colors.orange
                            : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        itemBuilder: (BuildContext context) => [
          // User Info Header
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF1E88E5),
                      backgroundImage: hasProfilePhoto
                          ? NetworkImage(user.profilePhoto!) as ImageProvider
                          : null,
                      child: !hasProfilePhoto
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.role == 'admin'
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: user.role == 'admin'
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Profile completion progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completionPercentage >= 70
                                ? Colors.green
                                : completionPercentage >= 40
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completionPercentage%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
              ],
            ),
          ),
          
          // My Profile (different screens for admin and worker)
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF1E88E5), size: 20),
                const SizedBox(width: 12),
                Text(
                  isAdmin ? 'Admin Profile' : 'My Profile',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Settings
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          
          const PopupMenuDivider(),
          
          // Logout
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        onSelected: (String value) async {
          switch (value) {
            case 'profile':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isAdmin 
                    ? const AdminProfileScreen() // Use enhanced admin profile screen
                    : const ProfileScreen(),     // Use regular profile screen for workers
                ),
              );
              break;
              
            case 'settings':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              break;
              
            case 'logout':
              _handleLogout(context);
              break;
          }
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Show confirmation dialog
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );

    // Check if context is still mounted before proceeding
    if (confirmed == true && context.mounted) {
      // Remove session for current user in this tab only
      SessionManager sessionManager = SessionManager();
      if (userProvider.currentUser != null) {
        // Clear current user ID for this tab only
        await sessionManager.clearCurrentUserId();
      }
      
      // Clear current user in provider for this tab
      userProvider.signOut();
      
      // Show toast
      Fluttertoast.showToast(
        msg: 'You have been logged out.',
        backgroundColor: Colors.green,
      );
      
      // Check if context is still mounted before navigation
      if (context.mounted) {
        // Navigate directly to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NewLoginScreen()),
          (route) => false,
        );
      }
    }
  }
}