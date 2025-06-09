
import 'dart:async';
import 'dart:io';
import 'dart:math' show min, pi, sin;
import 'dart:typed_data';  
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/screens/panelsExplore_screen.dart';
import 'package:frontend/utils/local_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';  
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:weather/weather.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
// import 'panelsExplore_screen.dart';
import '../widgets/solarloading_animation.dart';

class RooftopCalculator extends StatefulWidget {
  const RooftopCalculator({super.key});

  @override
  _RooftopCalculatorState createState() => _RooftopCalculatorState();
}

class _RooftopCalculatorState extends State<RooftopCalculator> {
  GoogleMapController? mapController;
  Set<Polygon> polygons = {};
  Map<MarkerId, Marker> markers = {};
  List<LatLng> polygonPoints = [];
  TextEditingController searchController = TextEditingController();
  double? calculatedArea;
  int markerIdCounter = 1;
  bool showResults = false;
  Weather? currentWeather;
  String weatherApiKey = dotenv.env['Weather_API']!;
  WeatherFactory? weatherFactory;
  final String figtreeFontFamily = GoogleFonts.figtree().fontFamily!;
  Position? currentPosition;
  String? weatherStatus;
  final SharedPreferencesManager prefsManager = SharedPreferencesManager();
  List<Prediction> _placesPredictions = [];
  bool isLoading = false;
  final places = GoogleMapsPlaces(apiKey: dotenv.env['Maps_API']!);
  BitmapDescriptor? customMarkerIcon;
  Timer? _debounce;
  
  // Add these for map screenshot functionality
  GlobalKey mapKey = GlobalKey();
  Uint8List? mapImage;

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory(weatherApiKey);
    _getCurrentLocation();
    searchController.addListener(_onSearchChanged);
    _createCustomMarkerIcon();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _showCapturedMapDialog() async {
  Uint8List? imageData = await prefsManager.getBytes("mapScreenshot");

  if (imageData != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Captured Map Image"),
          content: Image.memory(imageData),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print("Taking to next page");
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No captured map image found!')),
    );
  }
}




  Future<void> _captureMapWithPolygon() async {
  try {
    if (polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No polygon drawn to capture!')),
      );
      return;
    }

    // Step 1: Calculate the tight bounds of the polygon with minimal padding
    LatLngBounds bounds = _calculatePolygonBoundsWithPadding(polygonPoints, padding: 0.0001); // Very little padding

    // Step 2: Zoom the camera to tightly fit the polygon bounds
    await mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 5)); // Minimal padding in pixels

    // Wait for the map to settle after animation
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Capture the zoomed-in map image
    RenderRepaintBoundary boundary = mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      Uint8List fullImage = byteData.buffer.asUint8List();

      // Step 4: Crop the image to a square based on the polygon area
      Uint8List croppedImage = await _cropToSquarePolygonArea(fullImage, bounds);

      setState(() {
        mapImage = croppedImage; // Store the cropped square image
      });

      // Save to local storage
      await prefsManager.saveBytes("mapScreenshot", mapImage!);
      _showCapturedMapDialog();
      print('Successfully captured and cropped zoomed-in polygon area to square');
    }
  } catch (e) {
    print('Error capturing map screenshot: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error capturing map image: ${e.toString()}')),
    );
  }
}

// Helper method to calculate polygon bounds with minimal padding
LatLngBounds _calculatePolygonBoundsWithPadding(List<LatLng> points, {double padding = 0.0001}) {
  double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
  double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
  double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
  double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

  return LatLngBounds(
    southwest: LatLng(minLat - padding, minLng - padding),
    northeast: LatLng(maxLat + padding, maxLng + padding),
  );
}

// Helper method to crop the image to a square based on the polygon area
Future<Uint8List> _cropToSquarePolygonArea(Uint8List fullImage, LatLngBounds bounds) async {
  // Decode the full image
  ui.Image decodedImage = await decodeImageFromList(fullImage);

  // Get image dimensions
  int imageWidth = decodedImage.width;
  int imageHeight = decodedImage.height;

  // Calculate the aspect ratio of the polygon bounds
  double latSpan = bounds.northeast.latitude - bounds.southwest.latitude;
  double lngSpan = bounds.northeast.longitude - bounds.southwest.longitude;
  double boundsAspectRatio = lngSpan / latSpan; // Width / Height in geographic terms

  // Determine the target square size based on the smaller dimension
  int squareSize = min(imageWidth, imageHeight);

  // Adjust the crop area to center on the polygon and make it square
  int cropWidth, cropHeight, cropX, cropY;

  if (boundsAspectRatio > 1) {
    // Polygon is wider than tall, base crop on width
    cropWidth = squareSize;
    cropHeight = (squareSize / boundsAspectRatio).round();
  } else {
    // Polygon is taller than wide or square, base crop on height
    cropHeight = squareSize;
    cropWidth = (squareSize * boundsAspectRatio).round();
  }

  // Center the crop area
  cropX = (imageWidth - cropWidth) ~/ 2;
  cropY = (imageHeight - cropHeight) ~/ 2;

  // Ensure crop dimensions don't exceed image bounds
  cropX = cropX.clamp(0, imageWidth - cropWidth);
  cropY = cropY.clamp(0, imageHeight - cropHeight);
  cropWidth = cropWidth.clamp(0, imageWidth - cropX);
  cropHeight = cropHeight.clamp(0, imageHeight - cropY);

  // Create a PictureRecorder and Canvas for cropping
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImageRect(
    decodedImage,
    Rect.fromLTWH(cropX.toDouble(), cropY.toDouble(), cropWidth.toDouble(), cropHeight.toDouble()),
    Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
    Paint(),
  );

  // Convert the cropped image to bytes
  final croppedImage = await recorder.endRecording().toImage(cropWidth, cropHeight);
  final croppedByteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
  return croppedByteData!.buffer.asUint8List();
}

  Future<void> _createCustomMarkerIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(48, 48);

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, borderPaint);

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes != null) {
      setState(() {
        customMarkerIcon =
            BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (searchController.text.isNotEmpty) {
        _getPlaceSuggestions(searchController.text);
      } else {
        setState(() {
          _placesPredictions = [];
        });
      }
    });
  }

  Future<void> _getPlaceSuggestions(String input) async {
    try {
      PlacesAutocompleteResponse result = await places.autocomplete(
        input,
        types: ['address'],
        components: [Component(Component.country, "your_country_code")],
      );
      setState(() {
        _placesPredictions = result.predictions;
      });
    } catch (e) {
      print('Error getting place suggestions: $e');
    }
  }

 Future<void> sendBudgetDataWithImage(Uint8List imageBytes) async {
  showDialog(
    context: context,
    barrierColor: Colors.transparent, 
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Material(
        type: MaterialType.transparency,
        child: SolarLoadingAnimation(),
      );
    },
  );

    final url = Uri.parse("https://solaro1.onrender.com/user/budget");

  // Fetch stored data from prefsManager
  final id = await prefsManager.getString("id");
  final namee = await prefsManager.getString("name");
  double? savedAvgBillPrice = await prefsManager.getDouble("average_bill_price");
  double? savedAvgPowerConsumption = await prefsManager.getDouble("average_power_consumption");
  double? savedPerUnitPrice = await prefsManager.getDouble("per_unit_price");
  double? savedSanctionedLoad = await prefsManager.getDouble("sanctioned_load");
  Map<String, dynamic>? location = await prefsManager.getMap("location");

  if (id == null || namee == null || location == null) {
    print("Error: Missing required user data.");
    return;
  }

  // Convert Uint8List to a File (required for multipart request)
  final tempDir = await getTemporaryDirectory();
  final imageFile = File('${tempDir.path}/captured_image.png');
  await imageFile.writeAsBytes(imageBytes);

  // Create multipart request
  var request = http.MultipartRequest("POST", url);

  // Add JSON fields as form fields
  request.fields["id"] = id;
  request.fields["username"] = namee;
  request.fields["rooftopArea"] = calculatedArea.toString();
  request.fields["billPrice"] = (savedAvgBillPrice ?? 0).toString();
  request.fields["powerConsumption"] = (savedAvgPowerConsumption ?? 0).toString();
  request.fields["unitprice"] = (savedPerUnitPrice ?? 0).toString();
  request.fields["sanctionload"] = (savedSanctionedLoad ?? 0).toString();
  request.fields["coordinates[latitude]"] = location["latitude"].toString();
  request.fields["coordinates[longitude]"] = location["longitude"].toString();

  // Attach image as a file
  request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

  try {
    var response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Data sent successfully!");
      Navigator.of(context).pop();
    } else {
      print("Failed to send data. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error sending data: $e");
    Navigator.of(context).pop();
  }
}

Future<void> _getCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }
    }

    // Use high accuracy for more precise location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20), // Add timeout to prevent hanging
    );
    currentPosition = position;

    await prefsManager.saveMap("location",
        {"latitude": position.latitude, "longitude": position.longitude});

    Map<String, dynamic>? location = await prefsManager.getMap("location");
    if (location != null) {
      double latitude = location["latitude"];
      double longitude = location["longitude"];
      print("Latitude: $latitude, Longitude: $longitude");
    }

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String address =
          '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      searchController.text = address;
    }

    // Make sure to update weather before moving camera
    await _updateWeather(position.latitude, position.longitude);
    await _moveCamera(position.latitude, position.longitude);
  } catch (e) {
    print('Error getting location: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Error getting current location: ${e.toString()}')),
    );
  }
}

Future<void> _moveCamera(double lat, double lng) async {
  if (mapController == null) {
    print('Map controller is null');
    return;
  }
  
  await mapController!.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(lat, lng),
        zoom: 19.0,
        tilt: 0,
      ),
    ),
  );
}

Future<void> _updateWeather(double lat, double lon) async {
  try {
    // Force non-null assertion since you've confirmed it's initialized
    final weatherData = await weatherFactory!.currentWeatherByLocation(lat, lon);
    
    // Debug the weather response
    print('Raw weather data: $weatherData');
    
    // Add a slight delay to ensure API response is complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      currentWeather = weatherData;
      if (weatherData != null) {
        weatherStatus = weatherData.weatherDescription;
        print('Weather updated successfully: $weatherStatus');
      } else {
        print('Weather data is null');
      }
    });
  } catch (e) {
    print('Error fetching weather: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching weather: ${e.toString()}')),
      );
    }
  }
}


  Future<void> _searchLocation(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (_placesPredictions.isNotEmpty) {
        final PlacesDetailsResponse detail = await places.getDetailsByPlaceId(
          _placesPredictions.first.placeId!,
        );

        final lat = detail.result.geometry!.location.lat;
        final lng = detail.result.geometry!.location.lng;

        await _updateWeather(lat, lng);
        await _moveCamera(lat, lng);
      } else {
        List<geocoding.Location> locations =
            await geocoding.locationFromAddress(query);
        if (locations.isNotEmpty) {
          await _updateWeather(
              locations.first.latitude, locations.first.longitude);
          await _moveCamera(
              locations.first.latitude, locations.first.longitude);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
        _placesPredictions = [];
      });
    }
  }

  double _calculatePolygonArea() {
    if (polygonPoints.length < 3) return 0;

    double totalArea = 0;
    final int vertices = polygonPoints.length;

    for (int i = 0; i < vertices; i++) {
      int j = (i + 1) % vertices;

      double lat1 = polygonPoints[i].latitude * pi / 180;
      double lon1 = polygonPoints[i].longitude * pi / 180;
      double lat2 = polygonPoints[j].latitude * pi / 180;
      double lon2 = polygonPoints[j].longitude * pi / 180;

      totalArea += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }

    totalArea = totalArea.abs() * 6378137 * 6378137 / 2;
    return totalArea;
  }

  void _updatePolygon() {
    if (polygonPoints.length >= 4) {
      setState(() {
        polygons.clear();
        polygons.add(
          Polygon(
            polygonId: const PolygonId('rooftop'),
            points: polygonPoints,
            strokeWidth: 2,
            strokeColor: Colors.blue,
            fillColor: Colors.blue.withOpacity(0.3),
          ),
        );
        calculatedArea = _calculatePolygonArea();
      });
    }
  }


  Future<void> _captureAndShareMap() async {
  await _captureMapWithPolygon();

  if (mapImage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map captured successfully. Ready to share.')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to capture map image.')),
    );
  }
}

  void _addMarkerAndPoint(LatLng position) {
    final String markerId = 'point_${markerIdCounter++}';
    final MarkerId id = MarkerId(markerId);

    setState(() {
      markers[id] = Marker(
        markerId: id,
        position: position,
        draggable: true,
        onDragEnd: (LatLng newPosition) => _onMarkerDragEnd(id, newPosition),
        icon: customMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      polygonPoints.add(position);
      _updatePolygon();
    });
  }

  void _onMarkerDragEnd(MarkerId markerId, LatLng newPosition) {
    int index = int.parse(markerId.value.split('_')[1]) - 1;
    if (index < polygonPoints.length) {
      setState(() {
        polygonPoints[index] = newPosition;
        markers[markerId] =
            markers[markerId]!.copyWith(positionParam: newPosition);
        _updatePolygon();
      });
    }
  }

  Widget _buildResultCard() {
    final now = DateTime.now();
    final dateFormat = DateFormat('E, MM/dd/yyyy');
    final formattedDate = dateFormat.format(now);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Solar Ready!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Weather Section with Temperature
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(currentWeather?.temperature?.celsius ?? 0.0).toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weatherStatus ?? 'Sunny',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 30.0, top: 10),
                child: Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        weatherStatus == "Clear"
                            ? Icons.wb_sunny
                            : weatherStatus == "Clouds" ||
                                    weatherStatus == "smoke"
                                ? Icons.cloud
                                : weatherStatus == "Rain"
                                    ? Icons.umbrella
                                    : Icons.wb_sunny,
                        color: weatherStatus == "Clouds" ||
                                weatherStatus == "smoke" ||
                                weatherStatus == "Rain"
                            ? Colors.white
                            : Colors.amberAccent,
                        size: 40,
                      ),
                    )),
              ),
            ),
          ],
        ),

        Row(
          children: [
            // Selected Points Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9FFED), Color(0xFFEBFADE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFCEE5B4), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BC34A).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on,
                              color: Color(0xFF4CAF50), size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Points',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '${polygonPoints.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        // Small solar panel icon
                        const Icon(
                          Icons.grid_on,
                          color: Color(0xFF8BC34A),
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Area Selected Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5FE), Color(0xFFD2E7FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFB6DAFA), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.straighten,
                              color: Color(0xFF2196F3), size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Area Selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          (calculatedArea ?? 0).toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: ui.Color.fromARGB(255, 21, 100, 179),
                          ),
                        ),
                        const Text(
                          'm²',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ui.Color.fromARGB(255, 21, 100, 179),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () async {
              await _captureMapWithPolygon();
              await sendBudgetDataWithImage(mapImage!);
              Get.to(() => MyCardsScreen(mapImage: mapImage));
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8BC34A), Color(0xFF8BC34A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8BC34A).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Proceed",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Wrap GoogleMap with RepaintBoundary for screenshot capture
          RepaintBoundary(
            key: mapKey,
            child: GoogleMap(
              mapType: MapType.satellite,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 19.0,
              ),
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
                _getCurrentLocation();
              },
              polygons: polygons,
              markers: Set<Marker>.of(markers.values),
              onTap: _addMarkerAndPoint,
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 360,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: 354,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 360,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!showResults)
                          ElevatedButton(
                            onPressed: calculatedArea != null
                                ? () {
                                    setState(() => showResults = true);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDFE0FF),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Calculate Solar Potential',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        if (showResults) _buildResultCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Row(
                  children: [
                    // Just the logo in the circle
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(
                          'assets/solar-energy.png',
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),

                    // App name next to the logo
                    const SizedBox(width: 8),
                    Text(
                      'SolarO',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 2,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.15), // Subtle glass effect
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(0.5), // Gradient border feel
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      cursorColor: Colors.blueAccent,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                      onSubmitted: _searchLocation,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Place predictions dropdown
          if (_placesPredictions.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placesPredictions.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_placesPredictions[index].description ?? ''),
                      onTap: () {
                        searchController.text = _placesPredictions[index].description ?? '';
                        _searchLocation(searchController.text);
                        // Continued from the ListTile's onTap method
        _searchLocation(searchController.text);
        setState(() {
          _placesPredictions = [];  // Clear predictions after selection
        });
      },
    );
  }),
),
),

// Control buttons
Positioned(
  bottom: 380,
  right: 16,
  child: Column(
    children: [
      FloatingActionButton(
        heroTag: 'clear',
        backgroundColor: Colors.white,
        mini: true,
        onPressed: () {
          setState(() {
            markers.clear();
            polygonPoints.clear();
            polygons.clear();
            calculatedArea = null;
            showResults = false;
          });
        },
        child: const Icon(Icons.clear, color: Colors.black87),
      ),
      const SizedBox(height: 8),
      FloatingActionButton(
        heroTag: 'calculate',
        backgroundColor: Colors.white,
        mini: true,
        onPressed: polygonPoints.length >= 3 ? _calculatePolygonArea : null,
        child: const Icon(Icons.calculate, color: Colors.black87),
      ),
      const SizedBox(height: 8),
      FloatingActionButton(
        heroTag: 'screenshot',
        backgroundColor: Colors.white,
        mini: true,
        onPressed: _captureAndShareMap,
        child: const Icon(Icons.share, color: Colors.black87),
      ),
      const SizedBox(height: 8),
      FloatingActionButton(
        heroTag: 'location',
        backgroundColor: Colors.white,
        mini: true,
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location, color: Colors.black87),
      ),
    ],
  ),
),

// Loading indicator
if (isLoading)
  Container(
    color: Colors.black.withOpacity(0.5),
    child: const Center(
      child: CircularProgressIndicator(),
    ),
  ),
],
),
);
}
}