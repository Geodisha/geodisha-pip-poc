import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'executive_overview_screen.dart';
import 'analytics_dashboard_screen.dart';

/// Command Center - Tabbed interface merging:
/// 1. Executive Overview (High-level KPIs and constituency health)
/// 2. Analytics Dashboard (Detailed charts and visualizations)
class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: AppTheme.primaryGradientDecoration(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Executive Overview
          ExecutiveOverviewScreen(),
          
          // Tab 2: Analytics Dashboard
          AnalyticsDashboardScreen(),
        ],
      ),
    );
  }
}
