import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../Animations/FadeAnimation.dart';

class NewLoginScreen extends StatefulWidget {
  const NewLoginScreen({super.key});

  @override
  State<NewLoginScreen> createState() => _NewLoginScreenState();
}

class _NewLoginScreenState extends State<NewLoginScreen> {
  final _emailUserPhone = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String selectedRole = "Admin";

  final supabase = Supabase.instance.client;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Use the custom auth provider for login
      final success = await authProvider.login(
        identifier: _emailUserPhone.text.trim(),
        password: _password.text.trim(),
        role: selectedRole.toLowerCase(), // Convert to lowercase to match database values
        rememberMe: _rememberMe,
      );

      if (success) {
        // Login successful
        final user = authProvider.currentUser!;
        
        // Set current user in user provider for backward compatibility
        userProvider.currentUser = user;

        // Navigate based on selected role
        if (selectedRole == "Admin") {
          Navigator.pushReplacementNamed(context, "/admin_dashboard");
        } else {
          // For workers, navigate to worker dashboard
          Navigator.pushReplacementNamed(context, "/worker-dashboard");
        }
      } else {
        // Login failed
        final errorMessage = authProvider.errorMessage ?? 'Invalid credentials';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $errorMessage")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.isDark ? Colors.black : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 25),

              // ICON + TITLE
              FadeAnimation(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.work, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Worker Management",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "Login to your account",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // CARD
              FadeAnimation(
                child: Container(
                  width: size.width,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.isDark ? const Color(0xFF0D0D0D) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ROLE DROPDOWN (Perfect same size as input box)
                      Container(
                        height: 55,  // same height as TextField
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.isDark ? const Color(0xFF111111) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.isDark ? Colors.white : Colors.black,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Admin",
                                child: Text("Admin"),
                              ),
                              DropdownMenuItem(
                                value: "Worker",
                                child: Text("Worker"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _inputField(
                        icon: Icons.person_outline,
                        controller: _emailUserPhone,
                        label: "Phone, Email, or User ID",
                        theme: theme,
                      ),
                      const SizedBox(height: 15),

                      _inputField(
                        icon: Icons.lock_outline,
                        controller: _password,
                        label: "Password",
                        theme: theme,
                        obscure: true,
                      ),
                      const SizedBox(height: 15),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v!),
                          ),
                          const Text("Remember me"),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text("Login", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, "/forgot_password"),
                    child: const Text("Forgot Password?"),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("User Management"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required IconData icon,
    required TextEditingController controller,
    required String label,
    required ThemeProvider theme,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: theme.isDark ? const Color(0xFF111111) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD300), width: 2),
        ),
      ),
    );
  }
}