// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart'; // New screen for adding income
import 'budgeting_screen.dart'; // New screen for budgeting
// New screen for categories
import 'reports_screen.dart'; // New screen for reports
import 'transaction_history_screen.dart'; // New screen for transaction history
import 'settings_screen.dart'; // New screen for settings
// New screen for savings
import '../model/expense_model.dart';
import '../theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final expenseModel = Provider.of<ExpenseIncomeModel>(context);

    Color primaryTextColor =
        themeProvider.isDarkMode ? Colors.white : Colors.black;
    Color primaryBackgroundColor =
        themeProvider.isDarkMode ? Colors.black : Colors.white;

    return WillPopScope(
      onWillPop: _onWillPop, // Handle the back button press
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color.fromARGB(255, 66, 187, 235),
                  Color.fromARGB(255, 150, 219, 244)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'Home',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
          ),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                color: themeProvider.isDarkMode ? Colors.black : Colors.white,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: Container(
            color: primaryBackgroundColor,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color.fromARGB(255, 7, 161, 226),
                        Color.fromARGB(255, 190, 224, 231)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        return Text('Error loading username');
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        return Text('No user data available');
                      }

                      String username = snapshot.data!['username'] ?? 'User';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $username!',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Welcome to My Pocket!',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white70
                                  : Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _buildDrawerItem(context, 'Add Expense', Icons.add,
                    primaryTextColor, AddExpenseScreen()),
                _buildDrawerItem(context, 'Add Income', Icons.add_circle,
                    primaryTextColor, AddIncomeScreen()),
                _buildDrawerItem(
                    context,
                    'Budgeting',
                    Icons.account_balance_wallet,
                    primaryTextColor,
                    BudgetingScreen()),
                _buildDrawerItem(context, 'Reports', Icons.bar_chart,
                    primaryTextColor, ReportsScreen()),
                _buildDrawerItem(context, 'Settings', Icons.settings,
                    primaryTextColor, SettingsScreen()),
                _buildDrawerItem(context, 'Transaction History', Icons.history,
                    primaryTextColor, TransactionHistoryScreen()),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickActionCard(
                        context,
                        'Add Expense',
                        Icons.add,
                        const Color.fromARGB(255, 76, 140, 163),
                        AddExpenseScreen(),
                        primaryTextColor),
                    _buildQuickActionCard(
                        context,
                        'Add Income',
                        Icons.add_circle,
                        const Color.fromARGB(255, 108, 218, 237),
                        AddIncomeScreen(),
                        primaryTextColor),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  'Expense Summary',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? const Color.fromARGB(255, 143, 211, 238)
                        : const Color.fromARGB(255, 111, 225, 238),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildSummaryCard(
                    'Total Expenses',
                    expenseModel.totalExpenses.toStringAsFixed(2),
                    Icons.monetization_on,
                    const Color.fromARGB(255, 125, 200, 227),
                    primaryTextColor),
                SizedBox(height: 10),
                _buildSummaryCard(
                    'Total Income',
                    expenseModel.totalIncome.toStringAsFixed(2),
                    Icons.attach_money,
                    const Color.fromARGB(255, 163, 233, 245),
                    primaryTextColor),
                SizedBox(height: 10),
                _buildSummaryCard(
                    'Remaining Balance',
                    expenseModel.remainingBalance.toStringAsFixed(2),
                    Icons.savings,
                    const Color.fromARGB(255, 107, 197, 232),
                    primaryTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon,
      Color textColor, Widget targetScreen) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title,
      IconData icon, Color color, Widget targetScreen, Color textColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: Card(
        color: color,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: textColor),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, Color textColor) {
    return Card(
      color: color,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 40, color: textColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        )) ??
        false;
  }
}
