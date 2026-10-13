
import 'package:flutter/material.dart';

class AppConstants {
  // App information
  static const String appName = 'Expense Management';

  // Transaction types
  static const String income = 'income';
  static const String expense = 'expense';

  // Expense categories
  static const List<String> expenseCategories = [
    'Food',
    'Travel',
    'Shopping',
    'Education',
    'Entertainment',
    'Health',
    'Bills',
    'Other',
  ];

  // Income categories
  static const List<String> incomeCategories = [
    'Salary',
    'Scholarship',
    'Allowance',
    'Freelance',
    'Gift',
    'Other',
  ];

  // Main application color
  static const Color primaryColor = Color(0xFF6C4CE6);

  // Background color
  static const Color backgroundColor = Color(0xFFF6F7FB);
}