import 'dart:ui';
import 'package:flutter/material.dart';

// Highly visible liquid glass navigation bar matching TripMate's color scheme
class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> with TickerProviderStateMixin {
  late AnimationController _liquidController;
  late AnimationController _glowController;
  late AnimationController _floatController;

  late Animation<double> _liquidAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;

  // TripMate app color scheme
  static const Color primaryColor = Color(0xFF2D3748); // Dark gray-blue
  static const Color accentColor = Color(0xFF4FD1C7); // Teal accent
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white

  @override
  void initState() {
    super.initState();

    _liquidController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _liquidAnimation = CurvedAnimation(parent: _liquidController, curve: Curves.easeInOutCubic);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _liquidController, curve: Curves.easeOutBack));

    _floatController.repeat(reverse: true);

    // Initialize with current state
    _liquidController.forward();
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _liquidController.reset();
      _liquidController.forward();
      _glowController.reset();
      _glowController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -1 * _floatAnimation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    // Glass effect with TripMate colors - highly visible
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        surfaceColor.withOpacity(0.95), // Very opaque white
                        surfaceColor.withOpacity(0.90),
                        surfaceColor.withOpacity(0.92),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.15), // Visible border
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15), // Strong shadow
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Teal glow effect
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: _calculateGlowPosition(),
                            top: 10,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    accentColor.withOpacity(0.5 * _glowAnimation.value),
                                    Colors.transparent,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),

                      // Animated teal blob for selected item
                      AnimatedBuilder(
                        animation: _liquidAnimation,
                        builder: (context, child) {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            left: _calculateBlobPosition(),
                            top: 6,
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    width: _calculateBlobWidth(),
                                    height: 53,
                                    decoration: BoxDecoration(
                                      // Vibrant teal gradient
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accentColor,
                                          accentColor.withOpacity(0.9),
                                          const Color(0xFF81E6D9), // Lighter teal
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(31.5),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.4),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.5),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.3),
                                          blurRadius: 25,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.items[widget.currentIndex].icon,
                                            color: surfaceColor, // White icon
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            widget.items[widget.currentIndex].label,
                                            style: TextStyle(
                                              color: surfaceColor, // White text
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              shadows: [
                                                Shadow(
                                                  color: primaryColor.withOpacity(0.3),
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Interactive navigation items (always on top)
                      SizedBox(
                        height: 65,
                        child: Row(
                          children: widget.items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isSelected = index == widget.currentIndex;

                            return Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(32),
                                  onTap: () {
                                    print('Tapped item $index: ${item.label}'); // Debug
                                    widget.onTap(index);
                                  },
                                  child: SizedBox(
                                    height: 65,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: isSelected ? 0.0 : 1.0, // Hide when selected
                                      child: Center(
                                        child: Icon(
                                          item.icon,
                                          color: primaryColor.withOpacity(
                                            0.8,
                                          ), // Dark visible icons
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Shimmer effect (non-interactive)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: CustomPaint(painter: ShimmerPainter(_floatAnimation.value)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateBlobPosition() {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final itemWidth = screenWidth / widget.items.length;
    return (itemWidth * widget.currentIndex) + 6;
  }

  double _calculateBlobWidth() {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final baseWidth = screenWidth / widget.items.length - 12;
    return baseWidth.clamp(130.0, 170.0);
  }

  double _calculateGlowPosition() {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final itemWidth = screenWidth / widget.items.length;
    return (itemWidth * widget.currentIndex) + (itemWidth / 2) - 25;
  }
}

// Custom painter for shimmer effect
class ShimmerPainter extends CustomPainter {
  final double animationValue;

  ShimmerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFF4FD1C7).withOpacity(0.1 * animationValue), // Teal shimmer
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({required this.icon, required this.label});
}
