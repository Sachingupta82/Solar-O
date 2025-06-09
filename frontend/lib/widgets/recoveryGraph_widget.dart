import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class RecoveryGraphBottomSheet extends StatefulWidget {
  final double totalPrice;
  final double monthlyEnergyGeneration;
  final String userId;
  final Color primaryColor;

  const RecoveryGraphBottomSheet({
    Key? key,
    required this.totalPrice,
    required this.monthlyEnergyGeneration,
    required this.userId,
    this.primaryColor = const Color(0xFF4CAF50),
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required double totalPrice,
    required double monthlyEnergyGeneration,
    required String userId,
    Color primaryColor = const Color(0xFF4CAF50),
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecoveryGraphBottomSheet(
        totalPrice: totalPrice,
        monthlyEnergyGeneration: monthlyEnergyGeneration,
        userId: userId,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<RecoveryGraphBottomSheet> createState() => _RecoveryGraphBottomSheetState();
}

class _RecoveryGraphBottomSheetState extends State<RecoveryGraphBottomSheet> with SingleTickerProviderStateMixin {
  List<FlSpot> recoveryDataPoints = [];
  bool isLoading = true;
  bool hasError = false;
  double yearsToRecover = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // For gradient and styling
  List<Color> gradientColors = [];
  List<Color> areaGradientColors = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    
    // Setup gradient colors based on primary color
    updateGradientColors();
    
    _animationController.forward();
    fetchRecoveryData();
  }
  
  void updateGradientColors() {
    // Create more vibrant gradients based on primary color
    final Color accentColor = HSLColor.fromColor(widget.primaryColor)
        .withLightness(0.7)
        .withSaturation(0.85)
        .toColor();
    
    gradientColors = [
      widget.primaryColor.withOpacity(0.7),
      accentColor,
      widget.primaryColor,
    ];
    
    areaGradientColors = [
      widget.primaryColor.withOpacity(0.5),
      widget.primaryColor.withOpacity(0.2),
      widget.primaryColor.withOpacity(0.05),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchRecoveryData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://solaro1.onrender.com/user/${widget.userId}/calculateGraph'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'totalPrice': widget.totalPrice,
          'monthlyEnergyGeneration': widget.monthlyEnergyGeneration,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recoveryDataPoints = (data['dataPoints'] as List).map((point) {
            return FlSpot(
              (point['x'] as num).toDouble(),
              double.parse(point['y'].toString()),
            );
          }).toList();
          yearsToRecover = (data['yearsToRecover'] as num).toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          heightFactor: 0.3 + (0.5 * _animation.value),
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 50,
      height: 5,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: widget.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Investment Recovery Timeline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.grey[700]),
              onPressed: () => Navigator.pop(context),
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: widget.primaryColor,
                backgroundColor: widget.primaryColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Calculating recovery timeline...',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load recovery data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: fetchRecoveryData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildAnimatedChart(),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: _buildSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedChart() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Calculate animated data points
        List<FlSpot> animatedPoints = recoveryDataPoints.map((point) {
          return FlSpot(point.x, point.y * value);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 10000,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == value.roundToDouble() && value >= 1) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            'Year ${value.toInt()}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      if (value >= 1000) {
                        text = '₹${(value / 1000).toStringAsFixed(0)}k';
                      } else {
                        text = '₹${value.toInt()}';
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    interval: 10000,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                  left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              minX: 1,
              maxX: recoveryDataPoints.isNotEmpty ? recoveryDataPoints.last.x : 7,
              minY: 0,
              maxY: recoveryDataPoints.isNotEmpty ? (recoveryDataPoints.last.y * 1.1) : 50000,
              lineBarsData: [
                LineChartBarData(
                  spots: animatedPoints,
                  isCurved: true,
                  curveSmoothness: 0.4, // Increased for more natural curve
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) {
                      // Show dots every 2 years or at the last point
                      return spot.x % 2 == 0 || spot.x == animatedPoints.last.x;
                    },
                    getDotPainter: (spot, percent, barData, index) {
                      // Special treatment for the last dot (completion point)
                      if (spot.x == animatedPoints.last.x) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: widget.primaryColor,
                          strokeWidth: 3,
                          strokeColor: Colors.white,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 4,
                        color: widget.primaryColor.withOpacity(0.8),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: areaGradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  // tooltipBgColor: Colors.blueGrey.shade800.withOpacity(0.85),
                  getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.85),
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  tooltipMargin: 12,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        'Year ${spot.x.toInt()}\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '₹${spot.y.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
                touchCallback: (event, response) {
                  // Optional: handle touch events
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    // Calculate ROI percentage
    double roi = yearsToRecover > 0 
        ? ((recoveryDataPoints.last.y / widget.totalPrice) * 100) - 100
        : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                title: 'Recovery Time',
                value: '$yearsToRecover years',
                icon: Icons.watch_later_outlined,
                color: widget.primaryColor,
                flex: 2,
                animateValue: true,
                valueToAnimate: yearsToRecover,
                isMoney: false,
              ),
              const SizedBox(width: 16),
              _buildSummaryItem(
                title: 'Total Investment',
                value: '₹${widget.totalPrice.toInt()}',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.amber.shade700,
                flex: 2,
                animateValue: true,
                valueToAnimate: widget.totalPrice,
                isMoney: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: widget.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'After ${yearsToRecover.ceil()} years, ',
                        ),
                        TextSpan(
                          text: 'your solar system will generate ',
                        ),
                        TextSpan(
                          text: 'pure profit',
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' with an estimated ROI of ',
                        ),
                        TextSpan(
                          text: '${roi.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: '!'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    int flex = 1,
    bool animateValue = false,
    double valueToAnimate = 0,
    bool isMoney = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (animateValue)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: valueToAnimate),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  String displayValue;
                  if (isMoney) {
                    displayValue = '₹${value.toInt()}';
                  } else {
                    displayValue = '${value.toStringAsFixed(1)} years';
                  }
                  return Text(
                    displayValue,
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                },
              )
            else
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}