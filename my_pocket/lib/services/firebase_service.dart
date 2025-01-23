import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pocket/model/expense_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to get the current user's ID
  String? get userId {
    return _auth.currentUser?.uid;
  }

  // Helper function to check if the user is authenticated
  bool get _isUserAuthenticated => userId != null;

  // Save transaction with amount, date, category, note, and type (expense/income)
  Future<void> saveTransaction(double amount, DateTime date, String category, String note, String type) async {
    try {
      if (_isUserAuthenticated) {
        // Create a new TransactionModel object
        TransactionModel newTransaction = TransactionModel(
          id: '', // Firestore will auto-generate this
          title: note,
          category: category,
          amount: amount,
          date: date,
          type: type, // Specify whether it's income or expense
        );

        // Save transaction to Firestore
        await _firestore
            .collection('users')
            .doc(userId) // Save data under the current user's ID
            .collection('transactions')
            .add(newTransaction.toFirestore()..['timestamp'] = FieldValue.serverTimestamp());

        print("Transaction saved successfully.");
      } else {
        throw FirebaseAuthException(
          code: 'USER_NOT_AUTHENTICATED',
          message: 'User is not authenticated. Please log in.',
        );
      }
    } catch (e) {
      print("Error saving transaction: $e");
      rethrow; // Re-throw the error for handling in the UI
    }
  }

  // Retrieve transaction history (Stream for real-time updates)
  Stream<List<TransactionModel>> getTransactionHistory() {
    if (_isUserAuthenticated) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      });
    } else {
      print("User is not authenticated. Returning empty list.");
      return Stream.value([]); // Return an empty list
    }
  }

  // Retrieve transactions filtered by type (income or expense)
  Stream<List<TransactionModel>> getTransactionsByType(String type) {
    if (_isUserAuthenticated) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      });
    } else {
      print("User is not authenticated. Returning empty list.");
      return Stream.value([]);
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      if (_isUserAuthenticated) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(transactionId)
            .delete();

        print("Transaction deleted successfully.");
      } else {
        throw FirebaseAuthException(
          code: 'USER_NOT_AUTHENTICATED',
          message: 'User is not authenticated. Please log in.',
        );
      }
    } catch (e) {
      print("Error deleting transaction: $e");
      rethrow;
    }
  }

  // Reset all transactions for the user
  Future<void> resetAllTransactions() async {
    try {
      if (_isUserAuthenticated) {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        WriteBatch batch = _firestore.batch();

        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        print("All transactions reset successfully.");
      } else {
        throw FirebaseAuthException(
          code: 'USER_NOT_AUTHENTICATED',
          message: 'User is not authenticated. Please log in.',
        );
      }
    } catch (e) {
      print("Error resetting transactions: $e");
      rethrow;
    }
  }

  // Retrieve transactions filtered by date range
  Stream<List<TransactionModel>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    if (_isUserAuthenticated) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      });
    } else {
      print("User is not authenticated. Returning empty list.");
      return Stream.value([]);
    }
  }

  // Fetch total expenses and income
  Future<Map<String, double>> fetchTotals() async {
  double totalExpenses = 0.0;
  double totalIncome = 0.0;

  try {
    if (_isUserAuthenticated) {
      QuerySnapshot snapshot = await _firestore.collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = data['amount'] is int ? (data['amount'] as int).toDouble() : data['amount'];
        String type = data['type'];

        if (type == 'expense') {
          totalExpenses += amount;
        } else if (type == 'income') {
          totalIncome += amount;
        }
      }
    } else {
      throw FirebaseAuthException(
        code: 'USER_NOT_AUTHENTICATED',
        message: 'User is not authenticated. Please log in.',
      );
    }
  } catch (e) {
    print("Error fetching totals: $e");
    rethrow;
  }

  return {
    'totalExpenses': totalExpenses,
    'totalIncome': totalIncome,
  };
}
}

  