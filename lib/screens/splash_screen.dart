import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../providers/category_provider.dart';
import '../navigation/role_based_navigation.dart';
import 'auth_check_screen.dart';
import '../auth/signin.dart';
import '../walkthrough.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fireController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  Timer? _navigationTimer;

  final List<Particle> _particles = List.generate(24, (index) => Particle());

  @override
  void initState() {
    super.initState();

    // Fire flame loop animation
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // Scale & entrance animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleController.forward();

    // Auto navigate after 2.8 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    // Preload data
    await itemProvider.loadFromLocalStorage();
    await categoryProvider.reloadFromLocalStorage();

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool('onboardingComplete') ?? false;

    Widget targetScreen;

    if (!hasCompletedOnboarding) {
      targetScreen = const OnboardingScreen();
    } else if (authProvider.isAuthenticated && authProvider.user != null) {
      targetScreen = RoleBasedNavigation.getHomeScreen(authProvider.user!);
    } else if (authProvider.isAuthenticated) {
      targetScreen = const AuthCheckScreen();
    } else {
      targetScreen = const SignInScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fireController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate Background
      body: Stack(
        children: [
          // Ambient Animated Fire Flame Glow Particles in background
          AnimatedBuilder(
            animation: _fireController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: FireGlowPainter(
                  progress: _fireController.value,
                  particles: _particles,
                ),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with pulsing fire aura & scale animation
                AnimatedBuilder(
                  animation: _fireController,
                  builder: (context, child) {
                    final pulse = math.sin(_fireController.value * math.pi * 2);
                    final glowSize = 130 + (pulse * 10);

                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _logoOpacityAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing Outer Supermarket Aura Ring
                            Container(
                              width: glowSize,
                              height: glowSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B259)
                                        .withOpacity(0.5 + (pulse * 0.2)),
                                    blurRadius: 40,
                                    spreadRadius: 15,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00BBF9)
                                        .withOpacity(0.3 + (pulse * 0.15)),
                                    blurRadius: 60,
                                    spreadRadius: 25,
                                  ),
                                ],
                              ),
                            ),

                            // White Glowing Container for Supermarket Icon / Logo
                            Container(
                              width: 115,
                              height: 115,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B259)
                                        .withOpacity(0.6),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // App Title Text - Supermarket POS
                FadeTransition(
                  opacity: _logoOpacityAnimation,
                  child: Column(
                    children: [
                      Text(
                        'SUPERMARKET POS',
                        style: GoogleFonts.urbanist(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B259).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00B259).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          'Fresh Produce • Quick Checkout • Smart Inventory',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00B259),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Fire Flame Progress Bar
                AnimatedBuilder(
                  animation: _fireController,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: ((_fireController.value * 0.8) + 0.2)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00BBF9),
                                    Color(0xFFFF3D00),
                                    Color(0xFFFFD600),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00BBF9)
                                        .withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class for rising fire sparks
class Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 4 + 2;
  double speed = math.Random().nextDouble() * 0.008 + 0.003;
  double opacity = math.Random().nextDouble() * 0.7 + 0.3;
}

// Custom Painter to render rising fire flame sparks & glowing energy
class FireGlowPainter extends CustomPainter {
  final double progress;
  final List<Particle> particles;

  FireGlowPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw central fire aura
    final firePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00BBF9).withOpacity(0.22),
          const Color(0xFFFF3D00).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 180));

    canvas.drawCircle(center, 180, firePaint);

    // Draw rising fire spark particles
    for (var particle in particles) {
      particle.y -= particle.speed;
      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = math.Random().nextDouble();
      }

      final px = particle.x * size.width;
      final py = particle.y * size.height;

      final sparkPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF00BBF9),
          const Color(0xFFFFD600),
          math.Random().nextDouble(),
        )!
            .withOpacity(particle.opacity * (1.0 - particle.y))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), particle.size, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
