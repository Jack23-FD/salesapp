import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../screens/add_stock_screen.dart';
import '../screens/use_stock_screen.dart';
import '../theme/typography.dart';
import '../services/localization_service.dart';

class BottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final PageController pageController;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.pageController,
  }) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  int _previousIndex = 0;
  
  // Remove delayed initialization in favor of immediate loading
  bool _isReady = false;
  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    print("BottomNavigation: initializing");
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.85), weight: 30.0),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 40.0),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
    
    // Force ready state immediately
    _isReady = true;
    _currentLanguage = LocalizationService.currentLocale.languageCode;
    print("BottomNavigation: setting ready state immediately with language $_currentLanguage");
    
    // Additional fallback in case there's an issue with the initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isReady) {
        print("BottomNavigation: forcing ready state after first frame");
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Check if language has changed and force rebuild
  void _checkLanguage() {
    final currentLocale = LocalizationService.currentLocale;
    if (_currentLanguage != currentLocale.languageCode) {
      print("BottomNavigation: Language changed from $_currentLanguage to ${currentLocale.languageCode}, rebuilding");
      _currentLanguage = currentLocale.languageCode;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showBoundingOptions(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  context: context,
                  icon: Icons.login,
                  iconColor: Colors.green,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  title: 'inventory.addStock'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const AddStockScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                                position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    });
                  },
                  delayFactor: 0.0,
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  context: context,
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  title: 'inventory.removeStock'.tr,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const UseStockScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                                position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    });
                  },
                  delayFactor: 0.1,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required VoidCallback onTap,
    required double delayFactor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (100 * delayFactor).toInt()),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Visual feedback before performing action
            HapticFeedback.selectionClick();

            // Delay to allow ripple effect to show
            Future.delayed(const Duration(milliseconds: 150), onTap);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withOpacity(0.1),
          highlightColor: backgroundColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _animateAndNavigate({
    required BuildContext context,
    required Widget destination,
  }) {
    try {
      // Add haptic feedback
      HapticFeedback.selectionClick();

      // First close the bottom sheet
      Navigator.of(context).pop();

      // Add a small delay to ensure smooth transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!context.mounted) return;

        // Use a page route with custom animation
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // For primary animation (entering)
              var primaryCurve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );

              // Slide in from right animation
              var slideTransition = SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(primaryCurve),
                child: child,
              );

              // Fade transition
              return FadeTransition(
                opacity:
                    Tween<double>(begin: 0.0, end: 1.0).animate(primaryCurve),
                child: slideTransition,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
          ),
        );
      });
    } catch (e) {
      // Handle any navigation errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error navigating to screen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the LocalizationProvider to rebuild when language changes
    Provider.of<LocalizationProvider>(context);
    
    // Always check language when building
    _checkLanguage();
    
    // Fixed size to prevent layout shifts
    final double navBarHeight = 92.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom > 0 ? 8.0 : 0.0;
    final double totalHeight = navBarHeight + bottomPadding;
    
    print("BottomNavigation: building with _isReady = $_isReady, language = $_currentLanguage");
    
    return SizedBox(
      height: totalHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: bottomPadding,
        ),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: (index) {
            print("BottomNavigation: tab tapped at index $index, isReady=$_isReady");
            // Add haptic feedback
            HapticFeedback.selectionClick();

            if (index == 1) {
              // Stock tab
              _showBoundingOptions(context);
            } else {
              // Handle navigation for other tabs
              widget.pageController.jumpToPage(index);
              widget.onTabChanged(index);
              _controller.reset();
              _controller.forward();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 11.0,
          unselectedFontSize: 10.0,
          selectedLabelStyle: AppTypography.smallButton.copyWith(
            fontSize: 11.0,
            height: 1.0,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.smallButton.copyWith(
            fontSize: 10.0,
            height: 1.0,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: 'navigation.dashboard'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.compare_arrows),
              activeIcon: const Icon(Icons.compare_arrows),
              label: 'navigation.stock'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              activeIcon: const Icon(Icons.search),
              label: 'navigation.search'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.category_outlined),
              activeIcon: const Icon(Icons.category),
              label: 'navigation.categories'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu),
              activeIcon: const Icon(Icons.menu),
              label: 'navigation.menu'.tr,
            ),
          ],
        ),
      ),
    );
  }
}
