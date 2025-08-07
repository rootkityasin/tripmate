import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/navigation_item.dart';

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

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // TripMate Colors
  static const Color _primaryColor = Color(0xFF2D3748);
  static const Color _accentColor = Color(0xFF4FD1C7);
  static const Color _surfaceColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _surfaceColor.withOpacity(0.9),
                  _surfaceColor.withOpacity(0.8),
                  _surfaceColor.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _primaryColor.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Selection indicator
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: _calculateIndicatorPosition(),
                      top: 8,
                      child: Container(
                        width: _calculateIndicatorWidth(),
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accentColor,
                              _accentColor.withOpacity(0.8),
                              const Color(0xFF81E6D9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.items[widget.currentIndex].icon,
                                color: _surfaceColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.items[widget.currentIndex].label,
                                style: const TextStyle(
                                  color: _surfaceColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Navigation items
                Row(
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == widget.currentIndex;

                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => widget.onTap(index),
                          child: SizedBox(
                            height: 60,
                            child: Center(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isSelected ? 0.0 : 1.0,
                                child: Icon(
                                  item.icon,
                                  color: _primaryColor.withOpacity(0.7),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateIndicatorPosition() {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final itemWidth = screenWidth / widget.items.length;
    return (itemWidth * widget.currentIndex) + 8;
  }

  double _calculateIndicatorWidth() {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final baseWidth = screenWidth / widget.items.length - 16;
    return baseWidth.clamp(120.0, 160.0);
  }
}
