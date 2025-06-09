// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:frontend/utils/local_storage.dart';
// import 'package:google_generative_ai/google_generative_ai.dart' as imageai;
// import 'package:image_picker/image_picker.dart';
// import 'package:lottie/lottie.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:frontend/home_screen.dart';


// class SolarElectricityBillAnalyzerScreen extends StatefulWidget {
//   const SolarElectricityBillAnalyzerScreen({super.key});

//   @override
//   _SolarElectricityBillAnalyzerScreenState createState() =>
//       _SolarElectricityBillAnalyzerScreenState();
// }

// class _SolarElectricityBillAnalyzerScreenState
//     extends State<SolarElectricityBillAnalyzerScreen>
//     with SingleTickerProviderStateMixin {
//   File? _imageFile;
//   late imageai.GenerativeModel model;
//   Map<String, dynamic>? _billData;
//   bool _isAnalyzing = false;
//   bool _isAnalyzed = false;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   late AnimationController _animationController;
//   final SharedPreferencesManager prefsManager = SharedPreferencesManager();

//   @override
//   void initState() {
//     super.initState();
//     model = imageai.GenerativeModel(
//       model: 'gemini-2.0-flash',
//       apiKey:dotenv.env['Gemini_API']!
//     );

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _audioPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//         _billData = null;
//         _isAnalyzed = false;
//       });
//     }
//   }

//   Future<void> _analyzeElectricityBill() async {
//     if (_imageFile == null) return;

//     setState(() {
//       _isAnalyzing = true;
//       _billData = null;
//     });

//     try {
//       _audioPlayer.play(AssetSource('waiting.mp3'));

//       final imageBytes = await _imageFile!.readAsBytes();

//       const prompt = '''
//       Analyze this electricity bill and extract the following detailed information:
//       1. Current Bill Period (from which date to which date)
//       2. Units Consumed (Current Bill)
//       3. Total Bill Amount
//       4. Past 6 Months Average Consumption units
//       5. Past 12 Months Average Consumption units
//       6. Per Unit Price (should be calculated by dividing current Bill Amount by current Units Consumed)
//       7. Sanctioned Load

//       Return the response strictly in the following JSON format:
//       {
//         "current_bill_period": "string",
//         "current_units_consumed": number,
//         "total_bill_amount": number,
//         "past_6_months_avg": number,
//         "past_12_months_avg": number,
//         "per_unit_price": number,
//         "sanctioned_load": "string"
//       }
//       ''';

//       final response = await model.generateContent([
//         imageai.Content.multi([
//           imageai.TextPart(prompt),
//           imageai.DataPart('image/jpeg', imageBytes),
//         ])

//       ]);

//       _audioPlayer.stop();

//       if (response.text != null && response.text!.isNotEmpty) {
//         _parseAndShowResponse(response.text!);
//       } else {
//         _showErrorDialog('No valid response received');
//       }
//     } catch (e) {
//       print('Bill Analysis Error: $e');
//       _showErrorDialog('Failed to analyze bill: $e');
//     } finally {
//       setState(() {
//         _isAnalyzing = false;
//       });
//     }
//   }

//   void _parseAndShowResponse(String responseText) async {
//     try {
//       String cleanedText =
//           responseText.replaceAll('```json', '').replaceAll('```', '').trim();

//       final Map<String, dynamic> billData = json.decode(cleanedText);
//       setState(() {
//         _billData = billData;
//         _isAnalyzed = true;
//       });
//       double averagePowerConsumption = (billData['past_12_months_avg'] is num)
//           ? billData['past_12_months_avg'].toDouble()
//           : double.tryParse(billData['past_12_months_avg']?.toString() ?? "") ??
//               0.0;

//       double perUnitPrice = (billData['per_unit_price'] is num)
//           ? billData['per_unit_price'].toDouble()
//           : double.tryParse(billData['per_unit_price']?.toString() ?? "") ??
//               0.0;

//       double averageBillPrice = averagePowerConsumption * perUnitPrice;

//       double sanctionedLoad = (billData['sanctioned_load'] is num)
//           ? billData['sanctioned_load'].toDouble()
//           : double.tryParse(billData['sanctioned_load']?.toString() ?? "") ??
//               0.0;

//       // print('$averageBillPrice this is average price');

//       await prefsManager.saveDouble("average_bill_price", averageBillPrice);
//       await prefsManager.saveDouble(
//           "average_power_consumption", averagePowerConsumption);
//       await prefsManager.saveDouble("per_unit_price", perUnitPrice);
//       await prefsManager.saveDouble("sanctioned_load", sanctionedLoad);

// // Retrieve immediately to verify
//       double? savedAvgBillPrice =
//           await prefsManager.getDouble("average_bill_price");
//       double? savedAvgPowerConsumption =
//           await prefsManager.getDouble("average_power_consumption");
//       double? savedPerUnitPrice =
//           await prefsManager.getDouble("per_unit_price");
//       double? savedSanctionedLoad =
//           await prefsManager.getDouble("sanctioned_load");

//       print("====== Retrieved Values After Saving ======");
//       print("Average Bill Price: ${savedAvgBillPrice ?? 'Not Found'}");
//       print(
//           "Average Power Consumption: ${savedAvgPowerConsumption ?? 'Not Found'}");
//       print("Per Unit Price: ${savedPerUnitPrice ?? 'Not Found'}");
//       print("Sanctioned Load: ${savedSanctionedLoad ?? 'Not Found'}");
//       print("===========================================");
//     } catch (e) {
//       _showErrorDialog('Failed to parse bill data: $e');
//     }
//   }

//   void _navigateToHomePage() {

//        Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => const RooftopCalculator()));
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         title: const Text(
//           'Bill Analyzer',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.green[800],
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: LayoutBuilder(builder: (context, constraints) {
//           return Stack(
//             children: [
//               SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Image Selection Section with Professional Design
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             _buildProfessionalButton(
//                               icon: Icons.camera_alt_rounded,
//                               label: 'Capture',
//                               onPressed: () => _pickImage(ImageSource.camera),
//                             ),
//                             _buildProfessionalButton(
//                               icon: Icons.photo_library_rounded,
//                               label: 'Gallery',
//                               onPressed: () => _pickImage(ImageSource.gallery),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 20),

//                         // Animated Image Preview with Enhanced Design
//                         if (_imageFile != null)
//                           Center(
//                             child: Container(
//                               width: MediaQuery.of(context).size.width * 0.8,
//                               height: MediaQuery.of(context).size.height * 0.3,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(15),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.green.withOpacity(0.3),
//                                     spreadRadius: 3,
//                                     blurRadius: 10,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(15),
//                                 child: Image.file(
//                                   _imageFile!,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                             ),
//                           ),

//                         const SizedBox(height: 20),

//                         // Professional Analyze Button
//                         ElevatedButton(
//                           onPressed: _imageFile != null && !_isAnalyzing
//                               ? _analyzeElectricityBill
//                               : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green[800],
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 5,
//                           ),
//                           child: Text(
//                             _isAnalyzed ? 'Re-Analyze Bill' : 'Analyze Bill',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 1.2,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 20),

//                         // Bill Analysis Results with Professional Design
//                         if (_billData != null)
//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.green[50],
//                               borderRadius: BorderRadius.circular(15),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.green.withOpacity(0.2),
//                                   spreadRadius: 2,
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(20.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   _buildDetailRow(
//                                       'Current Bill Period',
//                                       _billData!['current_bill_period'] ??
//                                           'N/A'),
//                                   _buildDetailRow('Units Consumed',
//                                       '${_billData!['current_units_consumed'] ?? 'N/A'} kWh'),
//                                   _buildDetailRow('Total Bill Amount',
//                                       '₹${_billData!['total_bill_amount']?.toStringAsFixed(2) ?? 'N/A'}'),
//                                   _buildDetailRow('Past 6 Months Avg',
//                                       '${_billData!['past_6_months_avg']?.toStringAsFixed(2) ?? 'N/A'} kWh'),
//                                   _buildDetailRow('Past 12 Months Avg',
//                                       '${_billData!['past_12_months_avg']?.toStringAsFixed(2) ?? 'N/A'} kWh'),
//                                   _buildDetailRow('Per Unit Price',
//                                       '₹${_billData!['per_unit_price']?.toStringAsFixed(2) ?? 'N/A'}/kWh'),
//                                   _buildDetailRow('Sanctioned Load',
//                                       _billData!['sanctioned_load'] ?? 'N/A'),
//                                 ],
//                               ),
//                             ),
//                           ),

//                         // Enter HomePage Button below results
//                         if (_billData != null)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20.0),
//                             child: ElevatedButton(
//                               onPressed: _navigateToHomePage,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green[600],
//                                 foregroundColor: Colors.white,
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 15),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 5,
//                               ),
//                               child: const Text(
//                                 'Home',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 1.2,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               // Full Screen Loading Overlay
//               if (_isAnalyzing)
//                 Container(
//                   color: Colors.black.withOpacity(0.1),
//                   child: Center(
//                     child: Center(
//                       child: Lottie.asset(
//                         'assets/solar_loading.json',
//                         width: 220,
//                         height: 220,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   // Updated button design
//   Widget _buildProfessionalButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: Colors.white),
//       label: Text(
//         label,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.1,
//         ),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green[800],
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         elevation: 5,
//       ),
//     );
//   }

//   // Simplified detail row without animation
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.green[900],
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.black87,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }












import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/utils/local_storage.dart'; // Assuming this path is correct
import 'package:google_generative_ai/google_generative_ai.dart' as imageai;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:frontend/screens/home_screen.dart'; // Assuming this path is correct
import 'package:file_picker/file_picker.dart'; // Add file_picker to pubspec.yaml

class SolarElectricityBillAnalyzerScreen extends StatefulWidget {
  const SolarElectricityBillAnalyzerScreen({super.key});

  @override
  _SolarElectricityBillAnalyzerScreenState createState() =>
      _SolarElectricityBillAnalyzerScreenState();
}

class _SolarElectricityBillAnalyzerScreenState
    extends State<SolarElectricityBillAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  late imageai.GenerativeModel model;
  Map<String, dynamic>? _billData;
  bool _isAnalyzing = false;
  bool _isAnalyzed = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  final SharedPreferencesManager prefsManager = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();
    model = imageai.GenerativeModel(
        // Make sure 'gemini-pro-vision' supports PDF input or use a multimodal model
        model: 'gemini-2.0-flash', // Or a suitable multimodal model
        apiKey: dotenv.env['Gemini_API']!);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      await _processFile(File(pickedFile.path));
    }
  }

  Future<void> _pickPdf() async {
    Navigator.pop(context); // Close bottom sheet
    try {
       final result = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['pdf'],
       );
       if (result != null && result.files.single.path != null) {
         await _processFile(File(result.files.single.path!));
       }
    } catch (e) {
       _showErrorDialog("Failed to pick PDF: $e. Please ensure you have the necessary permissions and the file_picker package is correctly configured.");
    }
  }


  Future<void> _processFile(File file) async {
    setState(() {
      _selectedFile = file;
      _billData = null;
      _isAnalyzed = false;
    });
  }

  Future<void> _analyzeElectricityBill() async {
    if (_selectedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _billData = null;
    });

    try {
      _audioPlayer.play(AssetSource('waiting.mp3'));

      final fileBytes = await _selectedFile!.readAsBytes();
      final isPdf = _selectedFile!.path.toLowerCase().endsWith('.pdf');
      final mimeType = isPdf ? 'application/pdf' : 'image/jpeg'; // Adjust image mime type if needed (png?)

      const prompt = '''
      Analyze this electricity bill document (image or PDF) and extract the following detailed information:
      1. Current Bill Period (from which date to which date)
      2. Units Consumed (Current Bill)
      3. Total Bill Amount
      4. Past 6 Months Average Consumption units
      5. Past 12 Months Average Consumption units
      6. Per Unit Price (should be calculated by dividing current Bill Amount by current Units Consumed)
      7. Sanctioned Load

      Return the response strictly in the following JSON format:
      {
        "current_bill_period": "string",
        "current_units_consumed": number,
        "total_bill_amount": number,
        "past_6_months_avg": number,
        "past_12_months_avg": number,
        "per_unit_price": number,
        "sanctioned_load": "string"
      }
      If any value is not found, represent it as null or "N/A" in the JSON. Ensure numbers are actual numeric types.
      ''';

      final response = await model.generateContent([
        imageai.Content.multi([
          imageai.TextPart(prompt),
          imageai.DataPart(mimeType, fileBytes),
        ])
      ]);

      _audioPlayer.stop();

      if (response.text != null && response.text!.isNotEmpty) {
        _parseAndShowResponse(response.text!);
      } else {
        _showErrorDialog('No valid response received from the analysis model.');
      }
    } catch (e) {
      print('Bill Analysis Error: $e');
       _audioPlayer.stop();
      _showErrorDialog('Failed to analyze bill: $e. Check API key, model name, and network connection.');
    } finally {
      if (mounted) {
         setState(() {
           _isAnalyzing = false;
         });
      }
    }
  }

 void _parseAndShowResponse(String responseText) async {
    try {
      String cleanedText =
          responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic> billData = json.decode(cleanedText);

      double? parseDouble(dynamic value) {
          if (value is num) {
              return value.toDouble();
          } else if (value is String) {
              return double.tryParse(value);
          }
          return null;
      }

      String? parseString(dynamic value) {
          if (value is String && value.isNotEmpty && value.toLowerCase() != 'n/a') {
              return value;
          }
          return null; // Represent missing strings as null
      }

      double? past12MonthsAvg = parseDouble(billData['past_12_months_avg']);
      double? perUnitPrice = parseDouble(billData['per_unit_price']);
      double? sanctionedLoadValue = parseDouble(billData['sanctioned_load']); // Attempt to parse load as double

      double averagePowerConsumption = past12MonthsAvg ?? 0.0;
      double unitPrice = perUnitPrice ?? 0.0;
      double averageBillPrice = averagePowerConsumption * unitPrice;
      double sanctionedLoad = sanctionedLoadValue ?? 0.0; // Default to 0 if parsing fails or is null

      // Update state with potentially parsed/defaulted values
       setState(() {
         // Keep original data for display, but use parsed values for saving
         _billData = billData;
         _isAnalyzed = true;
       });


      await prefsManager.saveDouble("average_bill_price", averageBillPrice);
      await prefsManager.saveDouble(
          "average_power_consumption", averagePowerConsumption);
      await prefsManager.saveDouble("per_unit_price", unitPrice);
      await prefsManager.saveDouble("sanctioned_load", sanctionedLoad); // Save the parsed double

      double? savedAvgBillPrice =
          await prefsManager.getDouble("average_bill_price");
      double? savedAvgPowerConsumption =
          await prefsManager.getDouble("average_power_consumption");
      double? savedPerUnitPrice =
          await prefsManager.getDouble("per_unit_price");
      double? savedSanctionedLoad =
          await prefsManager.getDouble("sanctioned_load");

      print("====== Retrieved Values After Saving ======");
      print("Average Bill Price: ${savedAvgBillPrice ?? 'Not Found'}");
      print(
          "Average Power Consumption: ${savedAvgPowerConsumption ?? 'Not Found'}");
      print("Per Unit Price: ${savedPerUnitPrice ?? 'Not Found'}");
      print("Sanctioned Load: ${savedSanctionedLoad ?? 'Not Found'}");
      print("===========================================");

    } catch (e) {
       print("Parsing Error: $e");
       print("Raw Response Text: $responseText");
      _showErrorDialog('Failed to parse bill data: $e. The response format might be incorrect.');
       setState(() {
         _billData = null; // Clear potentially bad data
         _isAnalyzed = false;
       });
    }
  }


  void _navigateToHomePage() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const RooftopCalculator())); // Ensure RooftopCalculator exists
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUploadOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildBottomSheetOption(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Upload PDF',
                onTap: _pickPdf,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildBottomSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildBottomSheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Capture with Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.green[800], // Green outline color
        size: 28,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Bill Analyzer',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[800],
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showUploadOptionsBottomSheet,
                          icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
                          label: const Text(
                            'Upload Bill',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_selectedFile != null)
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.green[200]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: _selectedFile!.path.toLowerCase().endsWith('.pdf')
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 80, color: Colors.red[600]),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(
                                          _selectedFile!.path.split('/').last,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ),
                                    ],
                                  )
                                : Image.file(
                                    _selectedFile!,
                                    fit: BoxFit.contain, // Use contain to see the whole bill
                                    errorBuilder: (context, error, stackTrace) => const Center(child: Text("Preview not available")),
                                  ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _selectedFile != null && !_isAnalyzing
                              ? _analyzeElectricityBill
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                          child: Text(
                            _isAnalyzed ? 'Re-Analyze Bill' : 'Analyze Bill',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_billData != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                      'Current Bill Period',
                                      _billData!['current_bill_period']?.toString() ?? 'N/A'),
                                  _buildDetailRow('Units Consumed',
                                      '${_billData!['current_units_consumed']?.toString() ?? 'N/A'} kWh'),
                                  _buildDetailRow('Total Bill Amount',
                                      '₹${_billData!['total_bill_amount']?.toStringAsFixed(2) ?? 'N/A'}'),
                                  _buildDetailRow('Past 6 Months Avg',
                                      '${_billData!['past_6_months_avg']?.toStringAsFixed(2) ?? 'N/A'} kWh'),
                                  _buildDetailRow('Past 12 Months Avg',
                                      '${_billData!['past_12_months_avg']?.toStringAsFixed(2) ?? 'N/A'} kWh'),
                                  _buildDetailRow('Per Unit Price',
                                      '₹${_billData!['per_unit_price']?.toStringAsFixed(2) ?? 'N/A'}/kWh'),
                                  _buildDetailRow('Sanctioned Load',
                                      _billData!['sanctioned_load']?.toString() ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),

                        if (_billData != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0), // Added bottom padding
                            child: ElevatedButton(
                              onPressed: _navigateToHomePage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isAnalyzing)
                Container(
                  color: Colors.black.withOpacity(0.5), // Darker overlay
                  child: Center(
                    child: Column( // Added Column for text
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/solar_loading.json', // Make sure this asset exists
                          width: 200, // Slightly smaller
                          height: 200,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Analyzing your bill...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Align top for long values
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.green[900],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10), // Add spacing
          Expanded( // Allow value text to wrap
            child: Text(
              value,
              textAlign: TextAlign.right, // Align value to the right
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
