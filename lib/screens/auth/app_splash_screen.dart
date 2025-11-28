import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/modern_loader.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _loaderFade;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    // 🔥 Background Animation Controller
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Extended to 8 seconds
    )..repeat(reverse: true);

    // 🔥 Logo + Loader Animation Controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Extended to 4 seconds
    )..forward();

    // 🔥 Text Animation Controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200), // Extended to 3.2 seconds
    );

    // Logo Fade-in
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo Scale
    _logoScale = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Loader Fade
    _loaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // Title Fade
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );

    // Subtitle Fade
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start text animation after logo appears
    Future.delayed(const Duration(milliseconds: 1600), () { // Extended delay
      _textController.forward();
    });

    // Auto navigation after animation
    Timer(const Duration(seconds: 8), () { // Extended to 8 seconds
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A0F15),
                Color.lerp(const Color(0xFF0A0F15), Colors.black, _bgController.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ⭐ Glowing Animated Logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (_, child) {
                  return Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD300).withOpacity(0.45),
                              blurRadius: 35,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  "assets/logo.png",
                  height: 160,
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ Title Animation
              AnimatedBuilder(
                animation: _textController,
                builder: (_, child) {
                  return Opacity(
                    opacity: _titleFade.value,
                    child: child,
                  );
                },
                child: const Text(
                  "WORKER MANAGEMENT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ⭐ Subtitle Animation
              AnimatedBuilder(
                animation: _textController,
                builder: (_, child) {
                  return Opacity(
                    opacity: _subtitleFade.value,
                    child: child,
                  );
                },
                child: Text(
                  "Loading your workspace...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ⭐ Loader Fade-in
              AnimatedBuilder(
                animation: _logoController,
                builder: (_, child) {
                  return Opacity(
                    opacity: _loaderFade.value,
                    child: child,
                  );
                },
                child: const ModernLoader(
                  size: 65,
                  color: Color(0xFFFFD300),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}