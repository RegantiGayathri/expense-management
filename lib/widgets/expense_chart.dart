import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/expense_provider.dart';
import '../utils/constants.dart';

class ExpenseChart extends StatelessWidget {
  final ExpenseProvider provider;

  const ExpenseChart({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.expenseCategories;

    final data = categories
        .map((category) => provider.categoryExpenses(category))
        .toList();

    final hasData = data.any((amount) => amount > 0);

    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No expense data available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Add expenses to see your chart',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < categories.length; i++) {
      if (data[i] == 0) continue;

      sections.add(
        PieChartSectionData(
          value: data[i],
          title: categories[i],
          radius: 75,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Expense by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 45,
                sectionsSpace: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}