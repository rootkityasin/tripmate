import 'package:flutter/material.dart';

class AnimatedBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final double height;

  const AnimatedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = Colors.white,
    this.selectedColor = const Color(0xFF007AFF),
    this.unselectedColor = const Color(0xFF8E8E93),
    this.height = 80.0,
  });

  @override
  State<AnimatedBottomNavigationBar> createState() => _AnimatedBottomNavigationBarState();
}

class _AnimatedBottomNavigationBarState extends State<AnimatedBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _animation;
  late Animation<double> _rippleAnimation;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0);
      _rippleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Animated background indicator
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: _calculateIndicatorPosition(),
                  top: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _calculateIndicatorWidth(),
                    height: widget.height - 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.selectedColor.withOpacity(0.15),
                          widget.selectedColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                );
              },
            ),
            
            // Ripple effect
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _calculateRipplePosition(),
                  top: widget.height / 2 - 25,
                  child: Container(
                    width: 50 * _rippleAnimation.value,
                    height: 50 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      color: widget.selectedColor.withOpacity(0.2 * (1 - _rippleAnimation.value)),
                      shape: BoxShape.circle,
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
                  child: GestureDetector(
                    onTap: () {
                      widget.onTap(index);
                    },
                    child: Container(
                      height: widget.height,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final scale = isSelected ? (0.9 + (0.2 * _animation.value)) : 1.0;
                          final iconScale = isSelected ? (0.8 + (0.4 * _animation.value)) : 1.0;
                          
                          return Transform.scale(
                            scale: scale,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon with bounce animation
                                Transform.scale(
                                  scale: iconScale,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            color: widget.selectedColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: widget.selectedColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Icon(
                                      item.icon,
                                      color: isSelected ? Colors.white : widget.unselectedColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                
                                // Label with fade animation
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: _animation.value,
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: widget.selectedColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateIndicatorPosition() {
    final itemWidth = (MediaQuery.of(context).size.width - 32) / widget.items.length;
    return (itemWidth * widget.currentIndex) + 8;
  }

  double _calculateIndicatorWidth() {
    final totalWidth = MediaQuery.of(context).size.width - 32;
    return (totalWidth / widget.items.length) - 16;
  }

  double _calculateRipplePosition() {
    final itemWidth = (MediaQuery.of(context).size.width - 32) / widget.items.length;
    return (itemWidth * widget.currentIndex) + (itemWidth / 2) - 25;
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}

// Alternative floating navigation bar with more premium animations
class FloatingAnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const FloatingAnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingAnimatedNavBar> createState() => _FloatingAnimatedNavBarState();
}

class _FloatingAnimatedNavBarState extends State<FloatingAnimatedNavBar>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FloatingAnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _bubbleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Morphing background bubble
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return Positioned(
                left: _getBubblePosition(),
                top: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
                child: GestureDetector(
                  onTapDown: (_) => _scaleController.forward(),
                  onTapUp: (_) => _scaleController.reverse(),
                  onTapCancel: () => _scaleController.reverse(),
                  onTap: () => widget.onTap(index),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_bubbleController, _scaleController]),
                    builder: (context, child) {
                      final scale = isSelected && _scaleController.isAnimating ? 0.9 : 1.0;
                      
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          height: 70,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                transform: Matrix4.identity()
                                  ..translate(0.0, isSelected ? -2.0 : 0.0),
                                child: Icon(
                                  item.icon,
                                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                                  size: isSelected ? 26 : 24,
                                ),
                              ),
                              if (!isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getBubblePosition() {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    final itemWidth = screenWidth / widget.items.length;
    return (itemWidth * widget.currentIndex) + (itemWidth / 2) - 30;
  }
}
