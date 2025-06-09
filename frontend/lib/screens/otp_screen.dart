import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/billAnalyze_screen.dart';
import 'package:frontend/utils/local_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otpless_flutter/otpless_flutter.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final Otpless otplessPlugin;

  const OtpScreen({
    super.key, 
    required this.phoneNumber, 
    required this.otplessPlugin
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool isLoading = false;
  bool canResend = false;
  int _secondsRemaining = 30;
  late Timer _timer;
  final SharedPreferencesManager prefsManager = SharedPreferencesManager();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool otpVerified = false;

  @override
  void initState() {
    super.initState();
    
    widget.otplessPlugin.setHeadlessCallback(onHeadlessResult);
    
    sendOtp();
    startResendTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    nameController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void onHeadlessResult(dynamic result) async {
    // print("OTPless Result: $result"); 

    if (!mounted) return; 

    setState(() {
      isLoading = false;
    });

    if (result['statusCode'] == 200 || result['statusCode'] == 400) {
      switch (result['responseType'] as String) {
        case 'ONETAP':
        case 'OTP':
        case 'VERIFY':
          {
            // final token = result["response"]["token"] ?? "No token found";
            await prefsManager.saveString("id", widget.phoneNumber.toString());
            final id = await prefsManager.getString("id");
            // print("Verification Token: $id"); 

            setState(() {
              otpVerified = true;
              isLoading = false;
            });

            // Show name dialog after successful verification
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showNameDialog();
              }
            });
            break;
          }
        case 'INITIATE':
          {
            // OTP sent successfully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("OTP sent successfully"),
                backgroundColor: Colors.green,
              ),
            );
            break;
          }
      }
    } else {
      // OTP verification failed
      setState(() {
        otpVerified = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "OTP Verification Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 50,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please enter your name to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    hintStyle: GoogleFonts.ubuntu(color: Colors.black38),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      String name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter your name"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        await prefsManager.saveString("name", name);
                        final namee = await prefsManager.getString("name");
                        print(namee);
                        
                        
                          Navigator.of(context).pop(); 
                         //pasing to homescreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SolarElectricityBillAnalyzerScreen()),
                          );
                        }
                      
                    },
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void startResendTimer() {
    setState(() {
      canResend = false;
      _secondsRemaining = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          canResend = true;
          _timer.cancel();
        }
      });
    });
  }

  void resendCode() {
    if (canResend) {
      sendOtp();
      startResendTimer();
    }
  }

  void sendOtp() {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> arg = {};
    arg["phone"] = widget.phoneNumber;
    arg["countryCode"] = "91";
    widget.otplessPlugin.startHeadless(onHeadlessResult, arg);
  }

  void verifyOtp() {
    setState(() {
      isLoading = true;
    });

    String otpCode = otpController.text.trim();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    Map<String, dynamic> arg = {};
    arg["phone"] = widget.phoneNumber;
    arg["countryCode"] = "91";
    arg["otp"] = otpCode;
    widget.otplessPlugin.startHeadless(onHeadlessResult, arg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
          child: Container(
            child: Column(
              children: [
                Text(
                  'Verify Phone',
                  style: GoogleFonts.ubuntu(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Code has been sent to ${widget.phoneNumber} ',
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 30),
                Pinput(
                  length: 6,
                  controller: otpController,
                  onCompleted: (pin) {
                    verifyOtp(); 
                  },
                  defaultPinTheme: PinTheme(
                    width: 60,
                    height: 60,
                    textStyle: GoogleFonts.ubuntu(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Didn't get OTP Code ?",
                  style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.black54),
                ),
                TextButton(
                  onPressed: resendCode,
                  child: Text(
                    canResend ? 'Resend Code' : 'Resend Code (${_secondsRemaining}s)',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: verifyOtp,
                          child: Text(
                            'Verify',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}