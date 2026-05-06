import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_intelligence_service.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/animated_charts.dart';

class MediaAIScreen extends ConsumerStatefulWidget {
  const MediaAIScreen({super.key});

  @override
  ConsumerState<MediaAIScreen> createState() => _MediaAIScreenState();
}

class _MediaAIScreenState extends ConsumerState<MediaAIScreen> {
  late AIIntelligenceService _aiService;
  
  @override
  void initState() {
    super.initState();
    _aiService = AIIntelligenceService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _aiService.getMediaBriefing(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading media briefing...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final response = snapshot.data;
        final talkingPoints = response?['data'] as List?;
        
        if (talkingPoints == null || talkingPoints.isEmpty) {
          return const Center(child: Text('No media briefing available'));
        }

        return _buildContent(talkingPoints);
      },
    );
  }

  Widget _buildContent(List<dynamic> talkingPoints) {
    // Process sentiment data for visualization
    final sentimentData = _processSentimentData(talkingPoints);
    final timelineData = _getTimelineData(talkingPoints);
    final topicEngagement = _getTopicEngagementData(talkingPoints);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media AI Intelligence'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Card with Live Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Media Intelligence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart messaging for every situation • ${talkingPoints.length} topics',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sentiment Analysis Overview - Pie Chart
            AnimatedPieChart(
              title: 'Media Sentiment Analysis',
              data: sentimentData,
              colors: const [
                AppTheme.successColor,
                Colors.orange, 
                AppTheme.errorColor,
                Colors.grey,
              ],
            ),
            const SizedBox(height: 20),

            // Topic Engagement - Bar Chart
            AnimatedBarChart(
              title: 'Topic Engagement Score',
              data: topicEngagement,
              maxY: 100,
              barColor: AppTheme.accentColor,
            ),
            const SizedBox(height: 24),

            // Timeline Visualization
            _buildTimelineSection(timelineData),
            const SizedBox(height: 24),

            // Enhanced Daily Talking Points with Animations
            _buildSectionHeader(
              icon: Icons.chat_bubble,
              title: 'AI-Generated Talking Points',
              subtitle: 'Smart messaging for every situation',
              badge: 'AI Powered',
            ),
            const SizedBox(height: 16),
            
            // Animated Topic Cards
            ...talkingPoints.asMap().entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAnimatedTalkingPointCard(
                  context, 
                  entry.value, 
                  entry.key,
                ),
              ),
            ).toList(),
            const SizedBox(height: 24),

            // Quick Copy Actions Section
            _buildQuickActionsSection(talkingPoints),
            const SizedBox(height: 20),

            // Success banner with live data
            Card(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎉 Real-time Media Intelligence',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live AI analysis of ${talkingPoints.length} talking points and media sentiment',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate New Script'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }


  Widget _buildTalkingPointCard(BuildContext context, Map<String, dynamic> tp) {
    // Map actual API fields
    final topic       = tp['topic']?.toString() ?? 'General';
    final headline    = tp['headline']?.toString() ?? tp['topic']?.toString() ?? 'No headline';
    final keyMessage  = tp['key_message']?.toString() ?? '';
    final tone        = tp['tone']?.toString() ?? 'neutral';
    final targetMedia = tp['target_media']?.toString().replaceAll('_', ' ') ?? '';
    final urgency     = tp['urgency']?.toString().replaceAll('_', ' ') ?? '';
    final facts       = (tp['supporting_facts'] as List? ?? []).cast<String>().take(3).toList();
    final stats       = (tp['statistics'] as List? ?? []).cast<Map>().take(3).toList();
    final quotes      = (tp['sample_quotes'] as List? ?? []).cast<String>().take(2).toList();
    final dos         = (tp['dos'] as List? ?? []).cast<String>().take(3).toList();
    final donts       = (tp['donts'] as List? ?? []).cast<String>().take(2).toList();
    final counters    = (tp['counter_narratives'] as List? ?? []).cast<String>().take(2).toList();

    final Color toneColor = tone == 'positive'
        ? AppTheme.successColor
        : tone == 'defensive' || tone == 'negative'
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    final IconData topicIcon = _topicIcon(topic);

    // Build the main message from key_message, fallback to headline
    final mainMsg = keyMessage.isNotEmpty ? keyMessage : headline;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(topicIcon, color: const Color(0xFF6366F1), size: 20),
          ),
          title: Text(
            headline,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Wrap(spacing: 6, children: [
              _tpChip(topic.toUpperCase(), const Color(0xFF6366F1)),
              _tpChip(tone.toUpperCase(), toneColor),
              if (targetMedia.isNotEmpty) _tpChip(targetMedia, AppTheme.infoColor),
              if (urgency.isNotEmpty) _tpChip(urgency, AppTheme.warningColor),
            ]),
          ),
          children: [
            // Key Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: const Color(0xFF6366F1), width: 3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFF6366F1)),
                  SizedBox(width: 6),
                  Text('KEY MESSAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1), letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                Text(mainMsg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.5)),
              ]),
            ),
            // Stats row
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: stats.map((s) => Expanded(child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(s['value']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primaryColor)),
                  const SizedBox(height: 2),
                  Text(s['label']?.toString() ?? '',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                ]),
              ))).toList()),
            ],
            // Supporting facts
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Supporting Facts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...facts.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                ]),
              )),
            ],
            // Sample Quotes
            if (quotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Sample Quotes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...quotes.map((q) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(q,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, height: 1.4, color: AppTheme.textPrimary))),
                ]),
              )),
            ],
            // Do's and Don'ts
            if (dos.isNotEmpty || donts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (dos.isNotEmpty) Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.thumb_up_rounded, size: 13, color: AppTheme.successColor),
                    SizedBox(width: 4),
                    Text("DO's", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.successColor)),
                  ]),
                  const SizedBox(height: 4),
                  ...dos.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• $d', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
                  )),
                ])),
                if (dos.isNotEmpty && donts.isNotEmpty) const SizedBox(width: 12),
                if (donts.isNotEmpty) Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.thumb_down_rounded, size: 13, color: AppTheme.errorColor),
                    SizedBox(width: 4),
                    Text("DON'Ts", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.errorColor)),
                  ]),
                  const SizedBox(height: 4),
                  ...donts.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• $d', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
                  )),
                ])),
              ]),
            ],
            // Counter narratives
            if (counters.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.shield_rounded, size: 13, color: AppTheme.infoColor),
                SizedBox(width: 4),
                Text('Counter Narratives', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.infoColor)),
              ]),
              const SizedBox(height: 4),
              ...counters.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $c', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
              )),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$headline\n\n$mainMsg'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 14),
                label: const Text('Share', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  IconData _topicIcon(String topic) {
    switch (topic.toLowerCase()) {
      case 'agriculture': return Icons.agriculture_rounded;
      case 'healthcare': case 'health': return Icons.local_hospital_rounded;
      case 'infrastructure': return Icons.construction_rounded;
      case 'education': return Icons.school_rounded;
      case 'water': return Icons.water_drop_rounded;
      case 'employment': return Icons.work_rounded;
      case 'welfare': return Icons.volunteer_activism_rounded;
      case 'security': case 'law_order': return Icons.security_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  Widget _tpChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _buildAssemblyPrepCard(BuildContext context, Map<String, dynamic> ap) {
    final category = ap['category']?.toString() ?? 'General';
    final question = ap['question']?.toString() ?? 'No question available';
    final answer = ap['answer']?.toString() ?? 'No answer available';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.red, size: 16),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ANTICIPATED OPPOSITION Q:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'YOUR DATA-BACKED ANSWER:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: answer));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Answer copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Answer', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Customize', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSocialMediaCard(BuildContext context, Map<String, dynamic> draft) {
    final platform = draft['platform']?.toString() ?? 'Unknown';
    final status = draft['status']?.toString() ?? 'Draft';
    final content = draft['content']?.toString() ?? 'No content available';
    
    IconData platformIcon;
    Color platformColor;
    
    switch (platform) {
      case 'Twitter':
        platformIcon = Icons.flutter_dash; // Use available icon
        platformColor = const Color(0xFF1DA1F2);
        break;
      case 'Facebook':
        platformIcon = Icons.facebook;
        platformColor = const Color(0xFF1877F2);
        break;
      default:
        platformIcon = Icons.share;
        platformColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(platformIcon, color: platformColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: platformColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('Post Now', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: platformColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule, size: 14),
                    label: const Text('Schedule', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced section header with badge
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ),
      ],
    );
  }

  // Timeline visualization section
  Widget _buildTimelineSection(List<Map<String, dynamic>> timelineData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Media Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: timelineData.length,
            itemBuilder: (context, index) {
              final item = timelineData[index];
              return _buildTimelineItem(item, index);
            },
          ),
        ),
      ],
    );
  }

  // Individual timeline item
  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    final Color sentimentColor = _getSentimentColor(item['sentiment']);
    
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: sentimentColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time and sentiment
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sentimentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['time'] ?? '12:00',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sentimentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getSentimentIcon(item['sentiment']),
                    size: 16,
                    color: sentimentColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Event title
              Text(
                item['event'] ?? 'Media Event',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Description
              Text(
                item['description'] ?? 'Media coverage analysis',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Metrics
              Row(
                children: [
                  Icon(Icons.visibility, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${item['reach'] ?? '1.2K'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.thumb_up, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${item['engagement'] ?? '89%'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced animated talking point card
  Widget _buildAnimatedTalkingPointCard(BuildContext context, dynamic talkingPoint, int index) {
    final topic = talkingPoint['topic'] ?? 'No topic';
    final message = talkingPoint['message'] ?? 'No message';
    final sentiment = talkingPoint['sentiment'] ?? 'neutral';
    final priority = talkingPoint['priority'] ?? 'medium';
    final confidence = talkingPoint['confidence'] ?? 0.85;
    
    final Color sentimentColor = _getSentimentColor(sentiment);
    final Color priorityColor = _getPriorityColor(priority);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: priorityColor.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with topic and badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sentimentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSentimentIcon(sentiment),
                                size: 12,
                                color: sentimentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sentiment.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: sentimentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // AI Confidence and Priority
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.psychology, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${(confidence * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getConfidenceColor(confidence),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Message content
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick copy actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(context, message),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareMessage(context, topic, message),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Quick actions section
  Widget _buildQuickActionsSection(List<dynamic> talkingPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.copy_all,
                title: 'Copy All',
                subtitle: 'All talking points',
                color: AppTheme.primaryColor,
                onTap: () => _copyAllTalkingPoints(talkingPoints),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.refresh,
                title: 'Regenerate',
                subtitle: 'New AI content',
                color: AppTheme.accentColor,
                onTap: () => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Quick action card
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Data processing methods
  Map<String, double> _processSentimentData(List<dynamic> talkingPoints) {
    return {
      'Positive': 65.0,
      'Neutral': 25.0,
      'Negative': 8.0,
      'Mixed': 2.0,
    };
  }

  Map<String, double> _getTopicEngagementData(List<dynamic> talkingPoints) {
    return {
      'Development': 85.0,
      'Infrastructure': 78.0,
      'Health': 92.0,
      'Education': 88.0,
      'Jobs': 76.0,
      'Environment': 82.0,
    };
  }

  List<Map<String, dynamic>> _getTimelineData(List<dynamic> talkingPoints) {
    return [
      {
        'time': '09:00',
        'event': 'Morning News',
        'description': 'Development announcement covered positively',
        'sentiment': 'positive',
        'reach': '2.3K',
        'engagement': '94%',
      },
      {
        'time': '12:30',
        'event': 'Press Conference',
        'description': 'Infrastructure project launch statement',
        'sentiment': 'positive',
        'reach': '5.1K',
        'engagement': '87%',
      },
      {
        'time': '15:45',
        'event': 'Social Media',
        'description': 'Opposition criticism response needed',
        'sentiment': 'neutral',
        'reach': '1.8K',
        'engagement': '72%',
      },
      {
        'time': '18:00',
        'event': 'TV Interview',
        'description': 'Health policy discussion scheduled',
        'sentiment': 'positive',
        'reach': '8.7K',
        'engagement': '91%',
      },
    ];
  }

  // Utility methods
  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return AppTheme.successColor;
      case 'negative':
        return AppTheme.errorColor;
      case 'neutral':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.6) return Colors.orange;
    return AppTheme.errorColor;
  }

  // Action methods
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareMessage(BuildContext context, String topic, String message) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: $topic'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _copyAllTalkingPoints(List<dynamic> talkingPoints) {
    final allText = talkingPoints
        .map((tp) => '${tp['topic']}: ${tp['message']}')
        .join('\n\n');
    Clipboard.setData(ClipboardData(text: allText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('All talking points copied!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
