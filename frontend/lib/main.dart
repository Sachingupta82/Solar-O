import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/screens/billAnalyze_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:get/get.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const SAM());
}

class SAM extends StatefulWidget {
  const SAM({super.key});

  @override
  State<SAM> createState() => _SAMState();
}

class _SAMState extends State<SAM> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SolarO',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home:const LoginScreen(),
      // home:SolarElectricityBillAnalyzerScreen(),
    );
  }
}

