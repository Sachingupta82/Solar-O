import 'dart:math' as math;
import 'package:flutter/material.dart';

class SolarLoadingAnimation extends StatefulWidget {
  final String loadingText;
  final String completeText;
  final Color sunColor;
  final Color panelColor;
  final bool showText;

  const SolarLoadingAnimation({
    Key? key,
    this.loadingText = "Sending Solar Data...",
    this.completeText = "Upload Complete!",
    this.sunColor = Colors.amber,
    this.panelColor = const Color(0xFF1E3A8A), // deep blue
    this.showText = true,
  }) : super(key: key);

  @override
  State<SolarLoadingAnimation> createState() => _SolarLoadingAnimationState();
}

class _SolarLoadingAnimationState extends State<SolarLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _energyController;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Sun rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Sun ray pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Solar energy particles animation
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // This will show completion after 5 seconds for demo purposes
    // In real usage, you would set this based on your API call completion
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Solar animation
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              children: [
                // Solar panel - slightly tilted at the bottom
                Positioned(
                  bottom: 5,
                  left: 15,
                  right: 15,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateX(0.5), // tilt forward
                    alignment: Alignment.center,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: widget.panelColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        padding: const EdgeInsets.all(4),
                        children: List.generate(12, (index) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: widget.panelColor.withOpacity(0.7),
                                width: 1,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                
                // Spinning sun with pulsing rays
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_rotationController, _pulseController]),
                    builder: (context, child) {
                      return Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sun glow effect
                            Container(
                              width: 60 + (_pulseController.value * 15),
                              height: 60 + (_pulseController.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.sunColor.withOpacity(0.5),
                                    blurRadius: 20 + (_pulseController.value * 10),
                                    spreadRadius: 5 + (_pulseController.value * 5),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Sun rays
                            Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: Stack(
                                alignment: Alignment.center,
                                children: List.generate(8, (index) {
                                  return Transform.rotate(
                                    angle: index * math.pi / 4,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        height: 18 + (_pulseController.value * 6), // Ray length pulsing
                                        width: 3,
                                        decoration: BoxDecoration(
                                          color: widget.sunColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            
                            // Sun core
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.sunColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Energy particles from sun to panel
                if (!isCompleted) 
                  AnimatedBuilder(
                    animation: _energyController,
                    builder: (context, child) {
                      return Stack(
                        children: List.generate(5, (index) {
                          final position = _energyController.value + (index * 0.2);
                          final normalizedPos = position > 1.0 ? position - 1.0 : position;
                          
                          // Calculate particle position on a curve from sun to panel
                          double topPos = 35 + (normalizedPos * 60); // vertical position
                          double leftPos = 75 - (normalizedPos * math.sin(normalizedPos * math.pi) * 30);
                          
                          return Positioned(
                            top: topPos,
                            left: leftPos,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: widget.sunColor.withOpacity(1.0 - normalizedPos),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.sunColor.withOpacity(0.6 - (normalizedPos * 0.6)),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Loading text
          if (widget.showText) 
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isCompleted 
                ? Text(
                    widget.completeText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                : Text(
                    widget.loadingText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.panelColor,
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}