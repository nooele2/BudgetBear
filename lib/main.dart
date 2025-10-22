import 'package:budget_bear/auth/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:budget_bear/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Flutter Demo',
      home: AuthPage(),
    );
  }
}