import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
      apiKey: 'AIzaSyAmu_iULNXWfnfejEjxJ-lPiQ1xjnUK-Lk',
      appId: '1:742102338495:android:bda7c57327be4a3b972f0a',
      messagingSenderId: '742102338495',
      projectId: 'expense-tracker-app-b007d',
      storageBucket: 'expense-tracker-app-b007d.firebasestorage.app',
      databaseURL:
      'https://expense-tracker-app-b007d-default-rtdb.firebaseio.com/');

  static const FirebaseOptions ios = FirebaseOptions(
      apiKey: 'AIzaSyAmu_iULNXWfnfejEjxJ-lPiQ1xjnUK-Lk',
      appId: '1:742102338495:android:bda7c57327be4a3b972f0a',
      messagingSenderId: '742102338495',
      projectId: 'expense-tracker-app-b007d',
      storageBucket: 'expense-tracker-app-b007d.firebasestorage.app',
      iosBundleId: 'com.example.expense_tracker_app',
      databaseURL:
      'https://expense-tracker-app-b007d-default-rtdb.firebaseio.com/');
}

// FirebaseService class for Firestore interactions
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user's ID

  // Save transaction history
  Future<void> saveTransaction(double amount, DateTime date) async {
    try {
      await _firestore.collection('users')
          .doc(userId) // Save data under the current user's ID
          .collection('transactions')
          .add({
        'amount': amount,
        'date': date,
      });
      print("Transaction saved successfully.");
    } catch (e) {
      print("Error saving transaction: $e");
    }
  }

  // Save report data
  Future<void> saveReport(String title, String content) async {
    try {
      await _firestore.collection('users')
          .doc(userId) // Save report data under the current user's ID
          .collection('reports')
          .add({
        'title': title,
        'content': content,
        'date': DateTime.now(),
      });
      print("Report saved successfully.");
    } catch (e) {
      print("Error saving report: $e");
    }
  }

  // Retrieve transaction history
  Stream<QuerySnapshot> getTransactionHistory() {
    return _firestore.collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots(); // Use snapshots to listen for real-time updates
  }

  // Retrieve report data
  Stream<QuerySnapshot> getReportData() {
    return _firestore.collection('users')
        .doc(userId)
        .collection('reports')
        .snapshots(); // Use snapshots to listen for real-time updates
  }
}
