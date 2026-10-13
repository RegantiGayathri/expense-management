import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../models/transaction_model.dart';

import '../providers/expense_provider.dart';

import '../utils/constants.dart';

class TransactionsScreen extends StatefulWidget {

  const TransactionsScreen({super.key});

  @override

  State<TransactionsScreen> createState() =>

      _TransactionsScreenState();

}

class _TransactionsScreenState extends State<TransactionsScreen> {

  final TextEditingController _searchController =

      TextEditingController();

  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }

  void _openTransactionForm({

    TransactionModel? transaction,

    int? index,

  }) {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) => TransactionForm(

        transaction: transaction,

        index: index,

      ),

    );

  }

  void _navigateTo(String route) {

    Navigator.pushReplacementNamed(context, route);

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

    appBar: AppBar(

      leading: IconButton(

        icon: const Icon(Icons.arrow_back),

        onPressed: () {

          Navigator.pushReplacementNamed(context, '/home');

        },

      ),

      title: const Text(

        'Transactions',

        style: TextStyle(fontWeight: FontWeight.bold),

      ),

      backgroundColor: AppConstants.primaryColor,

      foregroundColor: Colors.white,

    ),

      body: Consumer<ExpenseProvider>(

        builder: (context, provider, child) {

          final transactions = provider.filteredTransactions;

          return Column(

            children: [

              Padding(

                padding: const EdgeInsets.all(16),

                child: TextField(

                  controller: _searchController,

                  onChanged: provider.setSearchQuery,

                  decoration: InputDecoration(

                    hintText: 'Search title or category',

                    prefixIcon: const Icon(Icons.search),

                    suffixIcon: _searchController.text.isNotEmpty

                        ? IconButton(

                            onPressed: () {

                              _searchController.clear();

                              provider.setSearchQuery('');

                              setState(() {});

                            },

                            icon: const Icon(Icons.clear),

                          )

                        : null,

                    filled: true,

                    fillColor: Colors.white,

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide.none,

                    ),

                  ),

                ),

              ),

              SizedBox(

                height: 45,

                child: ListView(

                  padding: const EdgeInsets.symmetric(

                    horizontal: 16,

                  ),

                  scrollDirection: Axis.horizontal,

                  children: [

                    _FilterChip(

                      label: 'All',

                      selected: provider.typeFilter == 'All',

                      onSelected: () =>

                          provider.setTypeFilter('All'),

                    ),

                    const SizedBox(width: 8),

                    _FilterChip(

                      label: 'Income',

                      selected: provider.typeFilter ==

                          AppConstants.income,

                      onSelected: () => provider.setTypeFilter(

                        AppConstants.income,

                      ),

                    ),

                    const SizedBox(width: 8),

                    _FilterChip(

                      label: 'Expense',

                      selected: provider.typeFilter ==

                          AppConstants.expense,

                      onSelected: () => provider.setTypeFilter(

                        AppConstants.expense,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 12),

              Padding(

                padding: const EdgeInsets.symmetric(

                  horizontal: 16,

                ),

                child: DropdownButtonFormField<String>(

                  value: provider.categoryFilter,

                  decoration: InputDecoration(

                    labelText: 'Category',

                    filled: true,

                    fillColor: Colors.white,

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide.none,

                    ),

                  ),

                  items: [

                    const DropdownMenuItem(

                      value: 'All',

                      child: Text('All Categories'),

                    ),

                    ...AppConstants.expenseCategories.map(

                      (category) => DropdownMenuItem(

                        value: category,

                        child: Text(category),

                      ),

                    ),

                    ...AppConstants.incomeCategories

                        .where(

                          (category) =>

                              !AppConstants.expenseCategories

                                  .contains(category),

                        )

                        .map(

                          (category) => DropdownMenuItem(

                            value: category,

                            child: Text(category),

                          ),

                        ),

                  ],

                  onChanged: (value) {

                    if (value != null) {

                      provider.setCategoryFilter(value);

                    }

                  },

                ),

              ),

              if (provider.errorMessage != null)

                Padding(

                  padding: const EdgeInsets.all(12),

                  child: Text(

                    provider.errorMessage!,

                    style: const TextStyle(color: Colors.red),

                  ),

                ),

              const SizedBox(height: 8),

              Expanded(

                child: provider.isLoading

                    ? const Center(

                        child: CircularProgressIndicator(),

                      )

                    : transactions.isEmpty

                        ? const _EmptyTransactions()

                        : ListView.builder(

                            padding: const EdgeInsets.symmetric(

                              horizontal: 16,

                              vertical: 8,

                            ),

                            itemCount: transactions.length,

                            itemBuilder: (context, i) {

                              final transaction = transactions[i];

                              return _TransactionItem(

                                transaction: transaction,

                                onEdit: () {

                                  final originalIndex =

                                      provider.transactions.indexOf(

                                    transaction,

                                  );

                                  if (originalIndex >= 0) {

                                    _openTransactionForm(

                                      transaction: transaction,

                                      index: originalIndex,

                                    );

                                  }

                                },

                                onDelete: () {

                                  final originalIndex =

                                      provider.transactions.indexOf(

                                    transaction,

                                  );

                                  if (originalIndex >= 0) {

                                    _deleteTransaction(

                                      context,

                                      provider,

                                      originalIndex,

                                    );

                                  }

                                },

                              );

                            },

                          ),

              ),

            ],

          );

        },

      ),

      floatingActionButton: FloatingActionButton(

        backgroundColor: AppConstants.primaryColor,

        foregroundColor: Colors.white,

        onPressed: () => _openTransactionForm(),

        child: const Icon(Icons.add),

      ),

      // Bottom navigation

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: 1,

        selectedItemColor: AppConstants.primaryColor,

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        onTap: (index) {

          if (index == 0) {

            _navigateTo('/home');

          } else if (index == 2) {

            _navigateTo('/analytics');

          }

        },

        items: const [

          BottomNavigationBarItem(

            icon: Icon(Icons.home_outlined),

            label: 'Home',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.receipt_long_outlined),

            label: 'Transactions',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.analytics_outlined),

            label: 'Analytics',

          ),

        ],

      ),

    );

  }

  Future<void> _deleteTransaction(

    BuildContext context,

    ExpenseProvider provider,

    int index,

  ) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Delete Transaction'),

        content: const Text(

          'Are you sure you want to delete this transaction?',

        ),

        actions: [

          TextButton(

            onPressed: () =>

                Navigator.pop(dialogContext, false),

            child: const Text('Cancel'),

          ),

          ElevatedButton(

            onPressed: () =>

                Navigator.pop(dialogContext, true),

            child: const Text('Delete'),

          ),

        ],

      ),

    );

    if (confirmed != true || !context.mounted) return;

    await provider.deleteTransaction(index);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(

          provider.errorMessage ?? 'Delete request completed',

        ),

      ),

    );

  }

}

class _FilterChip extends StatelessWidget {

  final String label;

  final bool selected;

  final VoidCallback onSelected;

  const _FilterChip({

    required this.label,

    required this.selected,

    required this.onSelected,

  });

  @override

  Widget build(BuildContext context) {

    return ChoiceChip(

      label: Text(label),

      selected: selected,

      onSelected: (_) => onSelected(),

      selectedColor: AppConstants.primaryColor,

      labelStyle: TextStyle(

        color: selected ? Colors.white : Colors.black87,

        fontWeight: FontWeight.w500,

      ),

    );

  }

}

class _EmptyTransactions extends StatelessWidget {

  const _EmptyTransactions();

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(

            Icons.receipt_long_outlined,

            size: 70,

            color: Colors.grey.shade400,

          ),

          const SizedBox(height: 16),

          Text(

            'No transactions found',

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Colors.grey.shade700,

            ),

          ),

          const SizedBox(height: 8),

          Text(

            'Add your first income or expense',

            style: TextStyle(color: Colors.grey.shade500),

          ),

        ],

      ),

    );

  }

}

class _TransactionItem extends StatelessWidget {

  final TransactionModel transaction;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const _TransactionItem({

    required this.transaction,

    required this.onEdit,

    required this.onDelete,

  });

  @override

  Widget build(BuildContext context) {

    final isIncome =

        transaction.type == AppConstants.income;

    return Container(

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 8,

            offset: const Offset(0, 3),

          ),

        ],

      ),

      child: Row(

        children: [

          Container(

            width: 46,

            height: 46,

            decoration: BoxDecoration(

              color: (isIncome ? Colors.green : Colors.red)

                  .withOpacity(0.1),

              shape: BoxShape.circle,

            ),

            child: Icon(

              isIncome

                  ? Icons.arrow_downward

                  : Icons.arrow_upward,

              color: isIncome ? Colors.green : Colors.red,

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  transaction.title,

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 15,

                  ),

                ),

                const SizedBox(height: 4),

                Text(

                  '${transaction.category} • ${_formatDate(transaction.date)}',

                  style: TextStyle(

                    color: Colors.grey.shade600,

                    fontSize: 12,

                  ),

                ),

                if (transaction.description.isNotEmpty) ...[

                  const SizedBox(height: 4),

                  Text(

                    transaction.description,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(

                      color: Colors.grey.shade500,

                      fontSize: 12,

                    ),

                  ),

                ],

              ],

            ),

          ),

          const SizedBox(width: 8),

          Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(

                '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',

                style: TextStyle(

                  color: isIncome ? Colors.green : Colors.red,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(height: 4),

              Row(

                children: [

                  IconButton(

                    onPressed: onEdit,

                    icon: const Icon(

                      Icons.edit_outlined,

                      size: 19,

                    ),

                    padding: EdgeInsets.zero,

                    constraints: const BoxConstraints(),

                  ),

                  const SizedBox(width: 12),

                  IconButton(

                    onPressed: onDelete,

                    icon: const Icon(

                      Icons.delete_outline,

                      size: 19,

                    ),

                    color: Colors.red,

                    padding: EdgeInsets.zero,

                    constraints: const BoxConstraints(),

                  ),

                ],

              ),

            ],

          ),

        ],

      ),

    );

  }

  String _formatDate(DateTime date) {

    return '${date.day.toString().padLeft(2, '0')}/'

        '${date.month.toString().padLeft(2, '0')}/'

        '${date.year}';

  }

}

class TransactionForm extends StatefulWidget {

  final TransactionModel? transaction;

  final int? index;

  const TransactionForm({

    super.key,

    this.transaction,

    this.index,

  });

  @override

  State<TransactionForm> createState() =>

      _TransactionFormState();

}

class _TransactionFormState extends State<TransactionForm> {

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late final TextEditingController _amountController;

  late final TextEditingController _descriptionController;

  String _type = AppConstants.expense;

  String _category = AppConstants.expenseCategories.first;

  DateTime _selectedDate = DateTime.now();

  bool _saving = false;

  bool get isEditing => widget.transaction != null;

  @override

  void initState() {

    super.initState();

    final transaction = widget.transaction;

    _titleController = TextEditingController(

      text: transaction?.title ?? '',

    );

    _amountController = TextEditingController(

      text: transaction?.amount.toString() ?? '',

    );

    _descriptionController = TextEditingController(

      text: transaction?.description ?? '',

    );

    if (transaction != null) {

      _type = transaction.type;

      _category = transaction.category;

      _selectedDate = transaction.date;

    }

  }

  @override

  void dispose() {

    _titleController.dispose();

    _amountController.dispose();

    _descriptionController.dispose();

    super.dispose();

  }

  List<String> get categories {

    return _type == AppConstants.income

        ? AppConstants.incomeCategories

        : AppConstants.expenseCategories;

  }

  @override

  Widget build(BuildContext context) {

    return Container(

      padding: EdgeInsets.only(

        left: 20,

        right: 20,

        top: 20,

        bottom: MediaQuery.of(context).viewInsets.bottom + 20,

      ),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(

          top: Radius.circular(24),

        ),

      ),

      child: SingleChildScrollView(

        child: Form(

          key: _formKey,

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Center(

                child: Container(

                  width: 45,

                  height: 5,

                  decoration: BoxDecoration(

                    color: Colors.grey.shade300,

                    borderRadius: BorderRadius.circular(10),

                  ),

                ),

              ),

              const SizedBox(height: 20),

              Text(

                isEditing ? 'Edit Transaction' : 'Add Transaction',

                style: const TextStyle(

                  fontSize: 22,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(height: 20),

              TextFormField(

                controller: _titleController,

                decoration: const InputDecoration(

                  labelText: 'Title',

                  prefixIcon: Icon(Icons.title),

                  border: OutlineInputBorder(),

                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {

                    return 'Please enter a title';

                  }

                  return null;

                },

              ),

              const SizedBox(height: 14),

              TextFormField(

                controller: _amountController,

                keyboardType:

                    const TextInputType.numberWithOptions(

                  decimal: true,

                ),

                decoration: const InputDecoration(

                  labelText: 'Amount',

                  prefixIcon: Icon(Icons.currency_rupee),

                  border: OutlineInputBorder(),

                ),

                validator: (value) {

                  final amount = double.tryParse(value ?? '');

                  if (amount == null || amount <= 0) {

                    return 'Enter a valid amount';

                  }

                  return null;

                },

              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(

                value: _type,

                decoration: const InputDecoration(

                  labelText: 'Type',

                  prefixIcon: Icon(Icons.swap_vert),

                  border: OutlineInputBorder(),

                ),

                items: const [

                  DropdownMenuItem(

                    value: AppConstants.income,

                    child: Text('Income'),

                  ),

                  DropdownMenuItem(

                    value: AppConstants.expense,

                    child: Text('Expense'),

                  ),

                ],

                onChanged: _saving

                    ? null

                    : (value) {

                        if (value == null) return;

                        setState(() {

                          _type = value;

                          _category = categories.first;

                        });

                      },

              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(

                value: categories.contains(_category)

                    ? _category

                    : categories.first,

                decoration: const InputDecoration(

                  labelText: 'Category',

                  prefixIcon: Icon(Icons.category_outlined),

                  border: OutlineInputBorder(),

                ),

                items: categories.map((category) {

                  return DropdownMenuItem(

                    value: category,

                    child: Text(category),

                  );

                }).toList(),

                onChanged: _saving

                    ? null

                    : (value) {

                        if (value != null) {

                          setState(() => _category = value);

                        }

                      },

              ),

              const SizedBox(height: 14),

              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Date'),
                  subtitle: Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: _saving ? null : _selectDate,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(

                controller: _descriptionController,

                maxLines: 3,

                decoration: const InputDecoration(

                  labelText: 'Description',

                  prefixIcon: Icon(Icons.description_outlined),

                  border: OutlineInputBorder(),

                ),

              ),

              const SizedBox(height: 20),

              SizedBox(

                width: double.infinity,

                height: 52,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: AppConstants.primaryColor,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(14),

                    ),

                  ),

                  onPressed: _saving ? null : _saveTransaction,

                  child: _saving

                      ? const SizedBox(

                          height: 22,

                          width: 22,

                          child: CircularProgressIndicator(

                            strokeWidth: 2,

                            color: Colors.white,

                          ),

                        )

                      : Text(

                          isEditing

                              ? 'Update Transaction'

                              : 'Save Transaction',

                          style: const TextStyle(

                            fontSize: 16,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  Future<void> _selectDate() async {

    final date = await showDatePicker(

      context: context,

      initialDate: _selectedDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

    );

    if (date != null && mounted) {

      setState(() => _selectedDate = date);

    }

  }

  Future<void> _saveTransaction() async {

    if (_saving || !_formKey.currentState!.validate()) {

      return;

    }

    final provider = context.read<ExpenseProvider>();

    final amount = double.parse(_amountController.text.trim());

    // Check balance before saving an expense. If editing, the existing

    // transaction is excluded so its old amount is not counted twice.

    double totalIncome = 0;

    double totalExpenses = 0;

    for (var i = 0; i < provider.transactions.length; i++) {

      // Exclude the transaction being edited from the old totals.

      if (isEditing && widget.index != null && i == widget.index) {

        continue;

      }

      final existing = provider.transactions[i];

      if (existing.type == AppConstants.income) {

        totalIncome += existing.amount;

      } else if (existing.type == AppConstants.expense) {

        totalExpenses += existing.amount;

      }

    }

    final availableBalance = totalIncome - totalExpenses;

    if (_type == AppConstants.expense && amount > availableBalance) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            availableBalance < 0

                ? 'Insufficient balance. Your current balance is negative.'

                : 'Insufficient balance! Available: ₹${availableBalance.toStringAsFixed(2)}',

          ),

          backgroundColor: Colors.red,

        ),

      );

      return;

    }

    setState(() => _saving = true);

    final transaction = TransactionModel(

      id: widget.transaction?.id,

      title: _titleController.text.trim(),

      amount: amount,

      type: _type,

      category: _category,

      date: _selectedDate,

      description: _descriptionController.text.trim(),

    );

    try {

      provider.errorMessage = null;

      if (isEditing && widget.index != null) {

        await provider.updateTransaction(

          widget.index!,

          transaction,

        );

      } else {

        await provider.addTransaction(transaction);

      }

      if (!mounted) return;

      if (provider.errorMessage != null) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(provider.errorMessage!),

            backgroundColor: Colors.red,

          ),

        );

        return;

      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            isEditing

                ? 'Transaction updated successfully'

                : 'Transaction saved successfully',

          ),

          backgroundColor: Colors.green,

        ),

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Failed to save transaction: $e'),

          backgroundColor: Colors.red,

        ),

      );

    } finally {

      if (mounted) {

        setState(() => _saving = false);

      }

    }

  }

}
