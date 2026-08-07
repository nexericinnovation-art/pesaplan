import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../transactions/transactions_repository.dart';
import '../budgets/budgets_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.clerkUserId,
    required this.currency,
    required this.onTabChanged,
  });

  final String clerkUserId;
  final String currency;
  final Function(int) onTabChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSummary? _summary;
  List<TransactionRecord> _recentTransactions = [];
  List<BudgetCategoryProgress> _budgetCategoryProgress = [];
  double _budgetProgressPercent = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _obscureBalance = false;

  static const backgroundColor = Color(0xFFEFF3FA);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        TransactionsRepository.fetchDashboardSummary(clerkUserId: widget.clerkUserId),
        TransactionsRepository.fetchTransactions(clerkUserId: widget.clerkUserId, limit: 5),
        BudgetsRepository.fetchBudgets(clerkUserId: widget.clerkUserId),
      ]);

      final summary = results[0] as DashboardSummary;
      final txs = results[1] as List<TransactionRecord>;
      final budgets = results[2] as List<BudgetRecord>;

      List<BudgetCategoryProgress> progress = [];
      double percent = 0.0;

      if (budgets.isNotEmpty) {
        progress = await BudgetsRepository.fetchBudgetProgress(
          budgetId: budgets.first.id,
          clerkUserId: widget.clerkUserId,
        );

        double totalAllocated = 0;
        double totalSpent = 0;
        for (final p in progress) {
          totalAllocated += p.allocatedAmount;
          totalSpent += p.spentAmount;
        }
        if (totalAllocated > 0) {
          percent = (totalSpent / totalAllocated).clamp(0.0, 1.0);
        }
      }

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recentTransactions = txs;
        _budgetCategoryProgress = progress;
        _budgetProgressPercent = percent;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load your dashboard. Check your connection and try again.";
      });
    }
  }

  String _formatAmount(num value) {
    return '${widget.currency} ${value.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _getWeekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1D5DE4),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5DE4),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auth = ClerkAuth.of(context);
    final user = auth.client.user;
    final name = user?.firstName ?? 'there';

    final now = DateTime.now();
    final dateString = '${_getWeekdayName(now.weekday)}, ${_getMonthName(now.month)} ${now.day}';

    final summary = _summary!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(0xFF1D5DE4),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              _buildHeader(context, name, dateString),
              const SizedBox(height: 20),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              _buildBalanceCard(context, summary),
              const SizedBox(height: 24),
              _buildBudgetsSection(context),
              const SizedBox(height: 24),
              _buildRecentTransactionsSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String dateString) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $name 👋',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Take control of your money.',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateString,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return _NeumorphicCard(
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      backgroundColor: backgroundColor,
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search transactions, budgets or goals...',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF94A3B8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 22),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardSummary summary) {
    final balanceText = _obscureBalance
        ? '••••••'
        : _formatAmount(summary.lifetimeBalance);

    final incomeText = _formatAmount(summary.monthIncome);
    final expensesText = _formatAmount(summary.monthExpenses);
    final savingsText = _formatAmount(summary.monthSavings);

    final leftThisMonth = summary.monthIncome - summary.monthExpenses;
    final leftThisMonthText = _formatAmount(leftThisMonth > 0 ? leftThisMonth : 0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A8CF7),
            Color(0xFF1D5CE3),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D5CE3).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Balance label + eye icon on left, Progress ring on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Total Balance + amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureBalance = !_obscureBalance;
                            });
                          },
                          child: Icon(
                            _obscureBalance
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balanceText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Progress Ring
              Column(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: ProgressRingPainter(
                        progress: _budgetProgressPercent,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        progressColor: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          '${(_budgetProgressPercent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Budget\nUsed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // White Breakdown Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              children: [
                _buildBreakdownRow(
                  icon: Icons.arrow_upward_rounded,
                  iconBg: const Color(0xFF3B82F6),
                  label: 'Income',
                  amount: incomeText,
                  amountColor: const Color(0xFF2563EB),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                ),
                _buildBreakdownRow(
                  icon: Icons.arrow_downward_rounded,
                  iconBg: const Color(0xFFF43F5E),
                  label: 'Expenses',
                  amount: expensesText,
                  amountColor: const Color(0xFFF43F5E),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                ),
                _buildBreakdownRow(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: const Color(0xFF10B981),
                  label: 'Savings',
                  amount: savingsText,
                  amountColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Left This Month Pill
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF2563EB),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$leftThisMonthText left this month',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBreakdownRow({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String amount,
    required Color amountColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabChanged(2),
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Budgets Content Card
        if (_budgetCategoryProgress.isEmpty)
          _NeumorphicCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20.0),
            backgroundColor: backgroundColor,
            child: Row(
              children: [
                // Illustration / Neumorphic Wallet Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-3, -3),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFAEBECF).withValues(alpha: 0.5),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF2563EB),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No budgets added yet.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create your first budget to get started.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => widget.onTabChanged(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Create Budget',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _budgetCategoryProgress.length,
              itemBuilder: (context, index) {
                final cat = _budgetCategoryProgress[index];
                return _buildCategoryCard(context, cat);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, BudgetCategoryProgress progress) {
    Color themeColor = const Color(0xFF2563EB);
    if (progress.categoryColor != null) {
      try {
        themeColor = Color(int.parse(progress.categoryColor!));
      } catch (_) {}
    }

    IconData iconData = Icons.category_rounded;
    final iconName = progress.categoryIcon ?? '';
    if (iconName.contains('food') || iconName.contains('burger')) {
      iconData = Icons.fastfood_rounded;
    } else if (iconName.contains('car') || iconName.contains('transport')) {
      iconData = Icons.directions_car_rounded;
    } else if (iconName.contains('bill') || iconName.contains('home') || iconName.contains('house')) {
      iconData = Icons.home_rounded;
    } else if (iconName.contains('movie') || iconName.contains('film') || iconName.contains('play')) {
      iconData = Icons.movie_rounded;
    } else if (iconName.contains('shopping') || iconName.contains('bag')) {
      iconData = Icons.shopping_bag_rounded;
    }

    final percentVal = (progress.percentUsed * 100).toStringAsFixed(0);

    return _NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      backgroundColor: backgroundColor,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: themeColor, size: 20),
            ),
            Text(
              progress.categoryName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatAmount(progress.allocatedAmount),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.percentUsed,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percentVal%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      '$percentVal%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabChanged(1),
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Transactions Content
        if (_recentTransactions.isEmpty)
          _NeumorphicCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20.0),
            backgroundColor: backgroundColor,
            child: Row(
              children: [
                // Illustration / Neumorphic Receipt Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-3, -3),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFAEBECF).withValues(alpha: 0.5),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF2563EB),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No transactions yet.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your transactions will appear here.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => widget.onTabChanged(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Add Transaction',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          _NeumorphicCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            backgroundColor: backgroundColor,
            child: Column(
              children: _recentTransactions
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final tx = entry.value;
                    final isLast = index == _recentTransactions.length - 1;
                    return Column(
                      children: [
                        _buildTransactionItem(context, tx),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE2E8F0)),
                          ),
                      ],
                    );
                  })
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionRecord tx) {
    final isIncome = tx.type == 'income';
    final sign = isIncome ? '+' : '-';
    final amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    Color bgCircleColor = const Color(0xFF2563EB);
    IconData icon = Icons.receipt_long_rounded;

    final name = (tx.description?.isNotEmpty == true
            ? tx.description!
            : tx.categoryName ?? 'Transaction')
        .toLowerCase();

    if (name.contains('carrefour') || name.contains('grocer')) {
      bgCircleColor = Colors.blue.shade900;
      icon = Icons.shopping_cart_rounded;
    } else if (name.contains('java') || name.contains('dining') || name.contains('coffee')) {
      bgCircleColor = Colors.brown;
      icon = Icons.coffee_rounded;
    } else if (name.contains('safaricom') || name.contains('airtime')) {
      bgCircleColor = Colors.green;
      icon = Icons.phone_android_rounded;
    } else if (name.contains('salary') || name.contains('employer') || name.contains('pay')) {
      bgCircleColor = Colors.teal;
      icon = Icons.work_rounded;
    } else if (name.contains('bill') || name.contains('rent')) {
      bgCircleColor = Colors.amber.shade800;
      icon = Icons.home_rounded;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFFAEBECF).withValues(alpha: 0.4),
              offset: const Offset(2, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(icon, color: bgCircleColor, size: 20),
      ),
      title: Text(
        tx.description?.isNotEmpty == true
            ? tx.description!
            : (tx.categoryName ?? 'Uncategorized'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        '${tx.categoryName ?? 'Uncategorized'} • '
        '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),
      trailing: Text(
        '$sign${tx.currency} ${tx.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: amountColor,
        ),
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  const _NeumorphicCard({
    required this.child,
    required this.borderRadius,
    required this.padding,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFFAEBECF).withValues(alpha: 0.45),
            offset: const Offset(6, 6),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}