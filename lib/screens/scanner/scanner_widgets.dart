import 'package:flutter/material.dart';

class ScannerControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ScannerControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF333366),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF333366),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerFrame extends StatelessWidget {
  const ScannerFrame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF333366),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Corner markers
          ...List.generate(4, (index) {
            final isTop = index < 2;
            final isLeft = index.isEven;
            return Positioned(
              left: isLeft ? 0 : null,
              right: !isLeft ? 0 : null,
              top: isTop ? 0 : null,
              bottom: !isTop ? 0 : null,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF333366).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTop && isLeft ? 10 : 0),
                    topRight: Radius.circular(isTop && !isLeft ? 10 : 0),
                    bottomLeft: Radius.circular(!isTop && isLeft ? 10 : 0),
                    bottomRight: Radius.circular(!isTop && !isLeft ? 10 : 0),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const ActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF333366),
                side: const BorderSide(color: Color(0xFF333366)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
