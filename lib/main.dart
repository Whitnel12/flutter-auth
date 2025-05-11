import 'package:flutter/material.dart';
import 'package:learning_auth/screens/home_screen.dart';
import 'package:learning_auth/screens/login_screen.dart';
import 'package:learning_auth/screens/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:learning_auth/screens/splash_screen.dart';
import 'package:learning_auth/screens/welcome_screen.dart';
import 'package:learning_auth/widgets/botttom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const String appName = "THIS IS AUTH LOGIN";
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      initialRoute: "/",
      routes: {
        '/': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/bottom_nav': (context) => BottomNav(),
      },
    );
  }
}
