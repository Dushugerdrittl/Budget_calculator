import 'package:flutter/material.dart';

class WelcomeAnimationScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onAnimationComplete;

  const WelcomeAnimationScreen({
    super.key,
    required this.userName,
    required this.onAnimationComplete,
  });

  @override
  State<WelcomeAnimationScreen> createState() => _WelcomeAnimationScreenState();
}

class _WelcomeAnimationScreenState extends State<WelcomeAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimationKitty;
  late Animation<Offset> _slideAnimationText1; // For "Welcome, userName!"
  late Animation<Offset> _slideAnimationText2; // For "So glad to see you!"

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800), // Total animation time
      vsync: this,
    );

    // Fade in for all elements
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation for the image
    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.1,
          0.7,
          curve: Curves.elasticOut,
        ), // Playful bounce
      ),
    );

    // Slide animation for Kitty image (from bottom)
    _slideAnimationKitty = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Slide animation for the first text line
    _slideAnimationText1 = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.4,
          0.85,
          curve: Curves.easeOutCubic,
        ), // Adjusted interval
      ),
    );

    // Slide animation for the second text line (more delayed)
    _slideAnimationText2 = Tween<Offset>(
      begin: const Offset(0, 0.4), // Start slightly lower or same
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.55,
          0.95,
          curve: Curves.easeOutCubic,
        ), // Adjusted and delayed interval
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Add a small delay *after* animation completes
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            widget.onAnimationComplete();
          }
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50,
              Colors.pink.shade100,
              Colors.pink.shade200,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _slideAnimationKitty,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/images/wellcome.jpg', // <-- Changed to .jpg
                      width: 160,
                      height: 160,
                      semanticLabel: 'App Logo',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SlideTransition(
                position: _slideAnimationText1,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Welcome, ${widget.userName}!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade700,
                      fontFamily: 'Comic Sans MS',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SlideTransition(
                position: _slideAnimationText2,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'So glad to see you!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.pink.shade500,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
