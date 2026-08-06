import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_design_tokens.dart';
import '../../ui/design_system/components/app_card.dart';
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
    return '${widget.currency} ${value.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }

    final auth = ClerkAuth.of(context);
    final user = auth.client.user;
    final name = user != null ? (user.firstName ?? 'Eric') : 'Eric';

    final now = DateTime.now();
    final dateString = '${_getWeekdayName(now.weekday)}, ${_getMonthName(now.month)} ${now.day}';

    final summary = _summary!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
              _buildHeader(context, name, dateString),
              const SizedBox(height: 20),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              _buildBalanceCard(context, summary),
              const SizedBox(height: 24),
              _buildBudgetCategories(context),
              const SizedBox(height: 24),
              _buildRecentTransactions(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String dateString) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menu tapped')),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, $name 👋',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take control of',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      'your money.',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications tapped')),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.black87),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black38, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search transactions, budgets or goals...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice search tapped')),
              );
            },
            child: const Icon(Icons.mic_none_rounded, color: Colors.black38, size: 22),
          ),
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

    return AppCard(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.purpleClay,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
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
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    balanceText,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBalanceSubItem(
                    icon: Icons.arrow_upward_rounded,
                    iconBg: const Color(0xFF10B981),
                    label: 'Income',
                    amount: incomeText,
                  ),
                  const SizedBox(height: 8),
                  _buildBalanceSubItem(
                    icon: Icons.arrow_downward_rounded,
                    iconBg: const Color(0xFFF43F5E),
                    label: 'Expenses',
                    amount: expensesText,
                  ),
                  const SizedBox(height: 8),
                  _buildBalanceSubItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconBg: Colors.amber,
                    label: 'Savings',
                    amount: savingsText,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wallet_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$leftThisMonthText left this month',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: ProgressRingPainter(
                        progress: _budgetProgressPercent,
                        backgroundColor: Colors.white24,
                        progressColor: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          '${(_budgetProgressPercent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Monthly Budget\nUsed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSubItem({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String amount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategories(BuildContext context) {
    final displayProgress = _budgetCategoryProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Categories',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (displayProgress.isNotEmpty)
              GestureDetector(
                onTap: () => widget.onTabChanged(2),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayProgress.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a budget to take control of your spending.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => widget.onTabChanged(2),
                  child: const Text(
                    'Create a budget',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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
              itemCount: displayProgress.length,
              itemBuilder: (context, index) {
                final cat = displayProgress[index];
                return _buildCategoryCard(context, cat);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, BudgetCategoryProgress progress) {
    Color themeColor = AppColors.primary;
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

    return AppCard(
      margin: const EdgeInsets.only(right: 12.0, bottom: 4.0),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: themeColor, size: 20),
            ),
            Text(
              progress.categoryName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              _formatAmount(progress.allocatedAmount),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.percentUsed,
                    backgroundColor: Colors.black12,
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
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      '$percentVal%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: Colors.black38,
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

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabChanged(1),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "You haven't added any transactions yet.",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          Column(
            children: _recentTransactions.map((tx) => _buildTransactionItem(context, tx)).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionRecord tx) {
    final isIncome = tx.type == 'income';
    final sign = isIncome ? '+' : '-';
    final amountColor = isIncome ? const Color(0xFF10B981) : Colors.redAccent;

    Color bgCircleColor = AppColors.primary;
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
      bgCircleColor = Colors.amber;
      icon = Icons.home_rounded;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgCircleColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: bgCircleColor, size: 20),
        ),
        title: Text(
          tx.description?.isNotEmpty == true
              ? tx.description!
              : (tx.categoryName ?? 'Uncategorized'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${tx.categoryName ?? 'Uncategorized'} • '
          '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Colors.black38,
          ),
        ),
        trailing: Text(
          '$sign${tx.currency} ${tx.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
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
    const strokeWidth = 8.0;
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