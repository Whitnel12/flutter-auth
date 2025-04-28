import 'package:flutter/material.dart';
import 'package:learning_auth/screens/sigin.dart';
import 'package:learning_auth/screens/signup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appName = "THIS IS AUTH LOGIN";
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      initialRoute: "/",
      routes: {
        '/': (context) => SignIn(),
        '/signup': (context) => SignUp(),
      },
    );
  }
}
