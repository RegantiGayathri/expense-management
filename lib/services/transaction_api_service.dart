
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';
import 'session.dart';

class TransactionApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  static int get _userId {
    final id = Session.userId;
    if (id == null) {
      throw Exception('Please log in again.');
    }
    return id;
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions?user_id=$_userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not load transactions: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((item) => TransactionModel.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static Future<void> addTransaction(
    TransactionModel transaction,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: _headers,
      body: jsonEncode({
        'user_id': _userId,
        'title': transaction.title,
        'amount': transaction.amount,
        'type': transaction.type,
        'category': transaction.category,
        'date': transaction.date.toIso8601String().split('T').first,
        'description': transaction.description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Could not save transaction: ${response.body}');
    }
  }

  static Future<void> updateTransaction(
    TransactionModel transaction,
  ) async {
    if (transaction.id == null) {
      throw Exception('This transaction has no database ID.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/transactions/${transaction.id}'),
      headers: _headers,
      body: jsonEncode({
        'user_id': _userId,
        'title': transaction.title,
        'amount': transaction.amount,
        'type': transaction.type,
        'category': transaction.category,
        'date': transaction.date.toIso8601String().split('T').first,
        'description': transaction.description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not update transaction: ${response.body}');
    }
  }

  static Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id?user_id=$_userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not delete transaction: ${response.body}');
    }
  }
}
