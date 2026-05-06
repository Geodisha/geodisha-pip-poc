import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/simple_auth_service.dart';
import '../../data/services/constituency_service.dart';
import '../../data/services/command_center_service.dart';
import '../../data/services/promises_service.dart';
import '../../data/services/alerts_crisis_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/gd_widgets.dart';
import 'command_center_screen.dart';
import 'ai_intelligence_hub_screen.dart';
import 'ground_reality_screen.dart';
import 'election_war_room_screen.dart';
import 'promise_tracker_screen.dart';
import 'alerts_center_screen.dart';
import 'todays_focus_screen.dart';
import 'auth/email_login_screen.dart';
import 'political_intelligence_screen.dart';
import 'constituency_pulse_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  final SimpleAuthService _authService = SimpleAuthService();
  late ConstituencyService _constituencyService;
  late CommandCenterService _commandCenterService;
  late PromisesService _promisesService;
  late AlertsCrisisService _alertsService;

  String? _selectedConstituency;
  UserRole? _userRole;
  Map<String, String?> _userProfile = {};
  List<Constituency> _constituencies = [];
  bool _loadingConstituencies = false;

  // Live KPI state
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _promisesKpi = {};
  List<dynamic> _recentAlerts = [];
  bool _kpiLoaded = false;

  static double _n(dynamic v, [double d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? d;
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return {};
  }

  static List<Map<String, dynamic>> _asList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => _asMap(e)).toList();
    return [];
  }

  @override
  void initState() {
    super.initState();
    _constituencyService = ConstituencyService(ApiService());
    _commandCenterService = CommandCenterService(ApiService());
    _promisesService = PromisesService(ApiService());
    _alertsService = AlertsCrisisService(ApiService());
    _loadUserProfile();
    _loadConstituencies();
    _loadKpiData();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    final role = await _authService.getUserRole();
    final constituency = await _authService.getSelectedConstituency();
    if (mounted) setState(() {
      _userProfile = profile;
      _userRole = role;
      _selectedConstituency = constituency;
    });
  }

  Future<void> _loadConstituencies() async {
    setState(() => _loadingConstituencies = true);
    try {
      final list = await _constituencyService.getAllConstituencies();
      if (mounted) setState(() {
        _constituencies = list;
        _loadingConstituencies = false;
        if (_selectedConstituency == null && list.isNotEmpty) {
          _selectedConstituency = list.first.id;
        } else if (_selectedConstituency != null && list.isNotEmpty) {
          final match = list.firstWhere(
            (c) => c.name == _selectedConstituency || c.id == _selectedConstituency,
            orElse: () => list.first,
          );
          _selectedConstituency = match.id;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingConstituencies = false);
    }
  }

  Future<void> _loadKpiData() async {
    try {
      final results = await Future.wait([
        _commandCenterService.getConstituencyOverview(constituencyId: _selectedConstituency),
        _promisesService.getPromiseCompletionRate(constituencyId: _selectedConstituency),
        _alertsService.getActiveAlerts(),
      ]);
      final overviewList  = _asList(results[0]['data']);
      final promisesData  = _asMap(results[1]['data']);
      final alertsList    = _asList(results[2]['data']);
      if (mounted) setState(() {
        _overview = overviewList.isNotEmpty ? overviewList[0] : {};
        _promisesKpi = promisesData;
        _recentAlerts = alertsList.take(5).toList();
        _kpiLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _kpiLoaded = true);
    }
  }

  Future<void> _changeConstituency(String? id) async {
    if (id == null) return;
    await _authService.setSelectedConstituency(id);
    setState(() { _selectedConstituency = id; _kpiLoaded = false; });
    _loadKpiData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const CommandCenterScreen(),
          
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
    ),
    child: SafeArea(
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.mediumGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Command'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Ground'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    ),
  );

  Widget _buildHomeTab() {
    // Build scrolling ticker messages from alerts
    final tickerMsgs = _recentAlerts.map((a) {
      final sev = a['severity']?.toString().toUpperCase() ?? 'ALERT';
      final title = a['title']?.toString() ?? '';
      final ward = a['location_ward']?.toString() ?? '';
      return '[$sev] $title${ward.isNotEmpty ? ' — $ward' : ''}';
    }).toList();

    if (tickerMsgs.isEmpty) tickerMsgs.addAll(['Loading alerts...', 'GeoDisha Political Intelligence Platform']);

    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverAppBar(
          expandedHeight: 230,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroHeader(),
          ),
          title: Row(children: [
            Image.asset('assets/logo.png', height: 28, errorBuilder: (_, __, ___) =>
                const Icon(Icons.shield, color: Colors.white, size: 26)),
            const SizedBox(width: 8),
            const Expanded(child: Text('GeoDisha Political Intelligence Platform', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsCenterScreen())),
                ),
                if (_recentAlerts.isNotEmpty)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => _showProfileSheet(context),
            ),
          ],
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async { setState(() => _kpiLoaded = false); await _loadKpiData(); },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Live ticker
            GDScrollingTicker(messages: tickerMsgs),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI row
                  if (!_kpiLoaded) ...[
                    Row(children: [
                      Expanded(child: GDShimmerBox(height: 100)),
                      const SizedBox(width: 12),
                      Expanded(child: GDShimmerBox(height: 100)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GDShimmerBox(height: 100)),
                      const SizedBox(width: 12),
                      Expanded(child: GDShimmerBox(height: 100)),
                    ]),
                  ] else ...[
                    Row(children: [
                      Expanded(child: GDStatCard(
                        title: 'Health Score', delay: 0,
                        value: '${_overview['health_score'] ?? '—'}',
                        subtitle: 'Constituency vitals',
                        icon: Icons.favorite_rounded, color: AppTheme.successColor,
                        trend: 2.4,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GDStatCard(
                        title: 'Satisfaction', delay: 100,
                        value: '${_overview['satisfaction_score'] ?? '—'}%',
                        subtitle: 'Voter satisfaction',
                        icon: Icons.sentiment_satisfied_rounded, color: AppTheme.accentColor,
                        trend: 1.2,
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: GDStatCard(
                        title: 'Promise Rate', delay: 150,
                        value: '${_promisesKpi['completion_rate'] ?? '—'}%',
                        subtitle: '${_promisesKpi['delayed'] ?? 0} delayed',
                        icon: Icons.task_alt_rounded, color: AppTheme.primaryColor,
                        trend: -1.8,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GDStatCard(
                        title: 'Active Issues', delay: 200,
                        value: '${_overview['active_issues'] ?? '—'}',
                        subtitle: '${_overview['critical_alerts'] ?? 0} critical',
                        icon: Icons.warning_amber_rounded, color: AppTheme.errorColor,
                      )),
                    ]),
                  ],
                  const SizedBox(height: 24),

                  // Today's focus CTA
                  FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaysFocusScreen())),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Today's Focus", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text('AI Nudges & Priority Actions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: const Text('Open', style: TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick access modules grid
                  GDSectionHeader(title: 'Modules', icon: Icons.grid_view_rounded),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _buildModules(),
                  ),
                  const SizedBox(height: 24),

                  // Recent alerts section
                  GDSectionHeader(
                    title: 'Recent Alerts',
                    icon: Icons.notifications_active_rounded,
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsCenterScreen())),
                  ),
                  const SizedBox(height: 12),
                  if (_recentAlerts.isEmpty && _kpiLoaded)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No active alerts', style: TextStyle(color: AppTheme.textSecondary)),
                    ))
                  else
                    ...(_recentAlerts.asMap().entries.map((e) => GDAlertCard(alert: _asMap(e.value), index: e.key))),

                  const SizedBox(height: 24),

                  // Promise progress
                  if (_kpiLoaded && _promisesKpi.isNotEmpty) ...[
                    GDSectionHeader(
                      title: 'Promise Tracker',
                      icon: Icons.flag_rounded,
                      actionLabel: 'Details',
                      onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromiseTrackerScreen())),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          children: [
                            GDProgressRow(
                              label: 'Completed',
                              value: _safeRate(_promisesKpi['completed'], _promisesKpi['total_promises']),
                              color: AppTheme.successColor,
                              valueLabel: '${_promisesKpi['completed'] ?? 0} / ${_promisesKpi['total_promises'] ?? 0}',
                            ),
                            GDProgressRow(
                              label: 'In Progress',
                              value: _safeRate(_promisesKpi['in_progress'], _promisesKpi['total_promises']),
                              color: AppTheme.infoColor,
                              valueLabel: '${_promisesKpi['in_progress'] ?? 0}',
                            ),
                            GDProgressRow(
                              label: 'Delayed',
                              value: _safeRate(_promisesKpi['delayed'], _promisesKpi['total_promises']),
                              color: AppTheme.errorColor,
                              valueLabel: '${_promisesKpi['delayed'] ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _safeRate(dynamic part, dynamic total) {
    final p = (part is num ? part : double.tryParse(part?.toString() ?? '') ?? 0).toDouble();
    final t = (total is num ? total : double.tryParse(total?.toString() ?? '') ?? 0).toDouble();
    return t > 0 ? (p / t).clamp(0.0, 1.0) : 0;
  }

  Widget _buildHeroHeader() {
    final health = _n(_overview['health_score']);
    final satisfaction = _n(_overview['satisfaction_score']);
    final constituency = _overview['constituency_name']?.toString() ?? _selectedConstituency ?? '—';
    final riskLevel = (_overview['risk_level'] ?? 'medium').toString().toUpperCase();
    final riskColor = riskLevel == 'LOW' ? AppTheme.successColor
        : riskLevel == 'HIGH' ? AppTheme.errorColor : AppTheme.warningColor;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050D1A), Color(0xFF0A1628), Color(0xFF0F2554), Color(0xFF162B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(top: -30, right: -30, child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF4F46E5).withValues(alpha: 0.25),
                Colors.transparent,
              ]),
            ),
          )),
          Positioned(bottom: -20, left: -20, child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF059669).withValues(alpha: 0.2),
                Colors.transparent,
              ]),
            ),
          )),
          Positioned(top: 80, left: 160, child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          )),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Greeting row
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.accentLight.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                      ),
                      child: Text('RISK: $riskLevel', style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Welcome text
                  Text(
                    'Welcome, ${_userProfile['name'] ?? 'Commander'}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  // Constituency selector
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF818CF8), size: 13),
                    const SizedBox(width: 3),
                    if (_loadingConstituencies)
                      const Text('Loading...', style: TextStyle(color: Colors.white54, fontSize: 12))
                    else if (_userRole == UserRole.admin && _constituencies.isNotEmpty)
                      _buildConstituencyDropdown()
                    else
                      Text(constituency, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  // KPI glass pills row
                  if (_kpiLoaded) Row(children: [
                    _heroPill(Icons.favorite_rounded, '${health.toStringAsFixed(0)}', 'Health', AppTheme.successColor),
                    const SizedBox(width: 8),
                    _heroPill(Icons.sentiment_satisfied_alt_rounded, '${satisfaction.toStringAsFixed(0)}%', 'Satisfied', AppTheme.infoColor),
                    const SizedBox(width: 8),
                    _heroPill(Icons.warning_amber_rounded, '${_n(_overview['active_issues']).toInt()}', 'Issues', AppTheme.warningColor),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, height: 1.1)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500)),
        ])),
      ]),
    ),
  );

  Widget _buildConstituencyDropdown() => DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: _constituencies.any((c) => c.id == _selectedConstituency) ? _selectedConstituency : null,
      dropdownColor: AppTheme.primaryColor,
      iconEnabledColor: Colors.white60,
      isDense: true,
      hint: const Text('Select constituency', style: TextStyle(color: Colors.white60, fontSize: 13)),
      items: _constituencies.map((c) => DropdownMenuItem(
        value: c.id,
        child: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
      )).toList(),
      onChanged: _changeConstituency,
    ),
  );

  List<Widget> _buildModules() {
    final mods = [
      ('Command\nCenter',     Icons.dashboard_customize_rounded,      AppTheme.primaryGradient,                                                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandCenterScreen())),     null),
      ('AI Intel\nHub',       Icons.psychology_rounded,                AppTheme.accentGradient,                                                                   () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIIntelligenceHubScreen())), null),
      ('Ground\nReality',     Icons.map_rounded,                       AppTheme.successGradient,                                                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroundRealityScreen())),      null),
      ('Election\nWar Room',  Icons.how_to_vote_rounded,               AppTheme.infoGradient,                                                                     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectionWarRoomScreen())),   null),
      ('Promise\nTracker',    Icons.task_alt_rounded,                  AppTheme.warningGradient,                                                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromiseTrackerScreen())),    null),
      ('Alerts &\nCrisis',    Icons.notification_important_rounded,    AppTheme.errorGradient,                                                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsCenterScreen())),      _recentAlerts.length),
      ('Political\nIntel',    Icons.how_to_vote_outlined,              const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)], begin: Alignment.topLeft, end: Alignment.bottomRight), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliticalIntelligenceScreen())), null),
      ('Constituency\nPulse', Icons.monitor_heart_rounded,             const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF134E4A)], begin: Alignment.topLeft, end: Alignment.bottomRight), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConstituencyPulseScreen())),    null),
    ];
    return mods.asMap().entries.map((e) {
      final i = e.key;
      final m = e.value;
      return GDModuleCard(
        title: m.$1, icon: m.$2, gradient: m.$3, onTap: m.$4,
        badge: m.$5 != null && m.$5! > 0 ? m.$5 : null,
        delay: i * 60,
      );
    }).toList();
  }

  Widget _buildSettingsTab() => Scaffold(
    appBar: AppBar(title: const Text('Profile & Settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Card
        FadeInDown(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                child: Center(child: Text(
                  (_userProfile['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_userProfile['name'] ?? 'User', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(_getRoleDisplay(_userRole), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              GDStatusBadge(label: 'Active', color: AppTheme.successColor),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _settingsTile('Notifications', Icons.notifications_outlined, AppTheme.accentColor, () {}),
        _settingsTile('Privacy & Security', Icons.lock_outline, AppTheme.primaryColor, () {}),
        _settingsTile('App Preferences', Icons.tune_rounded, AppTheme.successColor, () {}),
        _settingsTile('Help & Support', Icons.help_outline_rounded, AppTheme.warningColor, () {}),
        _settingsTile('About GeoDisha', Icons.info_outline_rounded, AppTheme.infoColor, () {}),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );

  Widget _settingsTile(String title, IconData icon, Color color, VoidCallback onTap) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.mediumGrey),
        onTap: onTap,
      ),
    );

  void _showProfileSheet(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 64, height: 64,
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(
              (_userProfile['name'] ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            )),
          ),
          const SizedBox(height: 12),
          Text(_userProfile['name'] ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          GDStatusBadge(label: _getRoleDisplay(_userRole)),
          const SizedBox(height: 20),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _handleLogout(context); },
          ),
        ],
      ),
    ),
  );

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await SimpleAuthService().logout();
      if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const EmailLoginScreen()), (_) => false);
    }
  }

  String _getRoleDisplay(UserRole? role) {
    switch (role) {
      case UserRole.admin: return 'System Administrator';
      case UserRole.mpMla: return 'MP / MLA';
      case UserRole.minister: return 'Minister';
      case UserRole.volunteer: return 'Volunteer';
      default: return 'User';
    }
  }
}
