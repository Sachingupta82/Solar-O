import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/agents/aiAgent_screen.dart';
import 'package:frontend/screens/quotation_screen.dart';
import 'package:frontend/utils/local_storage.dart';
import 'package:frontend/widgets/helpSupport_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SolarPanel {
  final int id;
  final String brand;
  final String model;
  final String material;
  final int powerWattage;
  final double? efficiency;
  final int price;
  final double? temperatureCoefficient;
  final int warrantyYears;
  final double? degradationRate;
  final double? voc;
  final double? isc;
  final int? lowLightPerformance;
  final int? windSnowResistance;
  final String? installationType;
  final double? width;
  final double? height;
  final String score;
  final String reason;
  final String type;
  final String typeFormatted;

  SolarPanel({
    required this.id,
    required this.brand,
    required this.model,
    required this.material,
    required this.powerWattage,
    this.efficiency,
    required this.price,
    this.temperatureCoefficient,
    required this.warrantyYears,
    this.degradationRate,
    this.voc,
    this.isc,
    this.lowLightPerformance,
    this.windSnowResistance,
    this.installationType,
    this.width,
    this.height,
    required this.score,
    required this.reason,
    required this.type,
    required this.typeFormatted,
  });

  Color get color {
    switch (type) {
      case "bestRecommended":
        return Colors.blue.shade700;
      case "HighestPrice":
        return Colors.purple.shade700;
      case "LowestPrice":
        return Colors.green.shade700;
      case "AveragePrice":
        return Colors.orange.shade700;
      case "Onemorebest":
        return Colors.teal.shade700;
      default:
        return Colors.deepOrange;
    }
  }
}

class MyCardsScreen extends StatefulWidget {
  final Uint8List? mapImage;

  const MyCardsScreen({Key? key, this.mapImage}) : super(key: key);

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isAnimating = false;
  Offset _dragStartPosition = Offset.zero;
  bool _isLoading = true;
  final SharedPreferencesManager prefsManager = SharedPreferencesManager();
  String? id;
  double? savedAvgBillPrice;
  double? savedAvgPowerConsumption;
  double? savedPerUnitPrice;
  double? savedSanctionedLoad;
  Map<String, dynamic>? location;
  String? namee;

  List<SolarPanel> featuredPanels = [];
  List<SolarPanel> allPanels = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
        _animationController.reset();
      }
    });
  }

  Future<void> _initializeData() async {
    await loadLocalData();
    if (id != null) {
      _fetchSolarPanelData();
    } else {
      print("ID is null, skipping API call");
    }
  }

  Future<void> loadLocalData() async {
    id = await prefsManager.getString("id");
    namee = await prefsManager.getString("name");
    savedAvgBillPrice = await prefsManager.getDouble("average_bill_price");
    savedAvgPowerConsumption =
        await prefsManager.getDouble("average_power_consumption");
    savedPerUnitPrice = await prefsManager.getDouble("per_unit_price");
    savedSanctionedLoad = await prefsManager.getDouble("sanctioned_load");
    location = await prefsManager.getMap("location");

    print("Loaded ID: $id"); // Debugging log
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void loadlocalData() async {
    namee = await prefsManager.getString("name");
    savedAvgBillPrice = await prefsManager.getDouble("average_bill_price");
    savedAvgPowerConsumption =
        await prefsManager.getDouble("average_power_consumption");
    savedPerUnitPrice = await prefsManager.getDouble("per_unit_price");
    savedSanctionedLoad = await prefsManager.getDouble("sanctioned_load");
    location = await prefsManager.getMap("location");
    id = await prefsManager.getString("id");
  }

  // Function to fetch solar panel data from API
  Future<void> _fetchSolarPanelData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('https://solaro1.onrender.com/user/$id/solardata'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Clear existing lists
        featuredPanels.clear();
        allPanels.clear();

        // Process featured panels (recommendations)
        final Map<String, dynamic> featured = {
          'bestRecommended': data.containsKey('bestRecommended')
              ? data['bestRecommended']
              : null,
          'HighestPrice':
              data.containsKey('HighestPrice') ? data['HighestPrice'] : null,
          'LowestPrice':
              data.containsKey('LowestPrice') ? data['LowestPrice'] : null,
          'AveragePrice':
              data.containsKey('AveragePrice') ? data['AveragePrice'] : null,
          'Onemorebest':
              data.containsKey('Onemorebest') ? data['Onemorebest'] : null,
        };

        // Add featured panels to both lists
        featured.forEach((key, value) {
          if (value != null) {
            SolarPanel panel = _createSolarPanelFromJson(value, key);
            featuredPanels.add(panel);
            allPanels.add(panel); 
          }
        });

        // Add regular panels to allPanels list
        if (data.containsKey('panels') && data['panels'] is List) {
          for (var panel in data['panels']) {
            SolarPanel regularPanel =
                _createSolarPanelFromJson(panel, 'regular');
            allPanels.add(regularPanel);
          }
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to create a SolarPanel object from JSON
  SolarPanel _createSolarPanelFromJson(Map<String, dynamic> json, String type) {
    return SolarPanel(
      id: json['id'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      material: json['material'] ?? '',
      powerWattage: json['power_wattage'] ?? 0,
      efficiency: json['efficiency']?.toDouble(),
      price: json['price'] ?? 0,
      temperatureCoefficient: json['temperature_coefficient']?.toDouble(),
      warrantyYears: json['warranty_years'] ?? 0,
      degradationRate: json['degradation_rate']?.toDouble(),
      voc: json['voc']?.toDouble(),
      isc: json['isc']?.toDouble(),
      lowLightPerformance: json['low_light_performance'],
      windSnowResistance: json['wind_snow_resistance'],
      installationType: json['installation_type'],
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      score: json['score']?.toString() ?? '',
      reason: json['reason'] ?? '',
      type: type,
      typeFormatted: _formatRecommendationType(type),
    );
  }

  String _formatRecommendationType(String type) {
    if (type == "bestRecommended") return "Best Recommended";
    if (type == "HighestPrice") return "Highest Price";
    if (type == "LowestPrice") return "Lowest Price";
    if (type == "AveragePrice") return "Average Price";
    if (type == "Onemorebest") return "Also Recommended";
    if (type == "regular") return "Regular Panel";
    return type;
  }

  List<SolarPanel> get _orderedPanels {
    if (featuredPanels.isEmpty) return [];

    final result = List<SolarPanel>.from(featuredPanels);
    if (_currentIndex > 0) {
      final frontPanels = result.sublist(0, _currentIndex);
      result.removeRange(0, _currentIndex);
      result.addAll(frontPanels);
    }
    return result;
  }

  void _nextCard() {
    if (_isAnimating || featuredPanels.isEmpty) return;

    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % featuredPanels.length;
      });
    });
  }

  void _prevCard() {
    if (_isAnimating || featuredPanels.isEmpty) return;

    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      setState(() {
        _currentIndex =
            (_currentIndex - 1 + featuredPanels.length) % featuredPanels.length;
      });
    });
  }

  void _showPanelDetails(BuildContext context, SolarPanel panel) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PanelDetailScreen(panel: panel, id: id!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Solar Panel Recommendations',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card stack
                SizedBox(
                  height: 300,
                  child: featuredPanels.isEmpty
                      ? const Center(
                          child: Text('No recommendations available'))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background cards (stacked)
                            for (int i = min(2, featuredPanels.length - 1);
                                i >= 0;
                                i--)
                              Positioned(
                                left: 15.0 * (2 - i),
                                top: 35.0 * (2 - i),
                                child: AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) {
                                    double offset = 0;
                                    double scale = 1.0;

                                    if (_isAnimating) {
                                      if (i == 0) {
                                        // Moving out card
                                        offset =
                                            _animation.value * size.width * 0.8;
                                        scale = 1.0 - (_animation.value * 0.1);
                                      } else if (i == 1) {
                                        // Next card moving forward
                                        scale = 1.0 + (_animation.value * 0.05);
                                      }
                                    }

                                    return Transform.translate(
                                      offset: Offset(offset, 0),
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: i == 2
                                              ? 0.7
                                              : i == 1
                                                  ? 0.85
                                                  : 1.0,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildCardStack(i),
                                ),
                              ),

                            // Navigation indicators
                            Positioned(
                              bottom: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  featuredPanels.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentIndex == index
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // All Panels section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'All Panels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'See All',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // All panels list
                Expanded(
                  child: allPanels.isEmpty
                      ? const Center(child: Text('No panels available'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: allPanels.length,
                          itemBuilder: (context, index) {
                            final panel = allPanels[index];
                            return _buildPanelItem(panel);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: AICallButton(
  onAICall: () async {
    makeCall(
      id.toString(),
      savedAvgBillPrice,
      savedAvgPowerConsumption,
      savedPerUnitPrice,
      savedSanctionedLoad,
      location,
      namee,
    );
  },
  phoneNumber: id.toString(),
  savedAvgBillPrice: savedAvgBillPrice,
  savedAvgPowerConsumption: savedAvgPowerConsumption,
  savedPerUnitPrice: savedPerUnitPrice,
  savedSanctionedLoad: savedSanctionedLoad,
  location: location,
  namee: namee,
),
    );
  }

  Widget _buildCardStack(int index) {
    if (featuredPanels.isEmpty || index >= _orderedPanels.length) {
      return Container(); 
    }

    final panel = _orderedPanels[index];
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (index == 0) {
          _dragStartPosition = details.globalPosition;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (index == 0 && !_isAnimating) {
          final dragDistance =
              details.globalPosition.dx - _dragStartPosition.dx;
          // Optional: You can add visual feedback during drag here
        }
      },
      onHorizontalDragEnd: (details) {
        if (index == 0 && !_isAnimating) {
          if (details.primaryVelocity! > 300) {
            _nextCard();
          } else {
            final dragDistance = details.primaryVelocity ?? 0;
            if (dragDistance.abs() > 50) {
              dragDistance > 0 ? _nextCard() : _prevCard();
            }
          }
        }
      },
      onTap: index == 0 ? () => _showPanelDetails(context, panel) : null,
      child: Hero(
        tag: 'stack_panel_${panel.id}_${panel.type}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: cardWidth - (index * 20),
            height: 200 - (index * 10),
            child: Row(
              children: [
                // Main colored card
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: panel.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          panel.typeFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (index == 0) ...[
                          const Icon(
                            Icons.solar_power,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            panel.model,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.verified_user,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                '${panel.warrantyYears} Year Warranty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Card info (white part) - Only show for the front card
                if (index == 0)
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '₹${panel.price}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Power',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${panel.powerWattage}W',
                            style: TextStyle(
                              color: panel.color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            panel.material,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 8),
                            decoration: BoxDecoration(
                              color: panel.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Know More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(width: 1),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildActionButton(String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPanelItem(SolarPanel panel) {
    final Color primaryGreen = const Color(0xFF26A69A);
    final Color surfaceColor = Colors.white;
    final Color accentColor = panel.color ?? primaryGreen;

    return GestureDetector(
      onTap: () => _showPanelDetails(context, panel),
      child: Hero(
        tag: 'panel_${panel.id}_${panel.type}',
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.08),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Background pattern (subtle)
                  Positioned(
                    right: -15,
                    top: -15,
                    child: Opacity(
                      opacity: 0.03,
                      child: Icon(
                        Icons.solar_power,
                        size: 100,
                        color: accentColor,
                      ),
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content area
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Panel image/icon with premium shadow effect
                            Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background design element
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            accentColor.withOpacity(0),
                                            accentColor.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Icon
                                  Icon(
                                    Icons.solar_power,
                                    color: accentColor,
                                    size: 36,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 15),

                            // Panel details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Efficiency indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.eco,
                                              size: 12,
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Efficient',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      // Price with premium styling
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor,
                                              accentColor.withGreen(
                                                  (accentColor.green + 20)
                                                      .clamp(0, 255)),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '₹${panel.price}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  // Brand and model with modern typography
                                  Text(
                                    panel.brand,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    panel.model,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Specifications row
                                  Row(
                                    children: [
                                      _buildSpecItem(
                                        icon: Icons.bolt,
                                        value: '${panel.powerWattage}W',
                                        label: 'Power',
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSpecItem(
                                        icon: Icons.layers,
                                        value: panel.material,
                                        label: 'Material',
                                        color: Colors.amber.shade700,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom action bar with glass effect
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Warranty info
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '15 Year Warranty',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // View details button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Detail screen that shows when a panel is tapped
class PanelDetailScreen extends StatefulWidget {
  final SolarPanel panel;
  final String id;

  const PanelDetailScreen({Key? key, required this.panel, required this.id})
      : super(key: key);

  @override
  State<PanelDetailScreen> createState() => _PanelDetailScreenState();
}

class _PanelDetailScreenState extends State<PanelDetailScreen> {
  Future<void> requestInstallationQuote(SolarPanel panel) async {
    final Map<String, dynamic> requestBody = {
      "panelInfo": {
        "id": panel.id,
        "brand": panel.brand,
        "model": panel.model,
        "material": panel.material,
        "power_wattage": panel.powerWattage,
        "price": panel.price,
        "warranty_years": panel.warrantyYears,
        "efficiency": panel.efficiency ?? 22.6,
        "temperature_coefficient": panel.temperatureCoefficient ?? -0.26,
        "degradation_rate": panel.degradationRate ?? 0.25,
        "voc": panel.voc ?? 69.5,
        "isc": panel.isc ?? 6.2,
        "low_light_performance": panel.lowLightPerformance ?? 92,
        "wind_snow_resistance": panel.windSnowResistance ?? 5400,
        "installation_type":
            panel.installationType ?? "Flat Roof, Slanted Roof",
        "width": panel.width ?? 1.80,
        "height": panel.height ?? 1.05,
        "score": panel.score,
        "reason": panel.reason
      }
    };

    final url = Uri.parse(
        'https://solaro1.onrender.com/user/${widget.id}/electricityCalculation');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        print('Installation Quote Response Sent successfully');
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print(responseData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SolarQuotationScreen(
              solarData: responseData,
              panelWatt: panel.powerWattage.ceilToDouble(),
              panelPrice: panel.price.ceilToDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // App bar with hero animation
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: widget.panel.color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.panel.model,
                style: const TextStyle(color: Colors.white),
              ),
              background: Hero(
                tag: 'panel_${widget.panel.id}_${widget.panel.type}',
                child: Container(
                  color: widget.panel.color,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        top: 60,
                        child: Icon(
                          Icons.solar_power,
                          color: Colors.white.withOpacity(0.2),
                          size: 120,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                widget.panel.typeFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand and model
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.solar_power,
                          color: widget.panel.color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.panel.brand,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              widget.panel.model,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recommendation score and reason
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommendation Score',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.panel.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.panel.score,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, color: Colors.amber),
                            const Icon(Icons.star, color: Colors.amber),
                            const Icon(Icons.star, color: Colors.amber),
                            const Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star_half, color: Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Why this panel?',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.panel.reason,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Technical specifications
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical Specifications',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSpecItem('Material', widget.panel.material),
                        _buildSpecItem(
                            'Power Output', '${widget.panel.powerWattage}W'),
                        _buildSpecItem(
                            'Warranty', '${widget.panel.warrantyYears} Years'),
                        _buildSpecItem('Price', '₹${widget.panel.price}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comparison with other panels
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Comparison',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // Text(
                            //   'View All',
                            //   style: TextStyle(
                            //     color: panel.color,
                            //     fontWeight: FontWeight.bold,
                            //     fontSize: 14,
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildComparisonChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        requestInstallationQuote(widget.panel);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.panel.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Request Installation Quote',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.panel.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.panel.model,
                      style: TextStyle(
                        color: widget.panel.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Average Panel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildComparisonRow(
              'Efficiency',
              '${(double.parse(widget.panel.score) / 10 * 100).toStringAsFixed(1)}%',
              '15.7%'),
          _buildComparisonRow(
              'Lifespan', '${widget.panel.warrantyYears} years', '10 years'),
          _buildComparisonRow('Power', '${widget.panel.powerWattage}W', '350W'),
          _buildComparisonRow(
              'Price/W',
              '₹${(widget.panel.price / widget.panel.powerWattage).toStringAsFixed(2)}',
              '₹45.00'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: widget.panel.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value1,
                style: TextStyle(
                  color: widget.panel.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value2,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function
int min(int a, int b) {
  return a < b ? a : b;
}
