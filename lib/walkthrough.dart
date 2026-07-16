import 'package:flutter/material.dart';
import 'language_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/typography.dart'; // Import our typography styles

class OnboardingScreen extends StatefulWidget {
  final bool skipAuth;

  const OnboardingScreen({super.key, this.skipAuth = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  final List<WalkthroughItem> _walkthroughItems = [
    WalkthroughItem(
      title: 'Lorem Ipsum de lore ko ipsum de lo',
      description:
          'Plan, manage, and celebrate your events effortlessly what would you like to do?',
      color: const Color(0xFFE0C6FF),
    ),
    WalkthroughItem(
      title: 'Lorem Ipsum de lore ko ipsum de lo',
      description:
          'Plan, manage, and celebrate your events effortlessly what would you like to do?',
      color: const Color(0xFFCED4FF),
    ),
    WalkthroughItem(
      title: 'Lorem Ipsum de lore ko ipsum de lo',
      description:
          'Plan, manage, and celebrate your events effortlessly what would you like to do?',
      color: const Color(0xFFBFC8FF),
    ),
    WalkthroughItem(
      title: 'Lorem Ipsum de lore ko ipsum de lo',
      description:
          'Plan, manage, and celebrate your events effortlessly what would you like to do?',
      color: const Color(0xFFD8C0FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();

    // If skipAuth is true, navigate directly to language selection
    if (widget.skipAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  LanguageSelectionScreen(skipAuth: widget.skipAuth)),
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isAnimating = true;
    });
    // Restart animation on page change
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
      });
    });
  }

  // Mark onboarding as completed in SharedPreferences
  Future<void> _markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      print('Onboarding marked as complete');
    } catch (e) {
      print('Error marking onboarding as complete: $e');
    }
  }

  void _onGetStartedPressed() async {
    // Mark onboarding as completed
    await _markOnboardingComplete();

    // Navigate to the language selection screen and wait for result
    if (!mounted) return;

    final selectedLanguage = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const LanguageSelectionScreen(skipAuth: false)),
    );

    // Handle the selected language
  }

  void _onSwipeUpTapped() {
    if (_currentPage < _walkthroughItems.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkipPressed() async {
    // Skip to the last page
    _pageController.animateToPage(
      _walkthroughItems.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // Also mark onboarding as completed when skipping
    await _markOnboardingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Logo - Keep this static during transitions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOGO',
                  style: AppTypography.h2,
                ),
                // Only show Skip button if not on the last page
                if (_currentPage < _walkthroughItems.length - 1)
                  GestureDetector(
                    onTap: _onSkipPressed,
                    child: Text(
                      'Skip',
                      style: AppTypography.smallButton,
                    ),
                  ),
              ],
            ),
          ),

          // Only content inside PageView animates during transition
          Expanded(
            child: ClipRect(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _walkthroughItems.length,
                onPageChanged: _onPageChanged,
                scrollDirection: Axis.vertical,
                physics: const ClampingScrollPhysics(),
                pageSnapping: true,
                padEnds: false,
                itemBuilder: (context, index) {
                  return WalkthroughPage(
                    item: _walkthroughItems[index],
                    onGetStartedPressed: _onGetStartedPressed,
                    onSkipPressed: _onSkipPressed,
                    onSwipeUpTapped: _onSwipeUpTapped,
                    animation: _fadeAnimation,
                    isLastPage: index == _walkthroughItems.length - 1,
                    isAnimating: _isAnimating,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/signup',
                  arguments: {'selectedLanguage': 'en'},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signin');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF333366),
                side: const BorderSide(color: Color(0xFF333366)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class WalkthroughItem {
  final String title;
  final String description;
  final Color color;

  WalkthroughItem({
    required this.title,
    required this.description,
    required this.color,
  });
}

class WalkthroughPage extends StatelessWidget {
  final WalkthroughItem item;
  final VoidCallback onGetStartedPressed;
  final VoidCallback onSkipPressed;
  final VoidCallback onSwipeUpTapped;
  final Animation<double> animation;
  final bool isLastPage;
  final bool isAnimating;

  const WalkthroughPage({
    super.key,
    required this.item,
    required this.onGetStartedPressed,
    required this.onSkipPressed,
    required this.onSwipeUpTapped,
    required this.animation,
    this.isLastPage = false,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FadeTransition(
        opacity: animation,
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Main Image with scroll indicator
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // Purple/blue gradient image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.color.withOpacity(0.8),
                          item.color.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Center abstract design
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.7),
                                    item.color.withOpacity(0.2),
                                  ],
                                  radius: 0.8,
                                ),
                              ),
                              child: CustomPaint(
                                painter: CurvePainter(color: item.color),
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

            const SizedBox(height: 24),

            // Title
            Text(
              item.title,
              style: AppTypography.h1.copyWith(
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              item.description,
              style: AppTypography.regularText.copyWith(
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            // Increase space here to prevent overlap
            const SizedBox(height: 50),

            // Get Started button or Swipe Up indicator
            if (isLastPage)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGetStartedPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppTypography.largeButton,
                  ),
                  child: const Text('Get Started'),
                ),
              )
            else
              Container(
                height: 60, // Fixed height for SwipeUp container
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onSwipeUpTapped,
                  child: const FloatingSwipeIndicator(),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final Color color;

  CurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    var path = Path();

    // Draw a curved design
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.7, size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class FloatingSwipeIndicator extends StatefulWidget {
  const FloatingSwipeIndicator({super.key});

  @override
  State<FloatingSwipeIndicator> createState() => _FloatingSwipeIndicatorState();
}

class _FloatingSwipeIndicatorState extends State<FloatingSwipeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Slightly slower animation
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, -0.3), // Reduced floating height
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0, // Reduced opacity change
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Reduced scale change
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Swipe Up',
                style: AppTypography.popupParagraphSentence,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF333366).withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Color(0xFF333366),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
