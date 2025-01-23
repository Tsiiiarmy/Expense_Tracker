import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/expense_model.dart';

class BudgetingScreen extends StatefulWidget {
  const BudgetingScreen({super.key});

  @override
  _BudgetingScreenState createState() => _BudgetingScreenState();
}

class _BudgetingScreenState extends State<BudgetingScreen> {
  @override
  Widget build(BuildContext context) {
    final expenseModel = Provider.of<ExpenseIncomeModel>(context);

    // Get data from ExpenseIncomeModel
    double incomeBudget = expenseModel.incomeBudget;
    double expenseBudget = expenseModel.expenseBudget;

    double totalIncome = expenseModel.totalIncome;
    double totalExpenses = expenseModel.totalExpenses;

    double remainingIncome = incomeBudget - totalIncome;
    double remainingExpense = expenseBudget - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budget'),
        backgroundColor: const Color.fromARGB(255, 39, 135, 176),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Budget sections for Income and Expense
            buildBudgetSection(
              title: 'Income Budget',
              budget: incomeBudget,
              spentAmount: totalIncome,
              remainingAmount: remainingIncome,
              onChanged: (value) => setState(() {
                expenseModel.setBudgets(value, expenseBudget, 0); // Added default saving value
              }),
            ),
            buildBudgetSection(
              title: 'Expense Budget',
              budget: expenseBudget,
              spentAmount: totalExpenses,
              remainingAmount: remainingExpense,
              onChanged: (value) => setState(() {
                expenseModel.setBudgets(incomeBudget, value, 0); // Added default saving value
              }),
            ),

            // Save Budget Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await expenseModel.saveBudgetsToDatabase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Budgets saved successfully")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 128, 221, 255),
                ),
                child: const Text('Save Budgets'),
              ),
            ),

            // Reset Budget Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  expenseModel.resetBudgets();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Budgets reset for the new month")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 128, 208, 255),
                ),
                child: const Text('Reset Budgets'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBudgetSection({
    required String title,
    required double budget,
    required double spentAmount,
    required double remainingAmount,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: BDT ${budget.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        LinearProgressIndicator(
          value: (spentAmount / (budget == 0 ? 1 : budget)).clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          color: Colors.purple,
        ),
        const SizedBox(height: 10),
        Text(
          'Remaining: BDT ${remainingAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: remainingAmount >= 0 ? Colors.green : Colors.red,
          ),
        ),
        Slider(
          value: budget,
          min: 0,
          max: 100000,
          divisions: 50,
          label: 'BDT ${budget.toStringAsFixed(0)}',
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
