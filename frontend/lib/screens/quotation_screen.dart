import 'dart:ui';
import 'dart:convert';
import 'package:frontend/screens/supportingImages_screen.dart';
import 'package:frontend/utils/local_storage.dart';
import 'package:frontend/widgets/recoveryGraph_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


Future<void> updateQuotation(String id,int panelCount,double monthlyenergy,int inverters,String insatallation,int totalvalue) async {
  final String url = 'https://solaro1.onrender.com/user/$id/quotation';

  final Map<String, dynamic> body = {
    "panelCount": panelCount,
    "monthlyEnergyGeneration": monthlyenergy,
    "numberofinverter": inverters,
    "installationType": insatallation,
    "totalQuotation": totalvalue,
  };

  try {
    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('Quotation updated successfully!');
      print('Response: ${response.body}');
    } else {
      print('Failed to update quotation. Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error updating quotation: $e');
  }
}

class SolarQuotationScreen extends StatefulWidget {
  final Map<String, dynamic> solarData;
  final double panelWatt;
  final double panelPrice;

  const SolarQuotationScreen({
    Key? key,
    required this.solarData,
    required this.panelWatt,
    required this.panelPrice,
  }) : super(key: key);

  @override
  _SolarQuotationScreenState createState() => _SolarQuotationScreenState();
}

class _SolarQuotationScreenState extends State<SolarQuotationScreen> {
  late int selectedPanelCount;
  bool isOnGrid = true;
  String selectedBattery = "5 kWh";
  final List<String> batteryOptions = ["3 kWh", "5 kWh", "7.5 kWh", "10 kWh"];
  String? userid;
  double? SanctionedLoad;

  // Financial calculations
  late double totalPanelCost;
  late double subsidyAmount;
  late double finalCost;
  late int requiredInverters;
  late double batteryCost;
  
  // Energy calculations
  late double scaledDailyEnergy;
  late double scaledMonthlyEnergy;
  late double scaledYearlyEnergy;

  // Theme colors
  final primaryGreen = const Color(0xFF2E7D32);
  final accentGreen = const Color(0xFF66BB6A);
  final lightGreen = const Color(0xFFE8F5E9);
  
  // Define currencyFormat as a class field
  final currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'hi_IN',
  );

  @override
  void initState(){
    super.initState();
    selectedPanelCount = widget.solarData['recommendedPanelCount'];
    getuserId();
    calculateCosts();
    updateEnergyValues();

  }

  Future<void>getuserId() async {
   final SharedPreferencesManager prefsManager = SharedPreferencesManager();
      final String? userId = await prefsManager.getString("id");
      double? savedSanctionedLoad = await prefsManager.getDouble("sanctioned_load");
      SanctionedLoad = savedSanctionedLoad;
      userid = userId; 
      selectedPanelCount = widget.solarData['recommendedPanelCount'];
  }

  void updateEnergyValues() {
    // Calculate scaling factor based on selected panels vs recommended panels
    double scalingFactor = selectedPanelCount.toDouble() ;
    
// Extract just the numeric part and parse it
String dailyEnergyStr = widget.solarData['finalDailyEnergy'].toString();
String monthlyEnergyStr = widget.solarData['monthlyEnergy'].toString();
String yearlyEnergyStr = widget.solarData['yearlyEnergy'].toString();
String recommendedPanelMonthlyEnergy = widget.solarData['yearlyEnergy'].toString();

// Extract just the number part using regex
RegExp numericRegex = RegExp(r'(\d+\.?\d*)');
double dailyValue = double.parse(numericRegex.firstMatch(dailyEnergyStr)?.group(1) ?? '0');
double monthlyValue = double.parse(numericRegex.firstMatch(monthlyEnergyStr)?.group(1) ?? '0');
double yearlyValue = double.parse(numericRegex.firstMatch(yearlyEnergyStr)?.group(1) ?? '0');

// Calculate scaled values
scaledDailyEnergy = dailyValue * scalingFactor;
scaledMonthlyEnergy = monthlyValue * scalingFactor;
scaledYearlyEnergy = yearlyValue * scalingFactor;
  }

  void calculateCosts() {
    // Calculate panel cost
    totalPanelCost = selectedPanelCount * widget.panelPrice;
    
    // Calculate subsidy (only for on-grid systems)
    subsidyAmount = isOnGrid ? calculateSubsidy() : 0.0;
    
    // Calculate battery cost if off-grid
    batteryCost = !isOnGrid ? getBatteryCost(selectedBattery) : 0.0;
    
    // Calculate required inverters (approximately 1 inverter per 10 panels)
    requiredInverters = (selectedPanelCount / 10).ceil();
    
    // Inverter cost calculation (average cost ₹15,000 per inverter)
    double inverterCost = requiredInverters * 15000;
    
    // Calculate final cost
    finalCost = totalPanelCost + inverterCost + batteryCost - subsidyAmount;
    
    // Update energy values whenever costs are calculated
    updateEnergyValues();
  }

  double calculateSubsidy() {
  double totalCapacity = selectedPanelCount * widget.panelWatt / 1000; 
  double subsidy = 0.0;

  if (totalCapacity <= 2) {
    subsidy = 30000; // ₹30,000 for 1-2 kW
  } else if (totalCapacity <= 3) {
    subsidy = 60000; // ₹60,000 for 2-3 kW
  } else if (totalCapacity > 3) {
    subsidy = 78000; // ₹78,000 for above 3 kW
  }

  return subsidy;
}

  double getBatteryCost(String capacity) {
    // Approximate battery costs based on capacity
    switch (capacity) {
      case "3 kWh":
        return 120000;
      case "5 kWh":
        return 180000;
      case "7.5 kWh":
        return 250000;
      case "10 kWh":
        return 320000;
      default:
        return 180000;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Solar System Quotation",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: primaryGreen),
            onPressed: () {
              // Show info dialog
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent System Type toggle at the top
                  _buildSystemTypeToggle(),
                  
                  const SizedBox(height: 24),
                  
                  // Solar energy details card
                  _buildInfoCard(
                    "Solar Energy Generation",
                    [],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Panel selection section
                  _buildSectionTitle("Solar Panel Configuration"),
                  
                  const SizedBox(height: 12),
                  
                  _buildPanelSelectionCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Battery section for off-grid
                  if (!isOnGrid) ...[
                    _buildSectionTitle("Battery Configuration"),
                    
                    const SizedBox(height: 12),
                    
                    _buildBatterySelectionCard(),
                    
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle("Inverter Requirements"),
                  
                  const SizedBox(height: 12),
                  
                  _buildInverterCard(),
                  
                  const SizedBox(height: 12),
                  _buildRoiButton(),
                  const SizedBox(height: 12),
                  _buildSectionTitle("Cost Breakdown"),
                  const SizedBox(height: 12),
                  _buildCostBreakdownCard(),
                  const SizedBox(height: 30),
                  _buildActionButton(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoiButton() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: InkWell(
      onTap: () {
        RecoveryGraphBottomSheet.show(
          context,
          totalPrice: finalCost, 
          monthlyEnergyGeneration: scaledMonthlyEnergy, 
          userId: userid!,
          primaryColor: primaryGreen,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryGreen.withOpacity(0.8),
              primaryGreen,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Investment Recovery",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "See when your system pays for itself",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoCard(String title, List<Map<String, dynamic>> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Daily",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "${scaledDailyEnergy.toStringAsFixed(1)} kWh",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monthly",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "${scaledMonthlyEnergy.toStringAsFixed(1)} kWh",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Yearly",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "${scaledYearlyEnergy.toStringAsFixed(1)} kWh",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTypeToggle() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Type",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isOnGrid = false;
                          calculateCosts();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isOnGrid ? primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Off-Grid",
                            style: TextStyle(
                              color: !isOnGrid ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isOnGrid = true;
                          calculateCosts();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isOnGrid ? primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "On-Grid",
                            style: TextStyle(
                              color: isOnGrid ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isOnGrid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentGreen),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Eligible for Surya Ghar Yojana Subsidy",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isOnGrid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentGreen),
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_charging_full, color: primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Battery backup for power outages",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSelectionCard() {
  final int recommendedCount = (widget.solarData['recommendedPanelCount'] * 0.7).round();

  if (selectedPanelCount == 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        selectedPanelCount = recommendedCount;
        calculateCosts();
      });
    });
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutBack,
    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Colors.grey.shade50,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: primaryGreen.withOpacity(0.1),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated header
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Animated icon with pulse effect
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.9, end: 1.1),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeInOutSine,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [primaryGreen, primaryGreen.withBlue(180)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.solar_power,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SOLAR PANEL CONFIGURATION",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Select Your System Size",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Panel quantity selection with interactive elements
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Circular counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom circular buttons with animations
                          _buildAnimatedButton(
                            Icons.remove_rounded,
                            () {
                              if (selectedPanelCount > 1) {
                                setState(() {
                                  selectedPanelCount--;
                                  calculateCosts();
                                });
                              }
                            },
                            selectedPanelCount > 1 ? primaryGreen : Colors.grey.shade300,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Animated counter display
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: selectedPanelCount == 0 ? recommendedCount : selectedPanelCount, end: selectedPanelCount == 0 ? recommendedCount : selectedPanelCount),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring with gradient
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryGreen.withOpacity(0.5),
                                          primaryGreen.withOpacity(0.7),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryGreen.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Inner circle with counter
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        transitionBuilder: (Widget child, Animation<double> animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "$value",
                                          key: ValueKey<int>(value),
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Progress indicator
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                      value: value / widget.solarData['panelCount'],
                                      strokeWidth: 5,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(width: 16),
                          
                          _buildAnimatedButton(
                            Icons.add_rounded,
                            () {
                              if (selectedPanelCount < widget.solarData['panelCount']) {
                                setState(() {
                                  selectedPanelCount++;
                                  calculateCosts();
                                });
                              }
                            },
                            selectedPanelCount < widget.solarData['panelCount'] ? primaryGreen : Colors.grey.shade300,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Recommended panel indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Recommended: ${widget.solarData['recommendedPanelCount']} panels",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Interactive visual panel selector
                      SizedBox(
                        height: 60,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // Background track
                                Container(
                                  height: 15,
                                  margin: const EdgeInsets.symmetric(horizontal: 25),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                
                                // Filled track based on selection
                                Container(
                                  height: 15,
                                  width: (constraints.maxWidth - 50) * (selectedPanelCount / widget.solarData['panelCount']),
                                  margin: const EdgeInsets.symmetric(horizontal: 25),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        primaryGreen,
                                        primaryGreen.withGreen((primaryGreen.green + 40).clamp(0, 255)),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Panel indicators
                                ...List.generate(
                                  5,
                                  (index) {
                                    final position = (index + 1) * (widget.solarData['panelCount'] / 5);
                                    final isSelected = selectedPanelCount >= position;
                                    
                                    return Positioned(
                                      left: 25 + (constraints.maxWidth - 50) * (position / widget.solarData['panelCount']) - 10,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? primaryGreen : Colors.grey.shade300,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? primaryGreen.withOpacity(0.3)
                                                      : Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${position.round()}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? primaryGreen : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                // Interactive gesture detector
                                Positioned.fill(
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (details) {
                                      final RenderBox box = context.findRenderObject() as RenderBox;
                                      final Offset localPosition = box.globalToLocal(details.globalPosition);
                                      
                                      // Calculate the new panel count based on drag position
                                      final double percent = (localPosition.dx - 25).clamp(0, constraints.maxWidth - 50) / (constraints.maxWidth - 50);
                                      final int newCount = (percent * widget.solarData['panelCount']).round().clamp(1, widget.solarData['panelCount']) as int;
                                      
                                      if (newCount != selectedPanelCount) {
                                        setState(() {
                                          selectedPanelCount = newCount;
                                          calculateCosts();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // System specifications
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 40),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SYSTEM SPECIFICATIONS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Animated info cards
                    Row(
                      children: [
                        _buildAnimatedInfoCard(
                          "System Size",
                          "${(selectedPanelCount * widget.panelWatt / 1000).toStringAsFixed(2)} kW",
                          Icons.power_rounded,
                          Colors.blue.shade600,
                          animation: selectedPanelCount > 0,
                        ),
                        const SizedBox(width: 12),
                        _buildAnimatedInfoCard(
                          "Daily Output",
                          "${(selectedPanelCount * widget.panelWatt * 4.5 / 1000).toStringAsFixed(1)} kWh",
                          Icons.wb_sunny_rounded,
                          Colors.amber.shade600,
                          animation: selectedPanelCount > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAnimatedInfoCard(
                          "Total Cost",
                          currencyFormat.format(selectedPanelCount * widget.panelPrice),
                          Icons.currency_rupee_rounded,
                          Colors.green.shade600,
                          animation: selectedPanelCount > 0,
                        ),
                        const SizedBox(width: 12),
                        _buildAnimatedInfoCard(
                          "Panel Type",
                          "${widget.panelWatt}W ",
                          Icons.format_list_bulleted_rounded,
                          Colors.purple.shade600,
                          animation: selectedPanelCount > 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Animated CTA button
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      // Proceed to next step with selected panel count
                      // Add your navigation logic here
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryGreen,
                            primaryGreen.withGreen((primaryGreen.green + 30).clamp(0, 255)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.2),
                            blurRadius: 5,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$selectedPanelCount PANELS SELECTED",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          // const SizedBox(width: 10),
                          // const Icon(
                          //   Icons.panel,
                          //   color: Colors.white,
                          //   size: 20,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Animated button with hover effect
Widget _buildAnimatedButton(IconData icon, VoidCallback? onTap, Color color) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
      ),
    ),
  );
}

// Animated info card with real-time updates
Widget _buildAnimatedInfoCard(String title, String value, IconData icon, Color color, {bool animation = false}) {
  return Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: const Offset(0, 0),
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBatterySelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.battery_charging_full, color: primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  "Battery Capacity",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedBattery,
                  icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: batteryOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedBattery = newValue;
                        calculateCosts();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Battery Cost: ${currencyFormat.format(batteryCost)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInverterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.electrical_services, color: primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  "Inverter Requirements",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$requiredInverters",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Inverters Required",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currencyFormat.format(requiredInverters * 15000),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Inverter Cost",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  "Cost Breakdown",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCostRow("Solar Panel Cost", totalPanelCost),
            const SizedBox(height: 8),
            _buildCostRow("Inverter Cost", requiredInverters * 15000),
            
            if (!isOnGrid) ...[
              const SizedBox(height: 8),
              _buildCostRow("Battery Cost", batteryCost),
            ],
            
            if (isOnGrid && subsidyAmount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings, color: primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Surya Ghar Yojana Subsidy",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "- ${currencyFormat.format(subsidyAmount)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "* Government subsidy applied as per Surya Ghar Yojana scheme",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Cost",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currencyFormat.format(finalCost),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15),
        ),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        onPressed: () {
          updateQuotation(userid!,selectedPanelCount , scaledMonthlyEnergy, requiredInverters, isOnGrid?'On-Grid':'Off-Grid', finalCost.toInt());
          
          Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>Assesment_Images(),
        ),
      );
          print("======= SOLAR QUOTATION DETAILS =======");
          print("Number of Panels: $selectedPanelCount");
          print("Panel Wattage: ${widget.panelWatt}W");
          print("Panel Price: ${currencyFormat.format(widget.panelPrice)}");
          print("System Type: ${isOnGrid ? 'On-Grid' : 'Off-Grid'}");
          if (!isOnGrid) {
            print("Battery Capacity: $selectedBattery");
            print("Battery Cost: ${currencyFormat.format(batteryCost)}");
          }
          print("Number of Inverters: $requiredInverters");
          print("Inverter Cost: ${currencyFormat.format(requiredInverters * 15000)}");
          print("Total Panel Cost: ${currencyFormat.format(totalPanelCost)}");
          if (isOnGrid) {
            print("Subsidy Amount: ${currencyFormat.format(subsidyAmount)}");
          }
          print("Final Cost: ${currencyFormat.format(finalCost)}");
          print("=====================================");
          
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Quote generated! Check console for details.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.next_plan),
            SizedBox(width: 8),
            Text(
              "Next",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 20),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}



































