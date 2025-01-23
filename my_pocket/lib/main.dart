import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/budgeting_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'model/expense_model.dart';
import 'theme_provider.dart';
import 'firebase_options.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // Theme Management
        ChangeNotifierProvider(create: (context) => ExpenseIncomeModel()),  // Expense Tracking Model
      ],
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
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, // Light or Dark Theme
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: '/', // SplashScreen as the first route
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/addExpense': (context) => const AddExpenseScreen(), // Add Expense Screen
        '/history': (context) => const TransactionHistoryScreen(), // Transaction History
      
        '/budgeting': (context) => const BudgetingScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
