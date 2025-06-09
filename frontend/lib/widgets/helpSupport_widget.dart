// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math' as math;
// import 'package:lottie/lottie.dart'; 

// class ExpandableOptions extends StatefulWidget {
//   final VoidCallback onAICall;
//   final VoidCallback onChatbot;
//   final String phoneNumber;
//   final double? savedAvgBillPrice;
//   final double? savedAvgPowerConsumption;
//   final double? savedPerUnitPrice;
//   final double? savedSanctionedLoad;
//   final Map<String, dynamic>? location;
//   final String? namee;

//   const ExpandableOptions({
//     Key? key,
//     required this.onAICall,
//     required this.onChatbot,
//     required this.phoneNumber,
//     this.savedAvgBillPrice,
//     this.savedAvgPowerConsumption,
//     this.savedPerUnitPrice,
//     this.savedSanctionedLoad,
//     this.location,
//     this.namee,
//   }) : super(key: key);

//   @override
//   _ExpandableOptionsState createState() => _ExpandableOptionsState();
// }

// class _ExpandableOptionsState extends State<ExpandableOptions>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   bool _isExpanded = false;
  
//   // Solar theme colors
//   final Color solarYellow = const Color(0xFFFFD600);
//   final Color solarOrange = const Color(0xFFFF9800);
//   final Color solarDeepOrange = const Color(0xFFFF5722);
//   final Color solarBlue = const Color(0xFF2196F3);

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _toggleExpanded() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Options when expanded
//         AnimatedSizeAndFade(
//           vsync: this,
//           show: _isExpanded,
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 16.0),
//             child: Column(
//               children: [
//                 // Chatbot option
//                 FloatingActionButton(
//                   heroTag: "chatbot",
//                   backgroundColor: solarBlue,
//                   onPressed: () {
//                     _toggleExpanded();
//                     widget.onChatbot();
//                   },
//                   child: const Icon(Icons.chat, color: Colors.white),
//                 ),
//                 const SizedBox(height: 16),
//                 // Swipe to call option
//                 SwipeToCallButton(
//                   onCallComplete: () {
//                     _toggleExpanded();
//                     widget.onAICall();
//                   },
//                   phoneNumber: widget.phoneNumber,
//                   savedAvgBillPrice: widget.savedAvgBillPrice,
//                   savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
//                   savedPerUnitPrice: widget.savedPerUnitPrice,
//                   savedSanctionedLoad: widget.savedSanctionedLoad,
//                   location: widget.location,
//                   namee: widget.namee,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Main floating action button
//         FloatingActionButton(
//           backgroundColor: solarDeepOrange,
//           onPressed: _toggleExpanded,
//           child: AnimatedIcon(
//             icon: AnimatedIcons.menu_close,
//             progress: _controller,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class AnimatedSizeAndFade extends StatelessWidget {
//   final TickerProvider vsync;
//   final bool show;
//   final Widget child;

//   const AnimatedSizeAndFade({
//     Key? key,
//     required this.vsync,
//     required this.show,
//     required this.child,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSize(
//       duration: const Duration(milliseconds: 200),
//       child: AnimatedOpacity(
//         opacity: show ? 1.0 : 0.0,
//         duration: const Duration(milliseconds: 200),
//         child: SizedBox(
//           height: show ? null : 0.0,
//           child: show ? child : const SizedBox(),
//         ),
//       ),
//     );
//   }
// }

// class SwipeToCallButton extends StatefulWidget {
//   final VoidCallback onCallComplete;
//   final String phoneNumber;
//   final double? savedAvgBillPrice;
//   final double? savedAvgPowerConsumption;
//   final double? savedPerUnitPrice;
//   final double? savedSanctionedLoad;
//   final Map<String, dynamic>? location;
//   final String? namee;

//   const SwipeToCallButton({
//     Key? key,
//     required this.onCallComplete,
//     required this.phoneNumber,
//     this.savedAvgBillPrice,
//     this.savedAvgPowerConsumption,
//     this.savedPerUnitPrice,
//     this.savedSanctionedLoad,
//     this.location,
//     this.namee,
//   }) : super(key: key);

//   @override
//   _SwipeToCallButtonState createState() => _SwipeToCallButtonState();
// }

// class _SwipeToCallButtonState extends State<SwipeToCallButton> {
//   double _dragExtent = 0;
//   bool _dragCompleted = false;
//   final double _dragThreshold = 200.0;
//   bool _showCallAnimation = false;

//   final Color solarGreen = const Color(0xFF4CAF50);
//   final Color solarOrange = const Color(0xFFFF9800);

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // Base container with call action indicator
//         Container(
//           width: _dragThreshold + 60,
//           height: 56,
//           decoration: BoxDecoration(
//             color: Colors.grey.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Icon(
//                 Icons.call,
//                 color: solarGreen,
//               ),
//               const SizedBox(width: 16),
//             ],
//           ),
//         ),
//         // Swipe to call text
//         Positioned(
//           left: 20,
//           child: Text(
//             "Swipe to call",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: solarGreen,
//             ),
//           ),
//         ),
//         // Draggable button
//         Positioned(
//           left: _dragExtent,
//           child: GestureDetector(
//             onHorizontalDragUpdate: (details) {
//               if (_dragCompleted) return;
//               setState(() {
//                 _dragExtent += details.delta.dx;
//                 if (_dragExtent < 0) _dragExtent = 0;
//                 if (_dragExtent > _dragThreshold) _dragExtent = _dragThreshold;
//               });
//             },
//             onHorizontalDragEnd: (details) {
//               if (_dragExtent >= _dragThreshold) {
//                 setState(() {
//                   _dragCompleted = true;
//                   _showCallAnimation = true;
//                 });
                
//                 // Show calling animation for a few seconds
//                 Future.delayed(const Duration(seconds: 2), () {
//                   if (mounted) {
//                     widget.onCallComplete();
//                   }
//                 });
//               } else {
//                 setState(() {
//                   _dragExtent = 0;
//                 });
//               }
//             },
//             child: Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [solarOrange, solarGreen],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(28),
//               ),
//               child: _showCallAnimation
//                   ? Lottie.asset(
//                       'assets/phone_ringing.json', 
//                       fit: BoxFit.contain,
//                     )
//                   : const Icon(
//                       Icons.phone,
//                       color: Colors.white,
//                     ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // Modified AICallButton to use the new components
// class AICallButton extends StatefulWidget {
//   final VoidCallback onAICall;
//   final String phoneNumber;
//   final double? savedAvgBillPrice;
//   final double? savedAvgPowerConsumption;
//   final double? savedPerUnitPrice;
//   final double? savedSanctionedLoad;
//   final Map<String, dynamic>? location;
//   final String? namee;

//   const AICallButton({
//     Key? key,
//     required this.onAICall,
//     required this.phoneNumber,
//     this.savedAvgBillPrice,
//     this.savedAvgPowerConsumption,
//     this.savedPerUnitPrice,
//     this.savedSanctionedLoad,
//     this.location,
//     this.namee,
//   }) : super(key: key);

//   @override
//   _AICallButtonState createState() => _AICallButtonState();
// }

// class _AICallButtonState extends State<AICallButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _rotationAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     _rotationAnimation = TweenSequence<double>([
//       TweenSequenceItem(
//         tween: Tween(begin: 0.0, end: 0.1)
//             .chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 1.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween(begin: 0.1, end: -0.1)
//             .chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 2.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween(begin: -0.1, end: 0.07)
//             .chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 2.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween(begin: 0.07, end: -0.05)
//             .chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 1.0,
//       ),
//       TweenSequenceItem(
//         tween: Tween(begin: -0.05, end: 0.0)
//             .chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 1.0,
//       ),
//     ]).animate(_controller);

//     Timer.periodic(const Duration(seconds: 10), (timer) {
//       _controller.forward(from: 0);
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void navigateToChatScreen() {
//     // Navigator.push(
//     //   context,
//     //   MaterialPageRoute(
//     //     builder: (context) => ChatScreen(
//     //       number: widget.phoneNumber,
//     //       savedAvgBillPrice: widget.savedAvgBillPrice,
//     //       savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
//     //       savedPerUnitPrice: widget.savedPerUnitPrice,
//     //       savedSanctionedLoad: widget.savedSanctionedLoad,
//     //       location: widget.location,
//     //       namee: widget.namee,
//     //     ),
//     //   ),
//     // );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Transform.rotate(
//           angle: _rotationAnimation.value * math.pi,
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 20.0, right: 15),
//             child: ExpandableOptions(
//               onAICall: widget.onAICall,
//               onChatbot: navigateToChatScreen,
//               phoneNumber: widget.phoneNumber,
//               savedAvgBillPrice: widget.savedAvgBillPrice,
//               savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
//               savedPerUnitPrice: widget.savedPerUnitPrice,
//               savedSanctionedLoad: widget.savedSanctionedLoad,
//               location: widget.location,
//               namee: widget.namee,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:frontend/agents/chat_agents.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';

class ExpandableOptions extends StatefulWidget {
  final VoidCallback onAICall;
  final VoidCallback onChatbot;
  final String phoneNumber;
  final double? savedAvgBillPrice;
  final double? savedAvgPowerConsumption;
  final double? savedPerUnitPrice;
  final double? savedSanctionedLoad;
  final Map<String, dynamic>? location;
  final String? namee;

  const ExpandableOptions({
    Key? key,
    required this.onAICall,
    required this.onChatbot,
    required this.phoneNumber,
    this.savedAvgBillPrice,
    this.savedAvgPowerConsumption,
    this.savedPerUnitPrice,
    this.savedSanctionedLoad,
    this.location,
    this.namee,
  }) : super(key: key);

  @override
  _ExpandableOptionsState createState() => _ExpandableOptionsState();
}

class _ExpandableOptionsState extends State<ExpandableOptions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;
  
  // Professional green and white color scheme with matte finish
  final Color primaryGreen = const Color(0xFF2E7D32); // Deep green
  final Color lightGreen = const Color(0xFF4CAF50);   // Standard green
  final Color paleGreen = const Color(0xFFE8F5E9);    // Very light green
  final Color matteWhite = const Color(0xFFF5F5F5);   // Off-white for matte finish

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _showOptionsDialog();
      } else {
        _controller.reverse();
      }
    });
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: matteWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Contact Options',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat button with same width as swipe to call
              SizedBox(
                width: 280,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onChatbot();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Chat Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Swipe to call button
              SwipeToCallButton(
                onCallComplete: () {
                  Navigator.of(context).pop();
                  widget.onAICall();
                },
                phoneNumber: widget.phoneNumber,
                savedAvgBillPrice: widget.savedAvgBillPrice,
                savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
                savedPerUnitPrice: widget.savedPerUnitPrice,
                savedSanctionedLoad: widget.savedSanctionedLoad,
                location: widget.location,
                namee: widget.namee,
                colorScheme: {
                  'primary': primaryGreen,
                  'light': lightGreen,
                  'pale': paleGreen,
                  'white': matteWhite,
                },
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        );
      },
    ).then((_) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: primaryGreen,
      onPressed: _toggleExpanded,
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _controller,
        color: Colors.white,
      ),
    );
  }
}

class SwipeToCallButton extends StatefulWidget {
  final VoidCallback onCallComplete;
  final String phoneNumber;
  final double? savedAvgBillPrice;
  final double? savedAvgPowerConsumption;
  final double? savedPerUnitPrice;
  final double? savedSanctionedLoad;
  final Map<String, dynamic>? location;
  final String? namee;
  final Map<String, Color> colorScheme;

  const SwipeToCallButton({
    Key? key,
    required this.onCallComplete,
    required this.phoneNumber,
    this.savedAvgBillPrice,
    this.savedAvgPowerConsumption,
    this.savedPerUnitPrice,
    this.savedSanctionedLoad,
    this.location,
    this.namee,
    required this.colorScheme,
  }) : super(key: key);

  @override
  _SwipeToCallButtonState createState() => _SwipeToCallButtonState();
}

class _SwipeToCallButtonState extends State<SwipeToCallButton> {
  double _dragExtent = 0;
  bool _dragCompleted = false;
  final double _dragThreshold = 210.0;  // Increased for better sliding space
  bool _showCallAnimation = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 56,
      decoration: BoxDecoration(
        color: widget.colorScheme['pale'],
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: widget.colorScheme['light']!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base container with call action indicator
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.call,
                  color: widget.colorScheme['primary'],
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          // Swipe to call text
          Positioned(
            left: 70,
            child: Text(
              "Swipe to call",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.colorScheme['primary'],
              ),
            ),
          ),
          // Draggable button
          Positioned(
            left: _dragExtent,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_dragCompleted) return;
                setState(() {
                  _dragExtent += details.delta.dx;
                  if (_dragExtent < 0) _dragExtent = 0;
                  if (_dragExtent > _dragThreshold) _dragExtent = _dragThreshold;
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragExtent >= _dragThreshold) {
                  setState(() {
                    _dragCompleted = true;
                    _showCallAnimation = true;
                  });
                  
                  // Show calling animation for a few seconds
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      widget.onCallComplete();
                    }
                  });
                } else {
                  setState(() {
                    _dragExtent = 0;
                  });
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colorScheme['light']!,
                      widget.colorScheme['primary']!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colorScheme['primary']!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _showCallAnimation
                    ? Lottie.asset(
                        'assets/phone_ringing.json',
                        fit: BoxFit.contain,
                      )
                    : const Icon(
                        Icons.phone,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AICallButton extends StatefulWidget {
  final VoidCallback onAICall;
  final String phoneNumber;
  final double? savedAvgBillPrice;
  final double? savedAvgPowerConsumption;
  final double? savedPerUnitPrice;
  final double? savedSanctionedLoad;
  final Map<String, dynamic>? location;
  final String? namee;

  const AICallButton({
    Key? key,
    required this.onAICall,
    required this.phoneNumber,
    this.savedAvgBillPrice,
    this.savedAvgPowerConsumption,
    this.savedPerUnitPrice,
    this.savedSanctionedLoad,
    this.location,
    this.namee,
  }) : super(key: key);

  @override
  _AICallButtonState createState() => _AICallButtonState();
}

class _AICallButtonState extends State<AICallButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.1, end: 0.07)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.07, end: -0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
    ]).animate(_controller);

    Timer.periodic(const Duration(seconds: 10), (timer) {
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * math.pi,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 15),
            child: ExpandableOptions(
              onAICall: widget.onAICall,
              onChatbot: navigateToChatScreen,
              phoneNumber: widget.phoneNumber,
              savedAvgBillPrice: widget.savedAvgBillPrice,
              savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
              savedPerUnitPrice: widget.savedPerUnitPrice,
              savedSanctionedLoad: widget.savedSanctionedLoad,
              location: widget.location,
              namee: widget.namee,
            ),
          ),
        );
      },
    );
  }


    void navigateToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          number: widget.phoneNumber,
          savedAvgBillPrice: widget.savedAvgBillPrice,
          savedAvgPowerConsumption: widget.savedAvgPowerConsumption,
          savedPerUnitPrice: widget.savedPerUnitPrice,
          savedSanctionedLoad: widget.savedSanctionedLoad,
          location: widget.location,
          namee: widget.namee,
        ),
      ),
    );
  }
}