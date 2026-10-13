
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../services/session.dart';
import '../services/transaction_api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<TransactionModel> _transactions = [];

  String _searchQuery = '';
  String _typeFilter = 'All';
  String _categoryFilter = 'All';

  bool isLoading = false;
  String? errorMessage;

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);

  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get categoryFilter => _categoryFilter;

  double get totalIncome => _transactions
      .where((t) => t.type == AppConstants.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == AppConstants.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((transaction) {
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          transaction.title.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query);

      final matchesType =
          _typeFilter == 'All' || transaction.type == _typeFilter;

      final matchesCategory =
          _categoryFilter == 'All' ||
          transaction.category == _categoryFilter;

      return matchesSearch && matchesType && matchesCategory;
    }).toList();
  }

  // Load transactions belonging to the logged-in user.
  Future<void> loadTransactions() async {
    if (Session.userId == null) {
      errorMessage = 'Please log in again to load your transactions.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded =
          await TransactionApiService.getTransactions();

      _transactions
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Save a transaction to MySQL through Flask.
  Future<void> addTransaction(TransactionModel transaction) async {
    errorMessage = null;
    try {
      await TransactionApiService.addTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // The index is the transaction's current position in the full list.
  Future<void> updateTransaction(
    int index,
    TransactionModel transaction,
  ) async {
    if (index < 0 || index >= _transactions.length) return;

    final existing = _transactions[index];
    final updated = transaction.copyWith(id: existing.id);

    errorMessage = null;
    try {
      await TransactionApiService.updateTransaction(updated);
      await loadTransactions();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete from MySQL using the transaction's database ID.
  Future<void> deleteTransaction(int index) async {
    if (index < 0 || index >= _transactions.length) return;

    final transaction = _transactions[index];
    if (transaction.id == null) {
      errorMessage = 'Transaction ID is missing. Reload your transactions.';
      notifyListeners();
      return;
    }

    errorMessage = null;
    try {
      await TransactionApiService.deleteTransaction(transaction.id!);
      await loadTransactions();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = 'All';
    _categoryFilter = 'All';
    notifyListeners();
  }

  double monthlyIncome(int year, int month) {
    return _transactions
        .where((t) =>
            t.type == AppConstants.income &&
            t.date.year == year &&
            t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double monthlyExpenses(int year, int month) {
    return _transactions
        .where((t) =>
            t.type == AppConstants.expense &&
            t.date.year == year &&
            t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double categoryExpenses(String category) {
    return _transactions
        .where((t) =>
            t.type == AppConstants.expense &&
            t.category == category)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String get highestSpendingCategory {
    if (totalExpenses == 0) return 'No expenses';

    String highestCategory = 'Other';
    double highestAmount = 0;

    for (final category in AppConstants.expenseCategories) {
      final amount = categoryExpenses(category);
      if (amount > highestAmount) {
        highestAmount = amount;
        highestCategory = category;
      }
    }

    return highestCategory;
  }
}
