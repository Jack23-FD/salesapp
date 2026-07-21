import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_selection.dart';

class OnboardingScreen extends StatefulWidget {
  final bool skipAuth;

  const OnboardingScreen({super.key, this.skipAuth = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _floatController;

  final Color _brandOrange = const Color(0xFFFF8A00);
  final Color _bgGradientStart = const Color(0xFFFFFFFF);
  final Color _bgGradientEnd = const Color(0xFFFFF5E6);

  final List<WalkthroughItem> _walkthroughItems = [
    WalkthroughItem(
      title: 'Track Your Inventory',
      description:
          'Monitor stock levels, add items, and organize your inventory categories in real-time.',
      type: WalkthroughType.inventory,
    ),
    WalkthroughItem(
      title: 'Manage Sales',
      description:
          'Create invoices, process orders, and manage your sales seamlessly.',
      type: WalkthroughType.sales,
    ),
    WalkthroughItem(
      title: 'Analyze Performance',
      description:
          'Get real-time insights and detailed reports to grow your business smarter.',
      type: WalkthroughType.analytics,
    ),
    WalkthroughItem(
      title: 'Secure & Reliable',
      description:
          'Your data is safe with us. Enjoy a secure and reliable experience every day.',
      type: WalkthroughType.security,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Smooth idle float animation for 3D card
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.skipAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LanguageSelectionScreen(skipAuth: widget.skipAuth),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
    } catch (e) {
      debugPrint('Error marking onboarding complete: $e');
    }
  }

  void _onGetStartedPressed() async {
    await _markOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LanguageSelectionScreen(skipAuth: false),
      ),
    );
  }

  void _onSwipeUpTapped() {
    if (_currentPage < _walkthroughItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStartedPressed();
    }
  }

  void _onSkipPressed() async {
    await _markOnboardingComplete();
    if (!mounted) return;
    _pageController.animateToPage(
      _walkthroughItems.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical, // Swipe UP navigation
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _walkthroughItems.length,
        itemBuilder: (context, index) {
          final item = _walkthroughItems[index];
          final isLastPage = index == _walkthroughItems.length - 1;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgGradientStart, _bgGradientEnd],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Vector brand logo for perfect transparent blending
                        BrandLogo(height: 34, color: _brandOrange),
                        if (!isLastPage)
                          GestureDetector(
                            onTap: _onSkipPressed,
                            child: Text(
                              'Skip',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Middle Contents Section
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          // Floating 3D card widget
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final floatVal = _floatController.value;
                              return Transform.translate(
                                offset: Offset(0, 6 * (1.0 - floatVal)),
                                child: _build3DCard(item),
                              );
                            },
                          ),
                          const Spacer(),

                          // Title
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              item.title,
                              style: GoogleFonts.urbanist(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _brandOrange,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 36.0),
                            child: Text(
                              item.description,
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls and Page Indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isLastPage
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0, vertical: 8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _onGetStartedPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shadowColor:
                                          _brandOrange.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Get Started',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: _onSwipeUpTapped,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Swipe Up',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandOrange
                                                .withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: _brandOrange,
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 20),

                        // Page Dots Indicator matching mockups
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _walkthroughItems.length,
                            (dotIndex) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == dotIndex
                                    ? _brandOrange
                                    : _brandOrange.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 3D Card Container
  Widget _build3DCard(WalkthroughItem item) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: _brandOrange.withOpacity(0.10),
            blurRadius: 32,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glowing aura
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _brandOrange.withOpacity(0.08),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Custom 3D Illustration
          CustomPaint(
            size: const Size(190, 190),
            painter: Walkthrough3DPainter(
                type: item.type, brandColor: _brandOrange),
          ),
        ],
      ),
    );
  }
}

// Transparent vector logo representing the orange fast-moving shopping cart
class BrandLogo extends StatelessWidget {
  final double height;
  final Color color;

  const BrandLogo({
    super.key,
    this.height = 36,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Speed lines
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 14,
                height: 2.2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 20,
                height: 2.2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 15,
                height: 2.2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
          // Shopping Cart Icon
          Icon(
            Icons.shopping_cart_rounded,
            size: height * 0.82,
            color: color,
          ),
        ],
      ),
    );
  }
}

// 3D Isometric illustrations Custom Painter
class Walkthrough3DPainter extends CustomPainter {
  final WalkthroughType type;
  final Color brandColor;

  Walkthrough3DPainter({required this.type, required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case WalkthroughType.inventory:
        _paintInventory(canvas, size);
        break;
      case WalkthroughType.sales:
        _paintSales(canvas, size);
        break;
      case WalkthroughType.analytics:
        _paintAnalytics(canvas, size);
        break;
      case WalkthroughType.security:
        _paintSecurity(canvas, size);
        break;
    }
  }

  void _paintInventory(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Draw Clipboard Sheet behind box
    final docPath = Path()
      ..moveTo(cx - 30, cy - 65)
      ..lineTo(cx + 35, cy - 65)
      ..lineTo(cx + 35, cy + 15)
      ..lineTo(cx - 30, cy + 15)
      ..close();

    final docShadow = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(docPath, docShadow);

    final docPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brandColor.withOpacity(0.15), Colors.white],
      ).createShader(Rect.fromLTWH(cx - 30, cy - 65, 65, 80));
    canvas.drawPath(docPath, docPaint);

    final linePaint = Paint()
      ..color = brandColor.withOpacity(0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final ly = cy - 45 + (i * 18);
      canvas.drawLine(Offset(cx - 15, ly), Offset(cx + 20, ly), linePaint);
      canvas.drawCircle(Offset(cx - 22, ly), 3, Paint()..color = brandColor);
    }

    // 3D Isometric cardboard box
    final boxPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [brandColor.withOpacity(0.95), brandColor],
      ).createShader(Rect.fromLTWH(cx - 45, cy + 10, 90, 55));

    final boxLidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, brandColor.withOpacity(0.1)],
      ).createShader(Rect.fromLTWH(cx - 45, cy - 5, 45, 35));

    final frontLeft = Path()
      ..moveTo(cx - 45, cy + 10)
      ..lineTo(cx, cy + 30)
      ..lineTo(cx, cy + 65)
      ..lineTo(cx - 45, cy + 45)
      ..close();
    canvas.drawPath(frontLeft, boxPaint);

    final frontRight = Path()
      ..moveTo(cx, cy + 30)
      ..lineTo(cx + 45, cy + 10)
      ..lineTo(cx + 45, cy + 45)
      ..lineTo(cx, cy + 65)
      ..close();
    canvas.drawPath(frontRight, boxPaint);

    canvas.drawPath(
      frontRight,
      Paint()..color = Colors.black.withOpacity(0.12),
    );

    final lidLeft = Path()
      ..moveTo(cx - 45, cy + 10)
      ..lineTo(cx - 10, cy - 5)
      ..lineTo(cx, cy + 30)
      ..close();
    canvas.drawPath(lidLeft, boxLidPaint);
  }

  void _paintSales(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;

    final speedPaint = Paint()
      ..color = brandColor.withOpacity(0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(cx - 70, cy - 20), Offset(cx - 35, cy - 20), speedPaint);
    canvas.drawLine(Offset(cx - 80, cy), Offset(cx - 45, cy), speedPaint);
    canvas.drawLine(
        Offset(cx - 65, cy + 20), Offset(cx - 35, cy + 20), speedPaint);

    final cartPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final basketPath = Path()
      ..moveTo(cx - 35, cy - 30)
      ..lineTo(cx + 25, cy - 30)
      ..lineTo(cx + 10, cy + 15)
      ..lineTo(cx - 25, cy + 15)
      ..close();
    canvas.drawPath(basketPath, cartPaint);

    final wheelPaint = Paint()..color = brandColor;
    canvas.drawCircle(Offset(cx - 15, cy + 28), 7, wheelPaint);
    canvas.drawCircle(Offset(cx + 5, cy + 28), 7, wheelPaint);

    final framePath = Path()
      ..moveTo(cx - 35, cy - 30)
      ..lineTo(cx - 45, cy - 38)
      ..lineTo(cx - 48, cy - 38);
    canvas.drawPath(framePath, cartPaint);

    final packagePaint = Paint()
      ..shader = LinearGradient(
        colors: [brandColor.withOpacity(0.95), brandColor.withOpacity(0.7)],
      ).createShader(Rect.fromLTWH(cx - 15, cy - 20, 25, 25));
    final pkgPath = Path()
      ..moveTo(cx - 15, cy - 20)
      ..lineTo(cx + 10, cy - 20)
      ..lineTo(cx + 5, cy + 5)
      ..lineTo(cx - 10, cy + 5)
      ..close();
    canvas.drawPath(pkgPath, packagePaint);
  }

  void _paintAnalytics(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;

    final clipPath = Path()
      ..moveTo(cx - 40, cy - 50)
      ..lineTo(cx + 40, cy - 50)
      ..lineTo(cx + 40, cy + 45)
      ..lineTo(cx - 40, cy + 45)
      ..close();

    canvas.drawPath(
      clipPath,
      Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawPath(
      clipPath,
      Paint()..color = brandColor.withOpacity(0.12),
    );

    final clipTop = Path()
      ..moveTo(cx - 15, cy - 50)
      ..lineTo(cx + 15, cy - 50)
      ..lineTo(cx + 10, cy - 42)
      ..lineTo(cx - 10, cy - 42)
      ..close();
    canvas.drawPath(clipTop, Paint()..color = brandColor);

    _draw3DBar(canvas, cx - 22, cy + 30, 32, const Color(0xFFFFB74D));
    _draw3DBar(canvas, cx, cy + 30, 52, brandColor);
    _draw3DBar(canvas, cx + 22, cy + 30, 72, const Color(0xFFE65100));
  }

  void _draw3DBar(
      Canvas canvas, double x, double y, double height, Color color) {
    final barW = 12.0;

    final front = Path()
      ..moveTo(x - barW / 2, y)
      ..lineTo(x + barW / 2, y)
      ..lineTo(x + barW / 2, y - height)
      ..lineTo(x - barW / 2, y - height)
      ..close();
    canvas.drawPath(front, Paint()..color = color);

    final topFacet = Path()
      ..moveTo(x - barW / 2, y - height)
      ..lineTo(x + barW / 2, y - height)
      ..lineTo(x + barW / 2 + 4, y - height - 4)
      ..lineTo(x - barW / 2 + 4, y - height - 4)
      ..close();
    canvas.drawPath(topFacet, Paint()..color = Colors.white.withOpacity(0.4));
  }

  void _paintSecurity(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;

    final shieldPath = Path()
      ..moveTo(cx, cy - 55)
      ..quadraticBezierTo(cx + 42, cy - 55, cx + 42, cy - 10)
      ..quadraticBezierTo(cx + 42, cy + 30, cx, cy + 55)
      ..quadraticBezierTo(cx - 42, cy + 30, cx - 42, cy - 10)
      ..quadraticBezierTo(cx - 42, cy - 55, cx, cy - 55)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = brandColor.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandColor.withOpacity(0.95), brandColor],
        ).createShader(Rect.fromLTWH(cx - 42, cy - 55, 84, 110)),
    );

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    final checkPath = Path()
      ..moveTo(cx - 15, cy - 2)
      ..lineTo(cx - 3, cy + 10)
      ..lineTo(cx + 16, cy - 14);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum WalkthroughType { inventory, sales, analytics, security }

class WalkthroughItem {
  final String title;
  final String description;
  final WalkthroughType type;

  WalkthroughItem({
    required this.title,
    required this.description,
    required this.type,
  });
}
