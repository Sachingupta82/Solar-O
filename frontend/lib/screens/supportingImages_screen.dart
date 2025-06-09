import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../utils/local_storage.dart';
import 'verifiedVendors_screen.dart';


Future<bool> updateSupportingImages(String id, File southFacingImage, File overheadAngleImage) async {
  final url = Uri.parse("https://solaro1.onrender.com/user/$id/upload");
  var request = http.MultipartRequest("PUT", url);
  
  // Change the field name to "images" to match your backend
  request.files.add(await http.MultipartFile.fromPath("images", southFacingImage.path));
  request.files.add(await http.MultipartFile.fromPath("images", overheadAngleImage.path));

  try {
    var response = await request.send();
    final responseString = await response.stream.bytesToString();
    print("Response: $responseString");
    
    if (response.statusCode == 200) {
      print("Images uploaded successfully!");
      return true;
    } else {
      print("Failed to upload images. Status Code: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Error uploading images: $e");
    throw e; // Re-throw to handle in calling function
  }
}


class Assesment_Images extends StatefulWidget {
  const Assesment_Images({Key? key}) : super(key: key);

  @override
  _Assesment_ImagesState createState() => _Assesment_ImagesState();
}

class _Assesment_ImagesState extends State<Assesment_Images> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _southFacingImage;
  File? _overheadAngleImage;
  bool _isUploading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? userid;
  Future<void> getUserData()async{
  final SharedPreferencesManager prefsManager = SharedPreferencesManager();
      final String? userId = await prefsManager.getString("id");
      userid = userId;
}

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _animationController.forward();
    getUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openCameraWithGrid(int imageType) async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreenWithGrid(camera: firstCamera, imageType: imageType),
      ),
    );
    
    if (result != null) {
      setState(() {
        if (imageType == 1) {
          _southFacingImage = File(result);
        } else {
          _overheadAngleImage = File(result);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source, int imageType) async {
    setState(() {
      _isUploading = true;
    });

    try {
      if (source == ImageSource.camera) {
        await _openCameraWithGrid(imageType);
      } else {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            if (imageType == 1) {
              _southFacingImage = File(pickedFile.path);
            } else {
              _overheadAngleImage = File(pickedFile.path);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImageSourceDialog(int imageType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green[800]),
              const SizedBox(width: 10),
              const Text('Select Image Source'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.green[600]),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('With alignment grid'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, imageType);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green[600]),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, imageType);
                  },
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
        );
      },
    );
  }

  Future<void> _submitAssessment() async {
  if (_southFacingImage == null || _overheadAngleImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Please upload both required photos'),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    // Wait for the API call to complete
    bool success = await updateSupportingImages(userid!, _southFacingImage!, _overheadAngleImage!);
    
    // Close loading dialog
    Navigator.pop(context);
    
    if (success) {
      // Only if successful, animate and show success message
      _animationController.reset();
      _animationController.forward();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Assessment submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SolarVendorModule(),
        ),
      );
    } else {
      // Show error message if the API call was not successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text('Failed to submit assessment. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  } catch (e) {
    // Close loading dialog and show error if exception occurs
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 10),
            Text('Error: ${e.toString()}'),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rooftop Solar Assessment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                      strokeWidth: 6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Processing image...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with sun animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[700]!, Colors.green[900]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Rooftop Solar Assessment',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TweenAnimationBuilder(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: const Duration(seconds: 2),
                                      builder: (context, double value, child) {
                                        return Transform.rotate(
                                          angle: value * 6.28,
                                          child: Icon(
                                            Icons.wb_sunny,
                                            color: Colors.yellow[300],
                                            size: 30,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Please provide the following two photos of your roof to assess solar installation potential:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: const [
                                    Icon(Icons.tips_and_updates, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Our grid guide will help you frame the perfect shot!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // South-facing angle photo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green[100]!, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        TweenAnimationBuilder(
                                          tween: Tween<double>(begin: 0.7, end: 1),
                                          duration: const Duration(seconds: 2),
                                          curve: Curves.easeInOut,
                                          builder: (context, double value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Icon(Icons.wb_sunny, color: Colors.green[700], size: 28),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'South-Facing View',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Text(
                                        'Take a photo from ground level showing the south-facing side of your roof. This helps determine sun exposure throughout the day.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () => _showImageSourceDialog(1),
                                      child: Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green[300]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: _southFacingImage != null
                                            ? Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.file(
                                                      _southFacingImage!,
                                                      width: double.infinity,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: CircleAvatar(
                                                      backgroundColor: Colors.white.withOpacity(0.7),
                                                      radius: 18,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.edit, size: 18),
                                                        color: Colors.green[700],
                                                        onPressed: () => _showImageSourceDialog(1),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Center(
                                                child: Column(
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_a_photo,
                                                      size: 48,
                                                      color: Colors.green[800],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Tap to upload South-Facing View',
                                                      style: TextStyle(
                                                        color: Colors.green[800],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Our grid will help you align perfectly',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Overhead angle photo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green[100]!, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        TweenAnimationBuilder(
                                          tween: Tween<double>(begin: 0, end: 1),
                                          duration: const Duration(seconds: 1),
                                          curve: Curves.elasticOut,
                                          builder: (context, double value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Icon(Icons.view_in_ar, color: Colors.green[700], size: 28),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Maximum Viewable Angle',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Text(
                                        'Take a photo from the highest vantage point possible (such as across the street or from a higher building) to show as much of the roof as possible for accurate estimation.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green[900],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () => _showImageSourceDialog(2),
                                      child: Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green[300]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: _overheadAngleImage != null
                                            ? Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.file(
                                                      _overheadAngleImage!,
                                                      width: double.infinity,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: CircleAvatar(
                                                      backgroundColor: Colors.white.withOpacity(0.7),
                                                      radius: 18,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.edit, size: 18),
                                                        color: Colors.green[700],
                                                        onPressed: () => _showImageSourceDialog(2),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_a_photo,
                                                      size: 48,
                                                      color: Colors.green[800],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Tap to upload Overhead View',
                                                      style: TextStyle(
                                                        color: Colors.green[800],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Use grid alignment for best results',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit button with animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: ElevatedButton(
                              onPressed: _submitAssessment,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green[800],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.solar_power,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Submit Assessment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// Custom Camera Screen with Grid Overlay
class CameraScreenWithGrid extends StatefulWidget {
  final CameraDescription camera;
  final int imageType;

  const CameraScreenWithGrid({
    Key? key,
    required this.camera,
    required this.imageType,
  }) : super(key: key);

  @override
  _CameraScreenWithGridState createState() => _CameraScreenWithGridState();
}

class _CameraScreenWithGridState extends State<CameraScreenWithGrid> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _showTip = true;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Hide tip after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showTip = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      Navigator.pop(context, image.path);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreview(_controller),
                
                // Grid Overlay
                CustomPaint(
                  painter: GridPainter(),
                  size: Size(screenSize.width, screenSize.height),
                ),
                
                // Tip card that disappears
                if (_showTip)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Card(
                      color: Colors.black.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.yellow[700]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.yellow[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pro Tip',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            widget.imageType == 1
                                ? const Text(
                                    'Align the horizon with the horizontal grid lines. Position your roof within the orange target area.',
                                    style: TextStyle(color: Colors.white),
                                  )
                                : const Text(
                                    'Capture as much of your roof as possible. Try finding an elevated position for a better view.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // App Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    elevation: 0,
                    title: Text(
                      widget.imageType == 1 ? 'South-Facing Roof' : 'Maximum View Angle',
                      style: const TextStyle(fontSize: 18),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.flash_on),
                        onPressed: () async {
                          final FlashMode currentMode = _controller.value.flashMode;
                          FlashMode newMode;
                          if (currentMode == FlashMode.off) {
                            newMode = FlashMode.off;
                          } else if (currentMode == FlashMode.auto) {
                            newMode = FlashMode.off;
                          } else {
                            newMode = FlashMode.off;
                          }
                          await _controller.setFlashMode(newMode);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                
                // Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    color: Colors.black.withOpacity(0.7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Back Button
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                          iconSize: 30,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        
                        // Capture Button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Help Button
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          color: Colors.white,
                          iconSize: 30,
                          onPressed: () {
                            setState(() {
                              _showTip = !_showTip;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// Grid Painter for Camera Overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      double dy = size.height * i / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      double dx = size.width * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }

    // Draw a "horizon" guide line
    final Paint horizonPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      horizonPaint,
    );

    // Draw compass indicators
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: 'N',
      style: TextStyle(
        color: Colors.orange,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 20));

    textPainter.text = TextSpan(
      text: 'S',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 40),
    );

    textPainter.text = TextSpan(
      text: 'E',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, size.height / 2 - textPainter.height / 2));

    textPainter.text = TextSpan(
      text: 'W',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - 40, size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}