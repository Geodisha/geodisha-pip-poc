import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'visits_list_screen_enhanced.dart';
//import 'visits_list_screen.dart';
import 'constituency_heatmap_screen.dart';

/// Ground Reality - Tabbed interface merging:
/// 1. Visit Records (List view with statistics)
/// 2. Constituency Heatmap (Map view with risk analysis)
class GroundRealityScreen extends StatefulWidget {
  const GroundRealityScreen({super.key});

  @override
  State<GroundRealityScreen> createState() => _GroundRealityScreenState();
}

class _GroundRealityScreenState extends State<GroundRealityScreen>
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
        title: const Text('Ground Reality'),
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
              icon: Icon(Icons.history),
              text: 'Visit Records',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Heatmap',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Visit Records
          VisitsListScreenEnhanced(),
          
          // Tab 2: Constituency Heatmap
          ConstituencyHeatmapScreen(),
        ],
      ),
    );
  }
}
