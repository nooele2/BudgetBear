import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/firebase_options.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:budget_bear/services/theme_provider.dart'; 

Future<void> main() async {
  const sendgridKey = String.fromEnvironment('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', defaultValue: '');
const senderEmail = String.fromEnvironment('budgetbear77@gmail.com', defaultValue: '');
const senderName = String.fromEnvironment('Budget Bear', defaultValue: '');
const openrouterKey = String.fromEnvironment('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', defaultValue: '');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider( 
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Bear',

      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF47A8A5),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF47A8A5),
          foregroundColor: Colors.white,
        ),
      ),

      home: const AuthPage(),
    );
  }
}
