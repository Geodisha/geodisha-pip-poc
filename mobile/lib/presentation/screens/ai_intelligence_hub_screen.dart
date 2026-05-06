import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'recommendations_screen.dart';
import 'media_ai_screen.dart';
import 'strategic_intelligence_screen.dart';

/// AI Intelligence Hub - Tabbed interface merging:
/// 1. AI Recommendations (Smart suggestions)
/// 2. Media AI (Talking points, media assistance)
/// 3. Strategic Intelligence (Influencer mapping, visit planning)
class AIIntelligenceHubScreen extends StatefulWidget {
  const AIIntelligenceHubScreen({super.key});

  @override
  State<AIIntelligenceHubScreen> createState() => _AIIntelligenceHubScreenState();
}

class _AIIntelligenceHubScreenState extends State<AIIntelligenceHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('AI Intelligence Hub'),
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
              icon: Icon(Icons.lightbulb_outline),
              text: 'Recommendations',
            ),
            Tab(
              icon: Icon(Icons.mic),
              text: 'Media AI',
            ),
            Tab(
              icon: Icon(Icons.psychology),
              text: 'Strategic Intel',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: AI Recommendations
          const RecommendationsScreen(),
          
          // Tab 2: Media AI
          const MediaAIScreen(),
          
          // Tab 3: Strategic Intelligence
          const StrategicIntelligenceScreen(),
        ],
      ),
    );
  }
}
