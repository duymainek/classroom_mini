import 'package:flutter/material.dart';

class EnhancedLoadingState extends StatefulWidget {
  const EnhancedLoadingState({Key? key}) : super(key: key);

  @override
  State<EnhancedLoadingState> createState() => _EnhancedLoadingStateState();
}

class _EnhancedLoadingStateState extends State<EnhancedLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Loading Icon
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_animation.value * 0.4),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Loading Text
          Text(
            'Đang tải...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
