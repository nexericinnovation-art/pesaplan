import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/savings_goals_screen.dart';
import '../profile/profile_screen.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_design_tokens.dart';

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({
    super.key,
    required this.clerkUserId,
    required this.currency,
  });

  final String clerkUserId;
  final String currency;

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        clerkUserId: widget.clerkUserId,
        currency: widget.currency,
        onTabChanged: _onTabChanged,
      ),
      TransactionsScreen(
        clerkUserId: widget.clerkUserId,
        currency: widget.currency,
      ),
      BudgetsScreen(
        clerkUserId: widget.clerkUserId,
        currency: widget.currency,
      ),
      SavingsGoalsScreen(
        clerkUserId: widget.clerkUserId,
        currency: widget.currency,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Keep screens alive or just show the active one
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 12.0, bottom: 20.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.pie_chart_rounded,
            label: 'Budgets',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.track_changes_rounded,
            label: 'Goals',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black38,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
