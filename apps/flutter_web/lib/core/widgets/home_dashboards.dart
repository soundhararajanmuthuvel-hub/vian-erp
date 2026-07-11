import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'custom_widgets.dart';

// ==========================================
// 1. ANAND HOME VIEW (Managing Director / Super Admin)
// ==========================================
class ExecutiveDashboardView extends StatefulWidget {
  const ExecutiveDashboardView({Key? key}) : super(key: key);

  @override
  State<ExecutiveDashboardView> createState() => _ExecutiveDashboardViewState();
}

class _ExecutiveDashboardViewState extends State<ExecutiveDashboardView> {
  Map<String, dynamic>? _execStats;
  List<dynamic> _fines = [];
  List<dynamic> _warnings = [];
  List<dynamic> _announcements = [];
  List<dynamic> _logs = [];
  List<dynamic> _projects = [];
  List<dynamic> _employees = [];
  Map<String, dynamic>? _analytics;
  List<dynamic> _targetAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final stats = await ApiService.getExecutiveStats();
    final finesData = await ApiService.getFines();
    final anns = await ApiService.getAnnouncements();
    final logData = await ApiService.getImportLogs();
    final projs = await ApiService.getProjects();
    final emps = await ApiService.getEmployees();
    final analytics = await ApiService.getExecutiveAnalytics();
    final targetAlerts = await ApiService.getTargetAlerts();

    if (mounted) {
      setState(() {
        _execStats = stats;
        _fines = finesData['fines'] ?? [];
        _warnings = finesData['warnings'] ?? [];
        _announcements = anns;
        _logs = logData;
        _projects = projs;
        _employees = emps;
        _analytics = analytics;
        _targetAlerts = targetAlerts;
        _loading = false;
      });
    }
  }

  void _showApplyFineDialog(Map<String, dynamic> warning) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Geofence Breach: Left assigned site boundary');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('APPLY GEOFENCE FINE', style: TextStyle(color: VianTheme.danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Employee: ${warning['user']?['name'] ?? 'Employee'}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Project: ${warning['project']?['name'] ?? 'Project'}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Fine Amount (INR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Apply Fine',
            color: VianTheme.danger,
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt > 0) {
                await ApiService.applyFine(warning['id'], warning['userId'] ?? 1, amt, reasonCtrl.text);
                Navigator.pop(context);
                setState(() => _loading = true);
                _loadAllData();
              }
            },
          )
        ],
      ),
    );
  }

  void _showPublishAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String type = 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('PUBLISH COMPANY ANNOUNCEMENT', style: TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Urgent', 'Holiday', 'Meeting', 'Safety'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message Body')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Publish',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && messageCtrl.text.isNotEmpty) {
                await ApiService.addAnnouncement({
                  'title': titleCtrl.text,
                  'message': messageCtrl.text,
                  'targetRole': 'All',
                  'type': type
                });
                Navigator.pop(context);
                setState(() => _loading = true);
                _loadAllData();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final curPerf = _analytics?['currentPerformance'] ?? {};
    final targets = _analytics?['targets'] ?? {};
    final forecasts = _analytics?['forecasts'] ?? {};
    final scoreData = _analytics?['scorecard'] ?? {};
    final depts = _analytics?['departments'] ?? {};
    
    final turnoverActual = safeToDouble(curPerf['actualTurnover']);
    final turnoverTarget = safeToDouble(targets['annualRevenueTarget'] ?? 10000000.0);
    
    final profitActual = safeToDouble(curPerf['netProfit']);
    final profitTarget = safeToDouble(targets['annualProfitTarget'] ?? 3000000.0);

    final projectsActual = safeToDouble(curPerf['projectsCompleted']);
    final projectsTarget = safeToDouble(targets['annualProjectTarget'] ?? 120.0);

    final clientsActual = safeToDouble((curPerf['newClients'] ?? 0) + (curPerf['repeatClients'] ?? 0));
    final clientsTarget = safeToDouble((targets['newClientTarget'] ?? 15) + (targets['repeatClientTarget'] ?? 5));

    final monthlyRevenueData = List<double>.from((_analytics?['monthlyRevenue'] ?? []).map((e) => safeToDouble(e)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXECUTIVE BUSINESS COMMAND OVERVIEW',
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: VianTheme.primaryGold,
                      letterSpacing: 1.0
                    )
                  ),
                  const Text('Managing Director Command Panel (Anand)', style: TextStyle(color: VianTheme.lightText)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: VianTheme.primaryGold), 
                onPressed: () => setState(() { _loading = true; _loadAllData(); })
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_targetAlerts.isNotEmpty) ...[
            Column(
              children: _targetAlerts.map<Widget>((alert) {
                final isHigh = alert['severity'] == 'High';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isHigh ? const Color(0x22DC3545) : const Color(0x22F5A623),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isHigh ? VianTheme.danger : VianTheme.primaryGold, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isHigh ? Icons.error_outline : Icons.warning_amber_rounded,
                        color: isHigh ? VianTheme.danger : VianTheme.primaryGold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${alert['title']} (${alert['type']})', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: isHigh ? VianTheme.danger : VianTheme.primaryGold,
                                fontSize: 13
                              )
                            ),
                            Text(alert['message'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const Text('ANNUAL TARGETS ACHIEVEMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 600 ? 2 : 4;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 0.85,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  TargetProgressIndicator(
                    title: 'ANNUAL TURNOVER',
                    actual: turnoverActual,
                    target: turnoverTarget,
                    label: currencyFormatter.format(turnoverActual),
                  ),
                  TargetProgressIndicator(
                    title: 'ANNUAL NET PROFIT',
                    actual: profitActual,
                    target: profitTarget,
                    label: currencyFormatter.format(profitActual),
                  ),
                  TargetProgressIndicator(
                    title: 'COMPLETED PROJECTS',
                    actual: projectsActual,
                    target: projectsTarget,
                    label: '${projectsActual.toInt()} / ${projectsTarget.toInt()} Projects',
                  ),
                  TargetProgressIndicator(
                    title: 'CLIENT GROWTH',
                    actual: clientsActual,
                    target: clientsTarget,
                    label: '${clientsActual.toInt()} Clients',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('REVENUE COLLECTION TREND (FY)', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                              Text('Apr 2026 - Mar 2027', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          RevenueTrendChart(data: monthlyRevenueData),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DEPARTMENT PERFORMANCE METRICS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 16),
                          _buildDeptProgressRow('Design Team', 'Drawing Completion Rate', safeToDouble(depts['design']?['completionRate'] ?? 84.0)),
                          const SizedBox(height: 12),
                          _buildDeptProgressRow('Site Team', 'Average Attendance Rate', safeToDouble(depts['site']?['attendanceRate'] ?? 92.0)),
                          const SizedBox(height: 12),
                          _buildDeptProgressRow('Accounts Team', 'Collection Efficiency Rate', safeToDouble(depts['accounts']?['collectionEfficiency'] ?? 72.0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GPS ATTENDANCE & GEOFENCE VIOLATIONS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.danger)),
                          const SizedBox(height: 12),
                          if (_warnings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: Text('No active geofence breaches detected today.', style: TextStyle(color: VianTheme.lightText))),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _warnings.length,
                              itemBuilder: (context, idx) {
                                final warn = _warnings[idx];
                                return ListTile(
                                  leading: const CircleAvatar(backgroundColor: Color(0x33DC3545), child: Icon(Icons.gps_off, color: VianTheme.danger)),
                                  title: Text('${warn['user']?['name'] ?? 'Employee'} left designated boundary'),
                                  subtitle: Text('Project: ${warn['project']?['name']} | Duration: ${warn['durationOutside']} mins | Location: ${warn['currentLocation']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.gavel, color: VianTheme.danger),
                                        tooltip: 'Apply Fine',
                                        onPressed: () => _showApplyFineDialog(warn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check, color: VianTheme.success),
                                        tooltip: 'Ignore Warning',
                                        onPressed: () async {
                                          await ApiService.updateWarningStatus(warn['id'], 'Ignored');
                                          setState(() => _loading = true);
                                          _loadAllData();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YEAR-END FORECAST ENGINE', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 16),
                          _buildForecastRow('Expected Revenue', currencyFormatter.format(safeToDouble(forecasts['projectedYearEndRevenue'] ?? 12000000))),
                          _buildForecastRow('Expected Profit', currencyFormatter.format(safeToDouble(forecasts['projectedYearEndProfit'] ?? 3600000))),
                          _buildForecastRow('Expected Projects', '${forecasts['projectedYearEndProjects'] ?? 108} projects'),
                          const Divider(color: Color(0xFF2E2E3E), height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Projections Status:', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                              Text('ON TARGET', style: TextStyle(color: VianTheme.success, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('BUSINESS HEALTH SCORECARD', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: VianTheme.primaryGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: VianTheme.primaryGold, width: 1),
                                ),
                                child: Text(
                                  '${_analytics?['financialHealthScore'] ?? 78} / 100', 
                                  style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                              )
                            ],
                          ),
                          _buildScoreItem('Financial Health', safeToDouble(scoreData['financial'] ?? 70)),
                          _buildScoreItem('Projects Delivery', safeToDouble(scoreData['projects'] ?? 68)),
                          _buildScoreItem('Operations Efficiency', safeToDouble(scoreData['operations'] ?? 82)),
                          _buildScoreItem('Client Relations', safeToDouble(scoreData['clients'] ?? 72)),
                          _buildScoreItem('Employee Health', safeToDouble(scoreData['employees'] ?? 88)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('COMPANY ANNOUNCEMENTS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                              IconButton(
                                icon: const Icon(Icons.add_comment_outlined, color: VianTheme.primaryGold, size: 20),
                                onPressed: _showPublishAnnouncementDialog,
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length > 3 ? 3 : _announcements.length,
                            itemBuilder: (context, idx) {
                              final ann = _announcements[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(ann['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ann['type'] == 'Urgent' ? const Color(0x33DC3545) : const Color(0x33F5A623), 
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Text(
                                            ann['type'] ?? 'General', 
                                            style: TextStyle(
                                              color: ann['type'] == 'Urgent' ? VianTheme.danger : VianTheme.primaryGold, 
                                              fontSize: 9
                                            )
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(ann['message'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptProgressRow(String teamName, String metric, double rate) {
    final color = rate >= 80 ? VianTheme.success : VianTheme.primaryGold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(metric, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 3.5,
                  backgroundColor: const Color(0xFF2E2E3E),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${rate.toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score) {
    final color = score > 85 ? VianTheme.success : VianTheme.primaryGold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 3.5,
                  backgroundColor: const Color(0xFF23232E),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${score.toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TargetProgressIndicator extends StatelessWidget {
  final String title;
  final double actual;
  final double target;
  final String label;

  const TargetProgressIndicator({
    Key? key,
    required this.title,
    required this.actual,
    required this.target,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double pct = target > 0 ? (actual / target) : 0.0;
    final int pctInt = (pct * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VianTheme.headerBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VianTheme.primaryGold.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: VianTheme.lightText,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: pct > 1.0 ? 1.0 : pct,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF2E2E3E),
                  valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                ),
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${NumberFormat.compact().format(target)}',
            style: const TextStyle(
              fontSize: 10,
              color: VianTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class RevenueTrendChart extends StatelessWidget {
  final List<double> data;

  const RevenueTrendChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No revenue data available', style: TextStyle(color: VianTheme.lightText)),
        ),
      );
    }

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double maxInterval = maxVal > 0 ? maxVal : 10.0;

    final List<String> months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i],
              gradient: const LinearGradient(
                colors: [VianTheme.primaryGold, Color(0xFFE5A93B)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxInterval * 1.15,
                color: const Color(0xFF1E1E26),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Color(0xFF262635),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(color: VianTheme.lightText, fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        months[idx],
                        style: const TextStyle(color: VianTheme.lightText, fontSize: 9),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: barGroups,
          maxY: maxInterval * 1.15,
        ),
      ),
    );
  }
}


// ==========================================
// 2. JAYA HOME VIEW (Admin / Office Manager / Accounts)
// ==========================================
class JayaHomeView extends StatefulWidget {
  const JayaHomeView({Key? key}) : super(key: key);

  @override
  State<JayaHomeView> createState() => _JayaHomeViewState();
}

class _JayaHomeViewState extends State<JayaHomeView> {
  bool _loading = true;
  List<dynamic> _attendance = [];
  List<dynamic> _clients = [];
  List<dynamic> _invoices = [];
  List<dynamic> _announcements = [];
  List<dynamic> _tasks = [];
  int _pendingPayments = 0;

  // New projects and employees for Work Assignment
  List<dynamic> _projects = [];
  List<dynamic> _employees = [];

  // Work Assignment Form State
  int? _assignProjectId;
  String? _assignChecklist;
  String? _assignDrawing;
  int? _assignUserId;
  String _assignPriority = 'Medium';
  final _assignDueDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ').first);
  final _assignTimeCtrl = TextEditingController(text: '05:00 PM');
  final _assignNotesCtrl = TextEditingController();

  final List<String> _checklistItems = [
    'Site Boundary', 'Column Marking', 'Footing', 'Grade Beam', 'Plinth',
    'Ground Floor', 'First Floor', 'Roof', 'Brick Work', 'Electrical',
    'Plumbing', 'Painting', 'Wood Work', 'False Ceiling', 'Flooring',
    'Finishing', 'Handover'
  ];

  final List<String> _drawingItems = [
    'Working Drawing', 'Floor Plan', 'Section', 'Elevation', 'Compound Wall',
    'Gate Design', 'Electrical', 'Plumbing', '3D Interior', '3D Exterior'
  ];

  @override
  void initState() {
    super.initState();
    _loadJayaData();
  }

  Future<void> _loadJayaData() async {
    final att = await ApiService.getAttendance();
    final cli = await ApiService.getClients();
    final inv = await ApiService.getInvoices();
    final anns = await ApiService.getAnnouncements();
    final tsk = await ApiService.getTasks();
    final projs = await ApiService.getProjects();
    final emps = await ApiService.getEmployees();

    if (mounted) {
      setState(() {
        _attendance = att;
        _clients = cli;
        _invoices = inv;
        _announcements = anns;
        _tasks = tsk;
        _projects = projs;
        _employees = emps.where((e) => e['role'] != 'Client' && e['role'] != 'Managing Director').toList();
        _pendingPayments = inv.where((i) => i['status'] != 'Paid').length;
        _loading = false;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_assignProjectId == null || _assignUserId == null || _assignChecklist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Project, Staff, and Working Checklist Item.'))
      );
      return;
    }
    
    final selectedProj = _projects.firstWhere((p) => p['id'] == _assignProjectId);
    final selectedClient = _clients.firstWhere((c) => c['id'] == selectedProj['clientId'], orElse: () => {'name': 'Client'});
    
    final descriptionObj = {
      'clientName': selectedClient['name'] ?? 'Client',
      'projectName': selectedProj['name'] ?? 'Project',
      'checklist': _assignChecklist,
      'drawing': _assignDrawing ?? 'None',
      'expectedCompletion': _assignTimeCtrl.text,
      'notes': _assignNotesCtrl.text.isEmpty ? 'Daily Work Assignment' : _assignNotesCtrl.text
    };

    final success = await ApiService.createTask({
      'title': 'Daily Work: $_assignChecklist',
      'description': jsonEncode(descriptionObj),
      'projectId': _assignProjectId,
      'assignedTo': _assignUserId,
      'priority': _assignPriority,
      'dueDate': _assignDueDateCtrl.text,
      'status': 'Pending'
    });

    if (success) {
      _assignNotesCtrl.clear();
      setState(() {
        _assignChecklist = null;
        _assignDrawing = null;
      });
      _loadJayaData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work assignment successfully saved and dispatched to Staff.'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save work assignment.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Office Administration Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Jaya Home Screen: Clients, Accounts, Tasks & Operations', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 600 ? 1 : 4;
              return GridView.count(
                crossAxisCount: cols,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  VianMetricCard(title: 'TOTAL CLIENTS', value: _clients.length.toString(), icon: Icons.people),
                  VianMetricCard(title: "TODAY'S ATTENDANCE", value: _attendance.length.toString(), icon: Icons.calendar_month, iconColor: VianTheme.success),
                  VianMetricCard(title: 'UNPAID INVOICES', value: _pendingPayments.toString(), icon: Icons.receipt, iconColor: VianTheme.danger),
                  VianMetricCard(title: 'TOTAL REVENUE INVOICED', value: formatter.format(_invoices.fold(0.0, (acc, item) => acc + safeToDouble(item['total']))), icon: Icons.payments, iconColor: VianTheme.primaryGold),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CLIENT METADATA DIRECTORY', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                              VianButton(text: 'Onboard Wizard', onPressed: () {}, isSecondary: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _clients.length > 3 ? 3 : _clients.length,
                            itemBuilder: (context, idx) {
                              final cli = _clients[idx];
                              return ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFF1E1E26), child: Icon(Icons.person, color: VianTheme.primaryGold)),
                                title: Text(cli['name'] ?? ''),
                                subtitle: Text('Phone: ${cli['phone']} | Email: ${cli['email']}'),
                                trailing: Text(cli['gst'] != null ? 'GST: ${cli['gst']}' : 'No GST', style: const TextStyle(fontSize: 10, color: VianTheme.lightText)),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RECENT INVOICES & PAYMENTS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invoices.length > 3 ? 3 : _invoices.length,
                            itemBuilder: (context, idx) {
                              final inv = _invoices[idx];
                              final isPaid = inv['status'] == 'Paid';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Invoice #${inv['invoiceNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Total: ${formatter.format(safeToDouble(inv['total']))}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isPaid ? const Color(0x3328A745) : const Color(0x33DC3545), borderRadius: BorderRadius.circular(4)),
                                      child: Text(inv['status'] ?? 'Draft', style: TextStyle(color: isPaid ? VianTheme.success : VianTheme.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildDailyAssignmentForm(),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ASSIGNED OFFICE TASKS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length > 4 ? 4 : _tasks.length,
                            itemBuilder: (context, idx) {
                              final task = _tasks[idx];
                              return Card(
                                color: const Color(0xFF1E1E26),
                                child: ListTile(
                                  dense: true,
                                  title: Text(task['title'] ?? ''),
                                  subtitle: Text('Due: ${task['dueDate']} | Assignee: ${task['assignee']?['name'] ?? 'Unassigned'}', style: const TextStyle(fontSize: 10)),
                                  trailing: Icon(task['status'] == 'Completed' ? Icons.check_circle : Icons.circle_outlined, color: task['status'] == 'Completed' ? VianTheme.success : VianTheme.primaryGold, size: 16),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RECENT ANNOUNCEMENTS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length > 3 ? 3 : _announcements.length,
                            itemBuilder: (context, idx) {
                              final ann = _announcements[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ann['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(ann['message'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDailyAssignmentForm() {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY WORK ASSIGNMENT DISPATCHER', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 0.8)),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            value: _assignProjectId,
            dropdownColor: VianTheme.headerBlack,
            decoration: const InputDecoration(labelText: 'Select Project & Client'),
            items: _projects.map((p) {
              return DropdownMenuItem<dynamic>(
                value: p['id'],
                child: Text('${p['name']} (Client ID: ${p['clientId']})', style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _assignProjectId = val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _assignChecklist,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Working Checklist Item'),
                  items: _checklistItems.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _assignChecklist = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _assignDrawing,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Drawing Reference (Optional)'),
                  items: _drawingItems.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _assignDrawing = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<dynamic>(
                  value: _assignUserId,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Assign Staff / Engineer'),
                  items: _employees.map((e) {
                    return DropdownMenuItem<dynamic>(
                      value: e['id'],
                      child: Text('${e['name']} (${e['role']})', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _assignUserId = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _assignPriority,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Priority Level'),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((p) {
                    return DropdownMenuItem<String>(
                      value: p,
                      child: Text(p, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _assignPriority = val!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _assignDueDateCtrl,
                  decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _assignTimeCtrl,
                  decoration: const InputDecoration(labelText: 'Expected Completion Time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _assignNotesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Task Instructions / Remarks'),
          ),
          const SizedBox(height: 16),
          Center(
            child: VianButton(
              text: 'Dispatch Today\'s Task',
              icon: Icons.send_rounded,
              onPressed: _submitAssignment,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. MUTHUIYA HOME VIEW (Tech Head + Senior Architect)
// ==========================================
class MuthuiyaHomeView extends StatefulWidget {
  const MuthuiyaHomeView({Key? key}) : super(key: key);

  @override
  State<MuthuiyaHomeView> createState() => _MuthuiyaHomeViewState();
}

class _MuthuiyaHomeViewState extends State<MuthuiyaHomeView> {
  bool _loading = true;
  List<dynamic> _tasks = [];
  List<dynamic> _drawings = [];
  List<dynamic> _announcements = [];
  List<dynamic> _employees = [];
  List<dynamic> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadMuthuiyaData();
  }

  Future<void> _loadMuthuiyaData() async {
    final tsk = await ApiService.getTasks();
    final anns = await ApiService.getAnnouncements();
    final emps = await ApiService.getEmployees();
    final projs = await ApiService.getProjects();

    List<dynamic> drawList = [];
    if (projs.isNotEmpty) {
      final draws = await ApiService.getDrawings(projs.first['id']);
      drawList = draws;
    }

    if (mounted) {
      setState(() {
        _tasks = tsk;
        _drawings = drawList;
        _announcements = anns;
        _employees = emps;
        _projects = projs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final designTeam = _employees.where((e) => e['username'] == 'gokul' || e['username'] == 'sivaraman').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Design & Architecture Command Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Muthuiya Home Screen: Design Review, Blueprints, Team Attendance', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 600 ? 1 : 3;
              return GridView.count(
                crossAxisCount: cols,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  VianMetricCard(title: 'PENDING DRAWINGS APPROVAL', value: _drawings.where((d) => d['status'] == 'Pending').length.toString(), icon: Icons.layers, iconColor: VianTheme.primaryGold),
                  VianMetricCard(title: 'DESIGN TEAM SIZE', value: designTeam.length.toString(), icon: Icons.people),
                  VianMetricCard(title: 'ACTIVE PROJECTS', value: _projects.length.toString(), icon: Icons.architecture, iconColor: VianTheme.success),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DRAWINGS APPROVAL QUEUE', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          if (_drawings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: Text('No drawings uploaded yet.', style: TextStyle(color: VianTheme.lightText))),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _drawings.length,
                              itemBuilder: (context, idx) {
                                final d = _drawings[idx];
                                return Card(
                                  color: const Color(0xFF1E1E26),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.picture_as_pdf, color: VianTheme.primaryGold),
                                    title: Text(d['title'] ?? ''),
                                    subtitle: Text('Type: ${d['type']} | Version: ${d['version']} | Status: ${d['status']}'),
                                    trailing: d['status'] == 'Pending'
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check, color: VianTheme.success),
                                                onPressed: () async {
                                                  await ApiService.approveDrawing(d['id'], 'Approved');
                                                  setState(() => _loading = true);
                                                  _loadMuthuiyaData();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: VianTheme.danger),
                                                onPressed: () async {
                                                  await ApiService.approveDrawing(d['id'], 'Rejected');
                                                  setState(() => _loading = true);
                                                  _loadMuthuiyaData();
                                                },
                                              ),
                                            ],
                                          )
                                        : Text(d['status'] ?? '', style: TextStyle(color: d['status'] == 'Approved' ? VianTheme.success : VianTheme.danger, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DESIGN TEAM ATTENDANCE STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: designTeam.length,
                            itemBuilder: (context, idx) {
                              final member = designTeam[idx];
                              return ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFF1E1E26), child: Icon(Icons.person, color: VianTheme.primaryGold)),
                                title: Text(member['name'] ?? ''),
                                subtitle: Text('Role: ${member['role']}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0x3328A745), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Checked In', style: TextStyle(color: VianTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DESIGN & CREATIVE TASKS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length > 3 ? 3 : _tasks.length,
                            itemBuilder: (context, idx) {
                              final task = _tasks[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task['title'] ?? ''),
                                    const SizedBox(height: 4),
                                    Text('Assignee: ${task['assignee']?['name'] ?? 'Unassigned'} | Due: ${task['dueDate']}', style: const TextStyle(fontSize: 10, color: VianTheme.lightText)),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROJECT PROGRESS METRICS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _projects.length,
                            itemBuilder: (context, idx) {
                              final proj = _projects[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(proj['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text('${proj['progressPercentage']}%', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: (proj['progressPercentage'] ?? 0) / 100.0,
                                      backgroundColor: const Color(0xFF1E1E26),
                                      valueColor: const AlwaysStoppedAnimation(VianTheme.primaryGold),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. SITE MANAGER DASHBOARD VIEW (Murugan Home)
// ==========================================
class SiteManagerDashboardView extends StatefulWidget {
  const SiteManagerDashboardView({Key? key}) : super(key: key);

  @override
  State<SiteManagerDashboardView> createState() => _SiteManagerDashboardViewState();
}

class _SiteManagerDashboardViewState extends State<SiteManagerDashboardView> {
  bool _loading = true;
  List<dynamic> _workers = [];
  List<dynamic> _attendance = [];
  List<dynamic> _projects = [];
  List<dynamic> _hourlyProgressList = [];
  
  final Map<int, String> _workerStatus = {};
  final Map<int, String> _workerRemarks = {};
  final Map<int, double> _workerOt = {};
  
  int? _selectedProjectId;
  final _hourlyProgressCtrl = TextEditingController();
  final _hourlyRemarksCtrl = TextEditingController();
  final _hourlyWorkersCtrl = TextEditingController(text: '8');
  final _hourlyPercentageCtrl = TextEditingController(text: '30');
  final _hourlyMaterialsCtrl = TextEditingController();
  final _hourlyDelayCtrl = TextEditingController();
  final _hourlyWeatherCtrl = TextEditingController(text: 'Sunny');

  @override
  void initState() {
    super.initState();
    _loadMuruganData();
  }

  Future<void> _loadMuruganData() async {
    final projs = await ApiService.getProjects();
    _projects = projs;
    if (_projects.isNotEmpty) {
      _selectedProjectId = _projects.first['id'];
      final res = await ApiService.getWorkersAttendance(_selectedProjectId!);
      _workers = res['workers'] ?? [];
      _attendance = res['attendance'] ?? [];
      
      for (final w in _workers) {
        _workerStatus[w['id']] = 'Present';
        _workerRemarks[w['id']] = 'Standard shift';
        _workerOt[w['id']] = 0.0;
      }
      
      final progressData = await ApiService.getHourlyProgress(_selectedProjectId!);
      _hourlyProgressList = progressData;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _submitManualAttendance() async {
    final List<Map<String, dynamic>> submitList = [];
    _workerStatus.forEach((key, status) {
      final worker = _workers.firstWhere((w) => w['id'] == key);
      submitList.add({
        'workerId': worker['workerId'],
        'status': status,
        'overtimeHours': _workerOt[key] ?? 0.0,
        'remarks': _workerRemarks[key] ?? ''
      });
    });

    final res = await ApiService.submitLabourAttendance(submitList, '28.4595, 77.0266', DateTime.now().toString().split(' ').first);
    if (!res['success'] && res['message'] != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('ATTENDANCE RECORDED', style: TextStyle(color: VianTheme.danger)),
          content: Text(res['message'] ?? 'Attendance already recorded for today.'),
          actions: [
            VianButton(text: 'Close', isSecondary: true, onPressed: () => Navigator.pop(context))
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance recorded successfully!')));
      setState(() => _loading = true);
      _loadMuruganData();
    }
  }

  void _submitHourlyProgressReport() async {
    if (_hourlyProgressCtrl.text.isEmpty || _selectedProjectId == null) return;
    
    final data = {
      'projectId': _selectedProjectId,
      'workProgress': _hourlyProgressCtrl.text,
      'remarks': _hourlyRemarksCtrl.text,
      'completionPercentage': int.tryParse(_hourlyPercentageCtrl.text) ?? 0,
      'workersPresent': int.tryParse(_hourlyWorkersCtrl.text) ?? 0,
      'materialsUsed': _hourlyMaterialsCtrl.text,
      'delayReason': _hourlyDelayCtrl.text,
      'weather': _hourlyWeatherCtrl.text,
      'photoUrls': []
    };

    await ApiService.submitHourlyProgress(data);
    _hourlyProgressCtrl.clear();
    _hourlyRemarksCtrl.clear();
    _hourlyMaterialsCtrl.clear();
    _hourlyDelayCtrl.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hourly progress uploaded!')));
    setState(() => _loading = true);
    _loadMuruganData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Site Operations Command Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Murugan Home Screen: Workers Attendance, GPS, Hourly Progress Logs', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),

          VianMetricCard(title: 'LABOUR ON-SITE TODAY', value: _workers.length.toString(), icon: Icons.engineering, iconColor: VianTheme.success),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('LABOUR MANUAL ATTENDANCE WIZARD', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                              VianButton(text: 'Submit Attendance', onPressed: _submitManualAttendance),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _workers.length,
                            itemBuilder: (context, idx) {
                              final worker = _workers[idx];
                              final id = worker['id'];
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E26))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(worker['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Skill: ${worker['skillType']} | Wage: ₹${worker['dailyWage']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: _workerStatus[id] ?? 'Present',
                                      dropdownColor: VianTheme.headerBlack,
                                      items: ['Present', 'Absent', 'Half Day'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) => setState(() => _workerStatus[id] = val!),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 60,
                                      child: TextField(
                                        decoration: const InputDecoration(hintText: 'OT Hrs', contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => _workerOt[id] = double.tryParse(val) ?? 0.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(hintText: 'Remarks', contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                                        onChanged: (val) => _workerRemarks[id] = val,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUBMIT HOURLY PROGRESS REPORT', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _hourlyProgressCtrl, decoration: const InputDecoration(labelText: 'Work Progress Details'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _hourlyRemarksCtrl, decoration: const InputDecoration(labelText: 'Remarks'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _hourlyWorkersCtrl, decoration: const InputDecoration(labelText: 'Workers Present'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _hourlyPercentageCtrl, decoration: const InputDecoration(labelText: 'Completion %'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _hourlyWeatherCtrl, decoration: const InputDecoration(labelText: 'Weather'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _hourlyMaterialsCtrl, decoration: const InputDecoration(labelText: 'Materials Used'))),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _hourlyDelayCtrl, decoration: const InputDecoration(labelText: 'Delay Reason (optional)'))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          VianButton(text: 'Upload Site Progress', onPressed: _submitHourlyProgressReport),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HOURLY PROGRESS LOGS TODAY', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          if (_hourlyProgressList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: Text('No hourly logs submitted today.', style: TextStyle(color: VianTheme.lightText))),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _hourlyProgressList.length,
                              itemBuilder: (context, idx) {
                                final log = _hourlyProgressList[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(log['user']?['name'] ?? 'Engineer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('${log['completionPercentage']}% Complete', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(log['workProgress'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      if (log['remarks'] != null && log['remarks'].toString().isNotEmpty)
                                        Text('Note: ${log['remarks']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 10, fontFamily: 'monospace')),
                                    ],
                                  ),
                                );
                              },
                            )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 5. EMPLOYEE HOME VIEW (Gokul, Sivaraman, Mohan, Vijayan, Manoj)
// ==========================================
class EmployeeDashboardView extends StatefulWidget {
  const EmployeeDashboardView({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardView> createState() => _EmployeeDashboardViewState();
}

class _EmployeeDashboardViewState extends State<EmployeeDashboardView> {
  bool _loading = true;
  bool _checkedIn = false;
  Timer? _gpsTimer;
  Map<String, dynamic>? _activeWarning;
  int idx = 0;
  
  List<dynamic> _tasks = [];
  List<dynamic> _announcements = [];
  List<dynamic> _fines = [];
  Map<String, dynamic>? _myIncentive;

  int? _selectedProjectId;
  List<dynamic> _projects = [];
  final _workReportCtrl = TextEditingController();
  final _quantityCompletedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCategory = 'Site Audit';

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    final projs = await ApiService.getProjects();
    final tsk = await ApiService.getTasks();
    final anns = await ApiService.getAnnouncements();
    final finesData = await ApiService.getFines();
    final attLogs = await ApiService.getAttendance();

    final String currentMonth = DateTime.now().toString().substring(0, 7);
    final incs = await ApiService.getIncentives(currentMonth);
    dynamic myInc;
    if (incs.isNotEmpty) {
      myInc = incs.first;
    }

    final todayStr = DateTime.now().toString().split(' ').first;
    dynamic myTodayAtt;
    for (var a in attLogs) {
      if (a['userId'] == ApiService.currentUser?['id'] && a['date'] == todayStr) {
        myTodayAtt = a;
        break;
      }
    }
    final hasCheckedIn = myTodayAtt != null && myTodayAtt['checkOutTime'] == null;

    if (projs.isNotEmpty) {
      _selectedProjectId = projs.first['id'];
    }

    if (mounted) {
      setState(() {
        _projects = projs;
        _tasks = tsk;
        _announcements = anns;
        _checkedIn = hasCheckedIn;
        _fines = (finesData['fines'] as List<dynamic>?)?.where((f) => f['employeeId'] == ApiService.currentUser?['id']).toList() ?? [];
        _myIncentive = myInc;
        _loading = false;
      });
    }
  }

  void _triggerCheckIn() async {
    final double lat = 28.4630;
    final double lng = 77.0300;
    final String gpsStr = '$lat° N, $lng° E';
    
    final ok = await ApiService.checkIn(gpsStr, 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80');
    if (ok) {
      setState(() => _checkedIn = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Morning Punch In successful! (GPS Geofence Verified)')));
      _loadEmployeeData();
      
      _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        final double currentLat = 28.4630 + (idx % 2 == 0 ? 0.001 : -0.001);
        final double currentLng = 77.0300;
        idx++;
        
        final res = await ApiService.trackGps(currentLat, currentLng);
        if (res['isOutside'] == true) {
          setState(() {
            _activeWarning = res['warning'];
          });
        } else {
          setState(() {
            _activeWarning = null;
          });
        }
      });
    }
  }

  void _triggerCheckOut() async {
    final double lat = 28.4630;
    final double lng = 77.0300;
    final String gpsStr = '$lat° N, $lng° E';
    
    final ok = await ApiService.checkOut(gpsStr);
    if (ok) {
      _gpsTimer?.cancel();
      setState(() {
        _checkedIn = false;
        _activeWarning = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evening Punch Out successful!')));
      _loadEmployeeData();
    }
  }

  void _submitEodReport() async {
    if (_workReportCtrl.text.isEmpty || _selectedProjectId == null) return;

    final data = {
      'projectId': _selectedProjectId,
      'workCategory': _selectedCategory,
      'workDescription': _workReportCtrl.text,
      'quantityCompleted': _quantityCompletedCtrl.text,
      'notes': _notesCtrl.text
    };

    await ApiService.submitDailyReport(data);
    _workReportCtrl.clear();
    _quantityCompletedCtrl.clear();
    _notesCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EOD Report submitted successfully!')));
  }

  void _showPhotoUploadModal(String slotName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: Text('Upload 5 Photos - Slot: $slotName', style: const TextStyle(color: VianTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload 5 geofenced site photos for this progress audit slot.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: VianTheme.primaryGold, size: 36),
                    Text('5 Photos Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('GPS: 28.4630° N, 77.0300° E', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Short progress remarks description'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          VianButton(
            text: 'Submit to Cloudinary',
            onPressed: () async {
              await ApiService.submitDailyReport({
                'projectId': _selectedProjectId ?? 1,
                'workCategory': 'Photo Compliance Slot: $slotName',
                'workDescription': 'Uploaded 5 photos for slot $slotName',
                'photoUrls': jsonEncode([
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80'
                ])
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully uploaded photos for slot $slotName.'))
              );
              _loadEmployeeData();
            },
          )
        ],
      ),
    );
  }

  void _showPendingWorkModal(dynamic task) {
    String selectedReason = 'Material Delay';
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 2)).toString().split(' ').first);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          title: const Text('Report Pending Work / Delay Reason', style: TextStyle(color: VianTheme.primaryGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Reason for Delay'),
                items: ['Material Delay', 'Rain', 'Labour Issue', 'Client Delay', 'Site Closed', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  setModalState(() {
                    selectedReason = val!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Expected Completion Date (YYYY-MM-DD)'),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            VianButton(
              text: 'Submit Delay Report',
              onPressed: () async {
                await ApiService.updateTask(task['id'], {
                  'status': 'Pending',
                  'description': '${task['description']}\n\n[DELAY REPORTED] Reason: $selectedReason | New Expected Completion: ${dateCtrl.text}'
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delay reason submitted. MD and Admin notified.'))
                );
                _loadEmployeeData();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSlots() {
    final slots = [
      {'time': '11:00 AM', 'slot': '11 AM'},
      {'time': '12:00 PM', 'slot': '12 PM'},
      {'time': '01:00 PM', 'slot': '1 PM'},
      {'time': '03:00 PM', 'slot': '3 PM'},
      {'time': '04:00 PM', 'slot': '4 PM'},
      {'time': '05:00 PM', 'slot': '5 PM'},
    ];

    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY PROGRESS PHOTO UPLOADS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Upload 5 site photos for each designated hourly slot. Captures location automatically.', style: TextStyle(color: Color(0xFF70707C), fontSize: 11)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: slots.map((slot) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot['time']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VianTheme.primaryGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: () {
                            _showPhotoUploadModal(slot['slot']!);
                          },
                          icon: const Icon(Icons.camera_alt, size: 12),
                          label: const Text('Upload', style: TextStyle(fontSize: 10)),
                        )
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${ApiService.currentUser?['name'] ?? 'Employee'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const Text('Employee Workspace: GPS Attendance, Tasks, EOD reporting', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              VianButton(
                text: _checkedIn ? 'Check Out' : 'GPS Check In',
                color: _checkedIn ? VianTheme.danger : VianTheme.success,
                onPressed: _checkedIn ? _triggerCheckOut : _triggerCheckIn,
              )
            ],
          ),
          const SizedBox(height: 20),

          if (_activeWarning != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0x33DC3545), border: Border.all(color: VianTheme.danger), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: VianTheme.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('WARNING: You have left the project area geofence! Supervisors notified in ${_activeWarning!['duration']} minutes.', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  )
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR ASSIGNED TASKS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            itemBuilder: (context, idx) {
                              final task = _tasks[idx];
                              Map<String, dynamic>? meta;
                              try {
                                if (task['description'] != null && task['description'].toString().startsWith('{')) {
                                  meta = jsonDecode(task['description'].toString());
                                }
                              } catch (e) {
                                // ignore
                              }

                              final isCompleted = task['status'] == 'Completed';

                              return Card(
                                color: const Color(0xFF1E1E26),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: VianTheme.primaryGold),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isCompleted ? const Color(0x3328A745) : const Color(0x33FFC107),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              task['status'] ?? 'Pending',
                                              style: TextStyle(color: isCompleted ? VianTheme.success : VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (meta != null) ...[
                                        Text('Client: ${meta['clientName']}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                        Text('Project: ${meta['projectName']}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                        Text('Checklist: ${meta['checklist']}', style: const TextStyle(fontSize: 12, color: VianTheme.primaryGold)),
                                        Text('Drawing: ${meta['drawing']}', style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                                        Text('Expected Completion: ${meta['expectedCompletion']}', style: const TextStyle(fontSize: 12, color: VianTheme.danger)),
                                        const SizedBox(height: 8),
                                        Text('Instructions: ${meta['notes']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ] else ...[
                                        Text(task['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                      const SizedBox(height: 8),
                                      Text('Due Date: ${task['dueDate']}', style: const TextStyle(fontSize: 11, color: VianTheme.lightText)),
                                      if (!isCompleted) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.warning_amber_rounded, size: 14, color: VianTheme.danger),
                                              label: const Text('Report Delay', style: TextStyle(color: VianTheme.danger, fontSize: 12)),
                                              onPressed: () => _showPendingWorkModal(task),
                                            ),
                                            const SizedBox(width: 12),
                                            VianButton(
                                              text: 'Mark Complete',
                                              onPressed: () async {
                                                await ApiService.updateTaskStatus(task['id'], 'Completed');
                                                _loadEmployeeData();
                                              },
                                            )
                                          ],
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildPhotoUploadSlots(),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUBMIT DAILY EOD WORK REPORT', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  dropdownColor: VianTheme.headerBlack,
                                  decoration: const InputDecoration(labelText: 'Category'),
                                  items: ['Brick Work', 'Painting', 'Interior Design', 'Plumbing', 'Electrical', 'Site Audit'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _selectedCategory = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: TextField(controller: _quantityCompletedCtrl, decoration: const InputDecoration(labelText: 'Quantity (e.g. 1200 Sq Ft)'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: _workReportCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Work Description')),
                          const SizedBox(height: 12),
                          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Special Notes / Issues faced')),
                          const SizedBox(height: 16),
                          VianButton(text: 'Submit EOD Report', onPressed: _submitEodReport),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (_fines.isNotEmpty) ...[
                      VianCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR ACTIVE FINES', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.danger)),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _fines.length,
                              itemBuilder: (context, idx) {
                                final f = _fines[idx];
                                final isAck = f['acknowledged'] == true;
                                return Card(
                                  color: const Color(0xFF1E1E26),
                                  child: ListTile(
                                    title: Text('Fine Amount: ₹${f['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(f['reason'] ?? ''),
                                    trailing: isAck
                                        ? const Text('Acknowledged', style: TextStyle(color: VianTheme.success, fontSize: 11))
                                        : VianButton(
                                            text: 'Acknowledge',
                                            onPressed: () async {
                                              await ApiService.acknowledgeFine(f['id']);
                                              _loadEmployeeData();
                                            },
                                          ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_myIncentive != null) ...[
                      VianCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR MONTHLY INCENTIVE STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Performance Score:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${safeToDouble(_myIncentive!['totalScore']).toStringAsFixed(1)} / 100',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Suggested Incentive:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '₹${safeToDouble(_myIncentive!['suggestedAmount']).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Approved Payout:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '₹${safeToDouble(_myIncentive!['finalAmount']).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                _statusTag(_myIncentive!['status'] ?? 'Draft'),
                              ],
                            ),
                            if (_myIncentive!['adminRemarks'] != null && _myIncentive!['adminRemarks'].toString().isNotEmpty) ...[
                              const Divider(color: Colors.white10),
                              const Text('Admin Remarks:', style: TextStyle(fontSize: 11, color: VianTheme.primaryGold)),
                              Text(
                                _myIncentive!['adminRemarks'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                            if (_myIncentive!['superAdminRemarks'] != null && _myIncentive!['superAdminRemarks'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('Management Remarks:', style: TextStyle(fontSize: 11, color: VianTheme.primaryGold)),
                              Text(
                                _myIncentive!['superAdminRemarks'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COMPANY ANNOUNCEMENTS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length > 2 ? 2 : _announcements.length,
                            itemBuilder: (context, idx) {
                              final ann = _announcements[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ann['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(ann['message'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        VianButton(
                                          text: 'Acknowledge',
                                          isSecondary: true,
                                          onPressed: () async {
                                            await ApiService.acknowledgeAnnouncement(ann['id']);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement acknowledged.')));
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _statusTag(String status) {
    Color bg = Colors.grey.withOpacity(0.1);
    Color txt = Colors.grey;
    if (status == 'Approved') {
      bg = Colors.green.withOpacity(0.15);
      txt = Colors.greenAccent;
    } else if (status == 'Paid') {
      bg = Colors.green.withOpacity(0.25);
      txt = Colors.green;
    } else if (status == 'Under Review') {
      bg = Colors.orange.withOpacity(0.15);
      txt = Colors.orangeAccent;
    } else if (status == 'Recommended') {
      bg = Colors.purple.withOpacity(0.15);
      txt = Colors.purpleAccent;
    } else if (status == 'Rejected') {
      bg = Colors.red.withOpacity(0.15);
      txt = Colors.redAccent;
    } else if (status == 'Draft') {
      bg = Colors.grey.withOpacity(0.15);
      txt = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status, style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color col;
  const _LegendItem(this.label, this.col, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF70707C))),
      ],
    );
  }
}
