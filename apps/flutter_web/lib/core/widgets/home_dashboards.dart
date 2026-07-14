import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'custom_widgets.dart';
import 'face_gps_verify_overlay.dart';

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
  Map<String, dynamic>? _attendanceStats;
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
    final attStats = await ApiService.getAttendanceDashboardStats();

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
        _attendanceStats = attStats['stats'];
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
        backgroundColor: VianTheme.cardColor,
        title: const Text('APPLY GEOFENCE FINE', style: TextStyle(color: VianTheme.danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Employee: ${warning['user']?['name'] ?? 'Employee'}', style: const TextStyle(color: VianTheme.headerBlack)),
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
        backgroundColor: VianTheme.cardColor,
        title: const Text('PUBLISH COMPANY ANNOUNCEMENT', style: TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: VianTheme.cardColor,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Urgent', 'Holiday', 'Meeting', 'Safety'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: VianTheme.headerBlack)))).toList(),
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

  Widget _tableHeader(String text, {bool isRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          color: VianTheme.primaryGold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        textAlign: isRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  TableRow _tableRow(Map<String, dynamic> proj, NumberFormat currencyFormatter) {
    final status = proj['status'] ?? 'Draft';
    final valuation = safeToDouble(proj['budgetedCost'] ?? proj['budget'] ?? 0.0);
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: VianTheme.goldBorder.withOpacity(0.4), width: 1)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: VianTheme.goldBorder, width: 1),
                  color: const Color(0xFF1E1F23),
                ),
                child: const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  proj['name'] ?? 'Untitled Project',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              proj['clientName'] ?? proj['client']?['name'] ?? 'N/A',
              style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              proj['address'] ?? 'Kyoto, JP',
              style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: VianTheme.primaryGold.withOpacity(0.08),
                border: Border.all(color: VianTheme.primaryGold.withOpacity(0.2), width: 1),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              currencyFormatter.format(valuation),
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart() {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: 0.65,
                      strokeWidth: 12,
                      backgroundColor: VianTheme.goldBorder.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('65%', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('RESIDENTIAL', style: GoogleFonts.outfit(fontSize: 8, color: VianTheme.lightText, letterSpacing: 0.5)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chartLegend(VianTheme.primaryGold, 'Residential ($6.1M)'),
              const SizedBox(height: 10),
              _chartLegend(VianTheme.lightText, 'Commercial ($2.3M)'),
              const SizedBox(height: 10),
              _chartLegend(VianTheme.goldBorder, 'Civic ($1.0M)'),
            ],
          )
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
      ],
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _barItem('Jan', 70),
          _barItem('Feb', 95),
          _barItem('Mar', 130, isHighlighted: true),
          _barItem('Apr', 85),
          _barItem('May', 110),
          _barItem('Jun', 100),
        ],
      ),
    );
  }

  Widget _barItem(String month, double height, {bool isHighlighted = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 18,
          height: height,
          color: isHighlighted ? VianTheme.primaryGold : VianTheme.goldBorder.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          month.toUpperCase(),
          style: GoogleFonts.outfit(
            color: isHighlighted ? VianTheme.primaryGold : VianTheme.lightText,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Main Area)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
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
                          'Executive Command Overview',
                          style: GoogleFonts.outfit(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: -0.5
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Managing Director Command Panel (Anand)', 
                          style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13)
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync, color: VianTheme.primaryGold), 
                      onPressed: () => setState(() { _loading = true; _loadAllData(); })
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // KPI CARDS
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 700 ? 2 : 4;
                    return GridView.count(
                      crossAxisCount: cols,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      shrinkWrap: true,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        CustomPaint(
                          painter: AtelierBracketPainter(color: VianTheme.primaryGold),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ACTIVE PROJECTS', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                Text('142', style: GoogleFonts.bodoniModa(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: VianTheme.primaryGold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('+12% since last month', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(color: VianTheme.primaryGold),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TOTAL REVENUE', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                Text('₹9.4M', style: GoogleFonts.bodoniModa(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: VianTheme.primaryGold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('+2.1M growth', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(color: VianTheme.primaryGold),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('UTILIZATION RATE', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                Text('88%', style: GoogleFonts.bodoniModa(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: VianTheme.primaryGold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Optimal capacity', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(color: VianTheme.primaryGold),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('AVG COMPLETION', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                Text('240d', style: GoogleFonts.bodoniModa(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: VianTheme.primaryGold, size: 14),
                                    const SizedBox(width: 4),
                                    Text('-4% efficiency gain', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // CHARTS ROW
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 700;
                    return Flex(
                      direction: isSmall ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(
                          flex: isSmall ? 0 : 1,
                          child: VianCard(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REVENUE DISTRIBUTION', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 16),
                                _buildDonutChart(),
                              ],
                            ),
                          ),
                        ),
                        if (!isSmall) const SizedBox(width: 24),
                        if (isSmall) const SizedBox(height: 24),
                        Expanded(
                          flex: isSmall ? 0 : 1,
                          child: VianCard(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PROJECT VELOCITY', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                const SizedBox(height: 16),
                                _buildBarChart(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // TARGET PROGRESS VIEW
                Text('ANNUAL TARGETS ACHIEVEMENT', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: VianTheme.primaryGold, letterSpacing: 1.0)),
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

                // GEOFENCE VIOLATIONS CARD
                if (_warnings.isNotEmpty) ...[
                  VianCard(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GPS ATTENDANCE & GEOFENCE BREACHES', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.danger, letterSpacing: 1.0, fontSize: 13)),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _warnings.length,
                          itemBuilder: (context, idx) {
                            final warn = _warnings[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: VianTheme.goldBorder, width: 0.5)),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(backgroundColor: Color(0x1ADB5545), child: Icon(Icons.gps_off, color: VianTheme.danger, size: 16)),
                                title: Text('${warn['user']?['name'] ?? 'Employee'} left assigned site boundary', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                subtitle: Text('Project: ${warn['project']?['name']} | Location: ${warn['currentLocation']}', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11.5)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.gavel, color: VianTheme.danger, size: 18),
                                      tooltip: 'Apply Fine',
                                      onPressed: () => _showApplyFineDialog(warn),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check, color: VianTheme.success, size: 18),
                                      tooltip: 'Ignore',
                                      onPressed: () async {
                                        await ApiService.updateWarningStatus(warn['id'], 'Ignored');
                                        setState(() => _loading = true);
                                        _loadAllData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // RECENT PROJECTS TABLE
                VianCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GLOBAL PROJECT STATUS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: VianTheme.primaryGold, width: 1),
                            ),
                            child: Text(
                              'EXPORT DATA',
                              style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_projects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('No active projects registered.', style: TextStyle(color: VianTheme.lightText))),
                        )
                      else
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                            4: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: VianTheme.goldBorder, width: 1)),
                              ),
                              children: [
                                _tableHeader('Project Identifier'),
                                _tableHeader('Client'),
                                _tableHeader('Region'),
                                _tableHeader('Status'),
                                _tableHeader('Valuation', isRight: true),
                              ],
                            ),
                            ..._projects.map((p) => _tableRow(p, currencyFormatter)).toList(),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Insights Rail
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF121317),
            border: Border(left: BorderSide(color: VianTheme.goldBorder, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE INSIGHTS', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('Real-time updates and alerts', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(color: VianTheme.goldBorder, height: 1),

              // Activity logs
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECENT ACTIVITY', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      if (_logs.isEmpty)
                        const Text('No recent activity logs.', style: TextStyle(color: Colors.white24, fontSize: 12))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _logs.length > 5 ? 5 : _logs.length,
                          itemBuilder: (context, idx) {
                            final log = _logs[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: VianTheme.primaryGold, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['message'] ?? log['action'] ?? 'System Action',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, height: 1.3),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          log['createdAt'] != null
                                              ? DateFormat('hh:mm a').format(DateTime.parse(log['createdAt']))
                                              : 'Just now',
                                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),

                      // Market trend card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: VianTheme.primaryGold.withOpacity(0.04),
                          border: const Border(left: BorderSide(color: VianTheme.primaryGold, width: 2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MARKET TREND', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text('+18.4%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Demand for sustainable concrete wireframes is rising sharply this quarter.',
                              style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // System check status list
                      Text('COMMAND STATUS', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      _statusCheckItem('Cloud Sync Database', true),
                      const SizedBox(height: 12),
                      _statusCheckItem('GPS Attendance Nodes', true),
                      const SizedBox(height: 12),
                      _statusCheckItem('Atelier Vault Security', true),
                    ],
                  ),
                ),
              ),
              const Divider(color: VianTheme.goldBorder, height: 1),

              // Bottom CTA
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: VianButton(
                    text: 'GENERATE SUITE REPORT',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Atelier Suite Report generated.')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCheckItem(String label, bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12)),
        Icon(
          active ? Icons.check_circle_outline : Icons.error_outline,
          color: active ? VianTheme.success : VianTheme.danger,
          size: 16,
        ),
      ],
    );
  }
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

    final Color ringColor;
    if (pctInt >= 90) {
      ringColor = VianTheme.success;
    } else if (pctInt >= 60) {
      ringColor = VianTheme.warning;
    } else {
      ringColor = VianTheme.danger;
    }

    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
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
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: VianTheme.headerBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ringColor,
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
                color: const Color(0xFFF1F5F9),
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
                color: Color(0xFFE2E8F0),
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
  Map<String, dynamic>? _attendanceStats;

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
    final attStats = await ApiService.getAttendanceDashboardStats();

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
        _attendanceStats = attStats['stats'];
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
          const SizedBox(height: 24),
          
          const Text('GPS GEOFENCE SECURITY & BIOMETRICS STATUS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VianTheme.primaryGold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
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
                  VianMetricCard(title: 'EMPLOYEES OUTSIDE SITE', value: '${_attendanceStats?['employeesOutsideSite'] ?? 0}', icon: Icons.person_pin_circle_outlined, iconColor: VianTheme.danger),
                  VianMetricCard(title: 'PENDING APPROVALS', value: '${_attendanceStats?['pendingAttendanceApproval'] ?? 0}', icon: Icons.pending_actions_outlined, iconColor: VianTheme.warning),
                  VianMetricCard(title: 'GPS BOUNDARY FAILURES', value: '${_attendanceStats?['gpsFailures'] ?? 0}', icon: Icons.gps_off_outlined, iconColor: VianTheme.danger),
                  VianMetricCard(title: 'FACE MATCH FAILURES', value: '${_attendanceStats?['faceFailures'] ?? 0}', icon: Icons.face_unlock_outlined, iconColor: VianTheme.danger),
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
                                leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: VianTheme.primaryGold)),
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
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
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
                                color: const Color(0xFFF1F5F9),
                                elevation: 0,
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
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
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
                                  color: const Color(0xFFF1F5F9),
                                  elevation: 0,
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
                                leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person, color: VianTheme.primaryGold)),
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
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
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
                                      backgroundColor: const Color(0xFFF1F5F9),
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
                                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                                      dropdownColor: VianTheme.cardColor,
                                      items: ['Present', 'Absent', 'Half Day'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: VianTheme.headerBlack)))).toList(),
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
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(log['user']?['name'] ?? 'Engineer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack)),
                                          Text('${log['completionPercentage']}% Complete', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(log['workProgress'] ?? '', style: const TextStyle(color: VianTheme.headerBlack, fontSize: 11)),
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

  void _triggerCheckIn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceGpsVerifyOverlay(
        action: 'check-in',
        onSuccess: () {
          Navigator.pop(ctx);
          setState(() => _checkedIn = true);
          _loadEmployeeData();
        },
        onCancel: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _triggerCheckOut() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceGpsVerifyOverlay(
        action: 'check-out',
        onSuccess: () {
          Navigator.pop(ctx);
          setState(() => _checkedIn = false);
          _loadEmployeeData();
        },
        onCancel: () {
          Navigator.pop(ctx);
        },
      ),
    );
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
        backgroundColor: VianTheme.cardColor,
        title: Text('Upload 5 Photos - Slot: $slotName', style: const TextStyle(color: VianTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload 5 geofenced site photos for this progress audit slot.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: VianTheme.primaryGold, size: 36),
                    Text('5 Photos Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.headerBlack)),
                    Text('GPS: 28.4630° N, 77.0300° E', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
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
          backgroundColor: VianTheme.cardColor,
          title: const Text('Report Pending Work / Delay Reason', style: TextStyle(color: VianTheme.primaryGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                dropdownColor: VianTheme.cardColor,
                decoration: const InputDecoration(labelText: 'Reason for Delay'),
                items: ['Material Delay', 'Rain', 'Labour Issue', 'Client Delay', 'Site Closed', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: VianTheme.headerBlack)))).toList(),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot['time']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack)),
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
                                 color: const Color(0xFFF1F5F9),
                                 elevation: 0,
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
                                             child: Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VianTheme.headerBlack)),
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
                                         Text('Client: ${meta['clientName']}', style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack)),
                                         Text('Project: ${meta['projectName']}', style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack)),
                                         Text('Checklist: ${meta['checklist']}', style: const TextStyle(fontSize: 12, color: VianTheme.primaryGold)),
                                         Text('Drawing: ${meta['drawing']}', style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                                         Text('Expected Completion: ${meta['expectedCompletion']}', style: const TextStyle(fontSize: 12, color: VianTheme.danger)),
                                         const SizedBox(height: 8),
                                         Text('Instructions: ${meta['notes']}', style: const TextStyle(fontSize: 11, color: VianTheme.lightText)),
                                       ] else ...[
                                         Text(task['description'] ?? '', style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
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

// ==========================================
// 6. CLIENT PORTAL VIEW
// ==========================================
class ClientPortalView extends StatefulWidget {
  const ClientPortalView({Key? key}) : super(key: key);

  @override
  State<ClientPortalView> createState() => _ClientPortalViewState();
}

class _ClientPortalViewState extends State<ClientPortalView> {
  bool _loading = true;
  Map<String, dynamic>? _project;
  List<dynamic> _stages = [];

  @override
  void initState() {
    super.initState();
    _loadClientProject();
  }

  Future<void> _loadClientProject() async {
    try {
      final list = await ApiService.getProjects();
      if (list.isNotEmpty) {
        _project = list.first;
        final details = await ApiService.getProjectDetails(_project!['id']);
        if (details.isNotEmpty) {
          _project = details;
          _stages = details['stages'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Error loading client project: $e");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    }

    final String projectName = _project?['name'] ?? "Maison L'Aube";
    final double progress = (_project?['progressPercentage'] ?? 74).toDouble();
    final String progressText = "${progress.toInt()}%";

    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final double budget = safeToDouble(_project?['budget'] ?? 14500000);
    final double paid = safeToDouble(_project?['paidAmount'] ?? 11000000);
    final double outstanding = budget - paid;

    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
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
                    'EXECUTIVE COMMAND',
                    style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Project Dossier: $projectName',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: VianTheme.primaryGold.withOpacity(0.08),
                border: Border.all(color: VianTheme.primaryGold),
                child: Text(
                  'CONFIDENTIAL DOSSIER',
                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Center(
            child: Column(
              children: [
                Text(
                  'CURRENT CONSTRUCTION PHASE',
                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3.0),
                ),
                const SizedBox(height: 16),
                Text(
                  progressText,
                  style: GoogleFonts.bodoniModa(
                    color: VianTheme.primaryGold,
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Container(
                  width: 200,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, VianTheme.primaryGold, Colors.transparent]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 500,
                  child: Text(
                    'Interior finishing, bespoke millwork, and stone masonry installations are currently in progress. Construction is on track for October delivery.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TIMELINE & MILESTONES', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('VIEW FULL LOG', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMilestoneCard(
                  'Foundation & Site Prep',
                  'MAY 12, 2023',
                  'COMPLETED',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDqirUa-AkKOeqNn9YcaHGH-EIkR-86pRcVue2XWy9TU_-kQeg4nQ75QGJ-SrJpiQnyIzi6d0v9F6Pj_5FB5SU4eLWq2ooU7KaSKpcdW4kh8cY72Du2wgpD4nmGTmMiIzXTfRmuyKFbK7UEoMCjHIZPtZsbO8tDU4U1GoAj7bWvETUxaInOL-hM_BybojEe5VCLCXpBszJNjmPECF9o8u_naxCtcM5U98yeubg6hdqx9cO1gUa4kGsv9lCnvhsd-SisOuRWNosyqjI',
                ),
                const SizedBox(width: 20),
                _buildMilestoneCard(
                  'Structural Framework',
                  'JULY 28, 2023',
                  'COMPLETED',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBknk5pHYPaB1A1BRZQGzKzaMBwH7ttAFmxl6OX0-GrPV6edUUGodK2NwqmEMxROkb1S9ut4XtvJPhdrJPfwGUtGqkBoINv5XaRHw0sHqmEoKEKietE9zD_YQV8bE_zthFv5UuKpWMYw5o6Ok6UsVSsHtHg4OCBb8vG8qmXj2HFALyd6v8rB8Wrj0MTnUE2gIlHOPLSFUL9oaitbW249njKAACiwMiCvvvaTZWCpQw53C4p--gkn86cXmt1HChVL2LI6PJa4Zv1gk8',
                ),
                const SizedBox(width: 20),
                _buildMilestoneCard(
                  'Interior Millwork',
                  'SEPTEMBER 14, 2023',
                  'IN PROGRESS',
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAVN-ovZpD6lonPMdXkXT13YIcHK_vZ5EXTm3uowjjt11OYkyTD48Pp41yatS7zi0_1jsvA5MJP9PxmJi0CxCg2lyQ2ofC4ugFj_MMAyHKtYToVS67PzpE6PYb89XW4eLbdYpFwgOW640H2dN3RwTXKHI__5bSxk-XltHJ9sNbnjnJC1V50WsLTOIVTOk4F6rUt-cCfgmysJJgVW7sAySWheLXYTvEqOtK78lSMSrEJvifnzVeaYYaw1y5LZwmwxH4V5fbhFFGHGa4',
                  isActive: true,
                ),
                const SizedBox(width: 20),
                _buildMilestoneCard(
                  'Landscaping & Exterior',
                  'OCTOBER 30, 2023',
                  'UPCOMING',
                  '',
                  isUpcoming: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildBlueprintsDossier()),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: _buildFinancialSummary(formatter, budget, paid, outstanding)),
              ],
            )
          else ...[
            _buildBlueprintsDossier(),
            const SizedBox(height: 32),
            _buildFinancialSummary(formatter, budget, paid, outstanding),
          ],
          const SizedBox(height: 48),

          Container(
            height: 320,
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border.all(color: Colors.white.withOpacity(0.04)),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDMAErbO4i1T_qkd_vzf5XsFhOH0Lr6B8bA86yZyC7TG_wOhJawrHq7QKGQd8sHUXrO23gO-4UyLoOD9K-j4dl8ZaMjjMOZkNLDRHFJyV033jeNhuvJLLtjMO4wsQKP6NsywnGtBvP482J9f1I142b0IeovY7L-gR_ZZ-wS3od8IG8-qABVTAlDTuT0JCuRY8wqiUdoibJFh4NG5_d22nm5GD5Lt9iLRCB9hPLO17B3Sw2zvHjAxm31N63cex5H9PjORJe-lTXmj7c'),
                fit: BoxFit.cover,
                opacity: 0.35,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 32,
                  left: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROJECT LOCATION', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      Text(
                        _project?['siteAddress'] ?? 'Varenna Estate, Lake Como',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 32,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.8),
                    border: Border.all(color: Colors.white10),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('CURRENT WEATHER', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text('22°C Clear', style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.wb_sunny, color: VianTheme.primaryGold, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(String title, String date, String status, String imageUrl, {bool isActive = false, bool isUpcoming = false}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(color: isActive ? VianTheme.primaryGold : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: isUpcoming
                ? Container(
                    color: const Color(0xFF13131A),
                    child: Center(
                      child: Icon(Icons.landscape, color: Colors.white.withOpacity(0.08), size: 48),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF13131A)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date, style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: isActive ? Colors.white : (isUpcoming ? Colors.white10 : VianTheme.primaryGold.withOpacity(0.1)),
                      child: Text(
                        status,
                        style: GoogleFonts.outfit(
                          color: isActive ? Colors.black : (isUpcoming ? VianTheme.lightText : VianTheme.primaryGold),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBlueprintsDossier() {
    final blueprints = [
      {'name': 'L01_FLOORPLAN_V4.PDF', 'desc': 'Architectural Floor Plan Layout', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDNp3L7QKmIg22J6AY_J0xQFbJ_GtPFvBo3A1i-zDyfjuvFmqk1mBAFF8aFWoXb6OuFS2eNIq3-OqiqWyCew7_ekeTg6Kb2WgJUeTqvaNbaUZgNmofIh53SDCPnm7NciFa3PDmnuZMQ1s0DPvZXnMoKUEc1pb8_QWUJj9yCw1CvOcTArEiRf9t41ldz7hmOn0Xuex0vvTeHKU7xAs9BuIgLvC8hnFbz6mwoNp4PJEC9KDEd9jFGjYApcZ7QLXYU_3rkVp26pYhpQe0'},
      {'name': 'STAIR_DETAIL_A1.PDF', 'desc': 'Section Detail: Oak Staircase', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAR9RyzG3djRghhGsMnRucSBlIfjITy4b4SkbvQiBMxeZ_-g1exWk27StLxjobrPRsZ9ThgB6OVjELdMRgB_KyppuRaNVPv3nFxfSVyBSxvGS6CBCGZxeRkNZcN0EXBwts63DLB84gPCvQC2gTXF_OICt1-xgfoCsQ80ky5waqpD_xTQyRcHmEGZBoFxKNOxAjYaIxCaBTrz0TYT-QKFCYRJq-GCP0fu3QyF95ITY1XwW-grNn4p8Hms70gfPF6po18gxoaR9GFjlM'},
      {'name': 'ELEC_LAYOUT_FINAL.PDF', 'desc': 'Master Lighting Layout Scheme', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDSosd_Ud9CnxDIP5NkuOZAEosZlh3b_rH_HS2Xa1HFejNP9XxtyDNLRoZhX8e4ZbYTv1ryCXKuR1MQgLfLfrU-KSq7pYAfpduT78bWZa6CGt1To80tVnvgy6ynTGSMzHkeNj9W3rlyddApxEEeZwe7r8za3S2FszU3kYTT68yAIL6-RkAXn4Trmbgo0AZIOdX6WTLPuNkFpQHdAkMCYCTKQWsxcgVsRfz0yrzvxbvnc5KsQcMtmDlR6EHEC7lIRZXXn9mGH0j8njI'},
    ];

    return Container(
      color: VianTheme.cardColor,
      border: Border.all(color: Colors.white.withOpacity(0.04)),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TECHNICAL DOSSIER', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('Approved Blueprints', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.download, color: VianTheme.primaryGold, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: blueprints.length + 1,
            itemBuilder: (context, idx) {
              if (idx == blueprints.length) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, color: VianTheme.lightText, size: 24),
                        const SizedBox(height: 8),
                        Text('REQUEST REVISION', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                );
              }
              final bp = blueprints[idx];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  image: DecorationImage(
                    image: NetworkImage(bp['url']!),
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bp['name']!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(bp['desc']!, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(NumberFormat formatter, double budget, double paid, double outstanding) {
    return Column(
      children: [
        CustomPaint(
          painter: AtelierBracketPainter(color: VianTheme.primaryGold),
          child: Container(
            color: VianTheme.cardColor,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FINANCIAL SUMMARY', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Valuation', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13)),
                    Text(formatter.format(budget), style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paid to Date', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13)),
                    Text(formatter.format(paid), style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Outstanding Balance', style: GoogleFonts.inter(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(formatter.format(outstanding), style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: Text('PAY NOW', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          color: VianTheme.cardColor,
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                color: const Color(0xFF13131A),
                child: const Icon(Icons.support_agent, color: VianTheme.primaryGold, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONCIERGE SUPPORT', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                  Text('Chat with Lead Architect', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: VianTheme.primaryGold, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

