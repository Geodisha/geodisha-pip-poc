import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/election_war_room_service.dart';
import '../../core/services/api_service.dart';
import '../../data/services/ground_reality_service.dart';
import 'booth_score_screen.dart';

Map<String, dynamic> _asMap(dynamic v) {
  if (v == null) return {};
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return {};
}

List<Map<String, dynamic>> _asList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => _asMap(e)).toList();
  return [];
}

/// Election War Room - Tabbed interface merging:
/// 1. Booth Scores (Booth-level analytics)
/// 2. Election Intelligence (Readiness metrics, voter mood)
class ElectionWarRoomScreen extends StatefulWidget {
  const ElectionWarRoomScreen({super.key});

  @override
  State<ElectionWarRoomScreen> createState() => _ElectionWarRoomScreenState();
}

class _ElectionWarRoomScreenState extends State<ElectionWarRoomScreen>
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
        title: const Text('Election War Room'),
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
              icon: Icon(Icons.poll),
              text: 'Booth Scores',
            ),
            Tab(
              icon: Icon(Icons.how_to_vote),
              text: 'Election Intel',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Booth Scores
          const BoothScoreScreen(),
          
          // Tab 2: Election Intelligence (inline)
          const ElectionIntelligenceScreen(),
        ],
      ),
    );
  }
}

// ─── Election Intelligence Screen ─────────────────────────────────────────────
class ElectionIntelligenceScreen extends StatefulWidget {
  const ElectionIntelligenceScreen({super.key});
  @override
  State<ElectionIntelligenceScreen> createState() => _ElectionIntelligenceScreenState();
}

class _ElectionIntelligenceScreenState extends State<ElectionIntelligenceScreen> {
  late ElectionWarRoomService _electionService;
  late GroundRealityService _groundService;

  @override
  void initState() {
    super.initState();
    _electionService = ElectionWarRoomService(ApiService());
    _groundService = GroundRealityService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _electionService.getElectionReadiness(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
              ],
            ),
          );
        }

        final data = _asMap(snapshot.data?['data']);
        final totalBooths      = int.tryParse(data['total_booths']?.toString() ?? '0') ?? 0;
        final secureBooths     = int.tryParse(data['secure_booths']?.toString() ?? '0') ?? 0;
        final vulnerableBooths = int.tryParse(data['vulnerable_booths']?.toString() ?? '0') ?? 0;
        final criticalBooths   = int.tryParse(data['critical_booths']?.toString() ?? '0') ?? 0;
        final readinessPct     = double.tryParse(data['readiness_percentage']?.toString() ?? '0') ?? 0.0;
        final avgScore         = double.tryParse(data['average_booth_score']?.toString() ?? '0') ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Readiness Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Election Readiness', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('${readinessPct.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Avg Booth Score: ${avgScore.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: readinessPct / 100,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          readinessPct >= 70 ? Colors.greenAccent : readinessPct >= 50 ? Colors.orangeAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Booth Status Cards
              const Text('Booth Status Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statusCard('Total', totalBooths, Colors.blueGrey, Icons.poll),
                  const SizedBox(width: 10),
                  _statusCard('Secure', secureBooths, Colors.green, Icons.check_circle),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statusCard('Vulnerable', vulnerableBooths, Colors.orange, Icons.warning),
                  const SizedBox(width: 10),
                  _statusCard('Critical', criticalBooths, Colors.red, Icons.error),
                ],
              ),
              const SizedBox(height: 20),

              // Risk Matrix section
              _buildRiskMatrixSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _statusCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMatrixSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _electionService.getBoothRiskMatrix(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final riskRows = _asList(snapshot.data?['data']).take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Risk Booths', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...riskRows.map((b) {
              final risk = b['risk_level']?.toString() ?? 'secure';
              final color = risk == 'critical' ? Colors.red : risk == 'vulnerable' ? Colors.orange : Colors.green;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(Icons.how_to_vote, color: color, size: 20),
                  ),
                  title: Text(b['booth_name']?.toString() ?? b['booth_number']?.toString() ?? 'Booth'),
                  subtitle: Text('Ward: ${b['location_ward'] ?? 'N/A'} • Score: ${b['booth_score'] ?? 'N/A'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(risk.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
