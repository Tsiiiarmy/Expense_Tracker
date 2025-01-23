import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedDateFilter = 'Today';
  String selectedCategoryFilter = 'All';
  String searchQuery = '';
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontSize: 22.0, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 139, 176),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateFilters(),
          _buildCategoryFilters(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Transactions',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Expenses Tab
                _buildTransactionList('expense'),
                // Income Tab
                _buildTransactionList('income'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Stream<QuerySnapshot> _fetchTransactions(String type) {
  final userId = currentUser?.uid;

  if (userId == null) {
    return const Stream.empty();
  }

  // Get the filter date
  DateTime? filterDate = _getFilterDate(); // Ensure _getFilterDate() can return null

  // Default to today's date if filterDate is null
  DateTime startDate = filterDate ?? DateTime.now();

  // Ensure we include the day by setting time to midnight
  startDate = DateTime(startDate.year, startDate.month, startDate.day);

  // Build the query
  var query = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .where('type', isEqualTo: type)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate)) // Filter by date
      .orderBy('date', descending: true);

  // Uncomment if category filtering is needed
  // if (selectedCategoryFilter != 'All') {
  //   query = query.where('category', isEqualTo: selectedCategoryFilter);
  // }

  return query.snapshots();
}


   Widget _buildTransactionList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchTransactions(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              const Expanded(child: Center(child: Text('No transactions found.'))),
              _buildTotalAmount(0.0),
            ],
          );
        }

        var transactions = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Extract the 'title' and 'category' fields from the document
          final title = data.containsKey('title')
              ? data['title'].toString().toLowerCase()
              : '';
          final category = data.containsKey('category')
              ? data['category'].toString().toLowerCase()
              : '';

          // Check if the title matches the search query and the category matches the filter
          final matchesTitle = title.contains(searchQuery.toLowerCase());
          final matchesCategory = selectedCategoryFilter == "All" || selectedCategoryFilter.isEmpty ||
              category == selectedCategoryFilter.toLowerCase();

          return matchesTitle && matchesCategory;
        }).toList();

        double totalAmount = transactions.fold(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum +
              (data['amount'] is double
                  ? data['amount']
                  : (data['amount'] is int
                      ? (data['amount'] as int).toDouble()
                      : 0.0));
        });

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final data = transaction.data() as Map<String, dynamic>;
                  final title =
                      data.containsKey('title') ? data['title'] : 'No Title';
                  final category = data['category'] ?? 'No Category';
                  final amount = data['amount'] is double
                      ? data['amount']
                      : (data['amount'] is int
                          ? (data['amount'] as int).toDouble()
                          : 0.0);

                  return Dismissible(
                    key: Key(transaction.id),
                    onDismissed: (direction) {
                      _deleteTransaction(transaction.id);
                    },
                    background: Container(
                        color: const Color.fromARGB(255, 73, 156, 186)),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amount.toStringAsFixed(2),
                            style: TextStyle(
                              color: amount >= 0
                                  ? const Color.fromARGB(255, 108, 215, 234)
                                  : const Color.fromARGB(255, 109, 223, 246),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditDialog(transaction.id, data),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildTotalAmount(totalAmount),
          ],
        );
      },
    );
  }

  Widget _buildTotalAmount(double totalAmount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Total: ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            totalAmount.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 39, 133, 176)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .collection('transactions')
        .doc(transactionId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  Future<void> _showEditDialog(
      String transactionId, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: data['title']);
    final categoryController = TextEditingController(text: data['category']);
    final amountController =
        TextEditingController(text: data['amount'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .collection('transactions')
                    .doc(transactionId)
                    .update({
                  'title': titleController.text,
                  'category': categoryController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDateFilterButton('Today'),
            _buildDateFilterButton('Last Week'),
            _buildDateFilterButton('Last Month'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (_tabController.index == 1) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryFilterButton('All'),
              _buildCategoryFilterButton('Salary'),
              _buildCategoryFilterButton('Freelancing'),
              _buildCategoryFilterButton('Business'),
              _buildCategoryFilterButton('Rent'),
              _buildCategoryFilterButton('Investment'),
              _buildCategoryFilterButton('Others'),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryFilterButton('All'),
              _buildCategoryFilterButton('Food'),
              _buildCategoryFilterButton('Bill'),
              _buildCategoryFilterButton('Cloth'),
              _buildCategoryFilterButton('Education'),
              _buildCategoryFilterButton('Shopping'),
              _buildCategoryFilterButton('Transport'),
              _buildCategoryFilterButton('Entertainment'),
              _buildCategoryFilterButton('Hospital'),
              _buildCategoryFilterButton('Loan'),
              _buildCategoryFilterButton('Medicine'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCategoryFilterButton(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryFilter = category;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chip(
          label: Text(category),
          backgroundColor: selectedCategoryFilter == category
              ? const Color.fromARGB(255, 39, 149, 176)
              : Colors.grey.shade200,
          labelStyle: TextStyle(
            color: selectedCategoryFilter == category
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }

  DateTime _getFilterDate() {
    DateTime now = DateTime.now();
    switch (selectedDateFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Last Week':
        return now.subtract(const Duration(days: 7));
      case 'Last Month':
        return DateTime(now.year, now.month - 1, now.day);
      default:
        return DateTime(2000);
    }
  }

  Widget _buildDateFilterButton(String period) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDateFilter = period;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chip(
          label: Text(period),
          backgroundColor: selectedDateFilter == period
              ? const Color.fromARGB(255, 59, 170, 201)
              : Colors.grey.shade200,
          labelStyle: TextStyle(
            color: selectedDateFilter == period ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
