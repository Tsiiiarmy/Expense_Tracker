import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Transaction Model (Handles both Expenses and Income)
class TransactionModel {
  late final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String type; // 'expense' or 'income'

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
  });

  // Convert Firestore document to TransactionModel object
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      category: data['category'] ?? 'Uncategorized',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'expense',
    );
  }

  // Convert TransactionModel object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type,
    };
  }
}

class ExpenseIncomeModel extends ChangeNotifier {
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;
  double _remainingBalance = 0.0;
  double _budget = 0.0; // Default budget
  String _selectedCurrency = 'BDT'; // Default currency
  double _incomeBudget = 0.0;
  double _expenseBudget = 0.0;
  double _savingBudget = 0.0;

  final Map<String, double> _categoryBudgets = {};
  List<TransactionModel> _transactions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters for totals
  double get totalExpenses => _totalExpenses;
  double get totalIncome => _totalIncome;
  double get remainingBalance => _remainingBalance;
  double get budget => _budget;
  String get selectedCurrency => _selectedCurrency;
  Map<String, double> get categoryBudgets => _categoryBudgets;
  List<TransactionModel> get transactions => _transactions;

  // Getters for budgets
  double get incomeBudget => _incomeBudget;
  double get expenseBudget => _expenseBudget;
  double get savingBudget => _savingBudget;

  // New method for calculating total savings
  double get totalSavings => _remainingBalance;
  ExpenseIncomeModel() {
    _listenToTransactions();
  }

  // Listen to Firestore for real-time transaction updates
  void _listenToTransactions() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Recalculate totals whenever the stream changes
      _recalculateTotals();
      notifyListeners();
    });
  }

  // Recalculate totals
  void _recalculateTotals() {
    _totalIncome = _transactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);

    _totalExpenses = _transactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);

    _remainingBalance = _budget + _totalIncome - _totalExpenses;
  }

  // Set or update the total budget
  void setBudget(double newBudget) {
    _budget = newBudget;
    _remainingBalance = _budget + _totalIncome - _totalExpenses;

    // Adjust category budgets proportionally
    if (_categoryBudgets.isNotEmpty) {
      double totalCategoryBudget = _categoryBudgets.values.fold(0, (sum, value) => sum + value);
      _categoryBudgets.updateAll((category, value) {
        return (value / totalCategoryBudget) * _budget;
      });
    }
    notifyListeners();
  }

  // Set income, expense, and saving budgets
  void setBudgets(double incomeBudget, double expenseBudget, double savingBudget) {
    _incomeBudget = incomeBudget;
    _expenseBudget = expenseBudget;
    _savingBudget = savingBudget;

    notifyListeners();
  }

  // Save budgets to Firestore
  Future<void> saveBudgetsToDatabase() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await _firestore.collection('users').doc(userId).update({
        'incomeBudget': _incomeBudget,
        'expenseBudget': _expenseBudget,
        'savingBudget': _savingBudget,
      });

      notifyListeners();
    } catch (e) {
      print("Error saving budgets to Firestore: $e");
    }
  }

  // Reset all budgets to default values
  void resetBudgets() {
    _incomeBudget = 0.0;
    _expenseBudget = 0.0;
    _savingBudget = 0.0;

    notifyListeners();
  }

  // Add a transaction (handles both income and expenses) and save it to Firebase
  Future<void> addTransaction(String title, String category, double amount, DateTime date, String type) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final newTransaction = TransactionModel(
      id: '', // ID will be generated by Firestore
      title: title,
      category: category,
      amount: amount,
      date: date,
      type: type,
    );

    try {
      // Save transaction to Firestore under the user's specific collection
      var transactionRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(newTransaction.toFirestore());

      // Update transaction ID locally
      newTransaction.id = transactionRef.id;

      _transactions.add(newTransaction);

      if (type == 'expense') {
        _totalExpenses += amount;
      } else if (type == 'income') {
        _totalIncome += amount;
      }

      _remainingBalance = _budget + _totalIncome - _totalExpenses;

      // Adjust category budget if applicable
      if (_categoryBudgets.containsKey(category) && type == 'expense') {
        _categoryBudgets[category] = _categoryBudgets[category]! - amount;
      }

      notifyListeners();
    } catch (e) {
      print("Error adding transaction: $e");
      rethrow;
    }
  }

  // Delete a transaction from Firestore and update locally
  Future<void> deleteTransaction(TransactionModel transaction) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .delete();

      _transactions.remove(transaction);

      if (transaction.type == 'expense') {
        _totalExpenses -= transaction.amount;
      } else if (transaction.type == 'income') {
        _totalIncome -= transaction.amount;
      }

      _remainingBalance = _budget + _totalIncome - _totalExpenses;

      // Restore category budget if applicable
      if (_categoryBudgets.containsKey(transaction.category) && transaction.type == 'expense') {
        _categoryBudgets[transaction.category] = _categoryBudgets[transaction.category]! + transaction.amount;
      }

      notifyListeners();
    } catch (e) {
      print("Error deleting transaction: $e");
    }
  }

  // Reset all transactions and update Firestore
  Future<void> resetTransactions() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      var batch = _firestore.batch();

      for (var tx in _transactions) {
        batch.delete(_firestore.collection('users').doc(userId)
            .collection('transactions')
            .doc(tx.id));
      }

      await batch.commit();

      _totalExpenses = 0.0;
      _totalIncome = 0.0;
      _remainingBalance = _budget;
      _transactions.clear();

      // Reset category budgets
      _categoryBudgets.updateAll((category, value) => 0.0);

      notifyListeners();
    } catch (e) {
      print("Error resetting transactions: $e");
    }
  }

  // Set or update the selected currency
  void setCurrency(String newCurrency) {
    _selectedCurrency = newCurrency;
    notifyListeners();
  }

  // Fetch transactions from Firestore
  Stream<List<TransactionModel>> fetchTransactions() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  // Filter transactions by type (income or expense)
  List<TransactionModel> filterByType(String type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  // Filter transactions by category
  List<TransactionModel> filterByCategory(String category) {
    if (category == 'All') return _transactions;
    return _transactions.where((tx) => tx.category == category).toList();
  }

  // Filter transactions by date range
  List<TransactionModel> filterByDateRange(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Last Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(2000); // Return all transactions for invalid input
    }

    return _transactions.where((tx) => tx.date.isAfter(startDate)).toList();
  }
}