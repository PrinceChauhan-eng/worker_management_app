import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'live_clock.dart'; // Import the LiveClock widget

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final VoidCallback? onLeadingPressed;
  final bool showLiveClock; // Add option to show live clock

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showThemeToggle = true,
    this.onLeadingPressed,
    this.showLiveClock = false, // Default to false to maintain backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    List<Widget> appActions = [];
    if (actions != null) {
      appActions.addAll(actions!);
    }
    
    if (showThemeToggle) {
      appActions.add(
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
      );
    }
    
    if (appActions.isNotEmpty) {
      appActions.add(const SizedBox(width: 16));
    }

    return AppBar(
      title: showLiveClock
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const LiveClock(), // Add the live clock when requested
              ],
            )
          : Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
      leading: onLeadingPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onLeadingPressed,
            )
          : null,
      actions: appActions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}