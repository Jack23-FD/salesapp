import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/date_formatter.dart';
import 'custom_calendar.dart';
import '../../utils/translation_utils.dart';
import '../../services/localization_service.dart';

class DateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime?) onDateSelected;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleCalendar() {
    if (_overlayEntry == null) {
      _animationController.forward();
      _showOverlay();
    } else {
      _animationController.reverse();
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    // Add a listener to close the overlay when tapping outside
    Future.delayed(Duration.zero, () {
      GestureBinding.instance.pointerRouter.addGlobalRoute((event) {
        // If the overlay is showing and user taps outside
        if (_overlayEntry != null &&
            event is PointerDownEvent &&
            !_isInsideOverlay(event.position)) {
          // Remove global listener
          GestureBinding.instance.pointerRouter
              .removeGlobalRoute(_handlePointerEvent);
          // Close the calendar
          _animationController.reverse();
          _removeOverlay();
        }
      });
    });
  }

  bool _isInsideOverlay(Offset position) {
    if (_overlayEntry == null) return false;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final overlayPosition = renderBox.localToGlobal(Offset.zero);

    final calendarHeight =
        450.0; // Increased to accommodate all calendar components

    // Define the bounds of the date selector button
    final buttonRect = Rect.fromLTWH(
        overlayPosition.dx, overlayPosition.dy, size.width, size.height);

    // Define the bounds of the calendar popup
    final calendarRect = Rect.fromLTWH(overlayPosition.dx,
        overlayPosition.dy + size.height + 8, size.width, calendarHeight);

    // Check if the position is inside either the button or the calendar
    return buttonRect.contains(position) || calendarRect.contains(position);
  }

  void _handlePointerEvent(PointerEvent event) {
    // This function exists to be able to remove the route
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay for the whole screen
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                tween: Tween<double>(begin: 0.0, end: 0.5),
                builder: (context, value, _) {
                  return Container(
                    color: Colors.black.withOpacity(value),
                  );
                },
              ),
            ),

            // Pointer interceptor that closes the calendar on tap
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCalendar,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Calendar popup
            Positioned(
              left: offset.dx,
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: CustomCalendar(
                    selectedDate: widget.selectedDate,
                    onDateSelected: (date) {
                      widget.onDateSelected(date);
                      _toggleCalendar();
                    },
                    onClose: _toggleCalendar,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current locale to force rebuild when language changes
    final locale = Provider.of<LocalizationProvider>(context).locale;
    
    // Get translated text for the label
    final String selectedDateLabel = 'dashboard.selectedDate'.translate();
    
    print("DateSelector: Translating 'dashboard.selectedDate' = '$selectedDateLabel' (locale: ${locale.languageCode})");
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: _toggleCalendar,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333366).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF333366),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDateLabel,
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.w500,
                                fontSize: _calculateFontSize(selectedDateLabel, 14.0),
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.formatDate(widget.selectedDate),
                              style: GoogleFonts.urbanist(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.0,
                                color: const Color(0xFF333366),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF333366),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to calculate font size based on text length
  double _calculateFontSize(String text, double baseSize) {
    // Check if current language is English - don't adjust font size for English
    if (LocalizationService.currentLocale.languageCode == 'en') {
      return baseSize;
    }
    
    // Adjust font size for other languages based on text length
    if (text.length <= 15) {
      return baseSize;
    } else if (text.length <= 25) {
      return baseSize - 1.0;
    } else if (text.length <= 35) {
      return baseSize - 2.0;
    } else {
      return baseSize - 3.0;
    }
  }
}
