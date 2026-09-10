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
        _analytics = analytics;
        _targetAlerts = targetAlerts;
        _attendanceStats = attStats['stats'];
        _loading = false;
      });
    }
  }

  void _showApplyFineDialog(Map<String, dynamic> warning) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(
      text: 'Geofence Breach: Left assigned site boundary',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: const Text(
          'APPLY GEOFENCE FINE',
          style: TextStyle(color: VianTheme.danger),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Employee: ${warning['user']?['name'] ?? 'Employee'}',
              style: const TextStyle(color: VianTheme.headerBlack),
            ),
            const SizedBox(height: 8),
            Text(
              'Project: ${warning['project']?['name'] ?? 'Project'}',
              style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Fine Amount (INR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          VianButton(
            text: 'Apply Fine',
            color: VianTheme.danger,
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt > 0) {
                await ApiService.applyFine(
                  warning['id'],
                  warning['userId'] ?? 1,
                  amt,
                  reasonCtrl.text,
                );
                Navigator.pop(context);
                setState(() => _loading = true);
                _loadAllData();
              }
            },
          ),
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
        title: const Text(
          'PUBLISH COMPANY ANNOUNCEMENT',
          style: TextStyle(color: VianTheme.primaryGold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: VianTheme.cardColor,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['General', 'Urgent', 'Holiday', 'Meeting', 'Safety']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: const TextStyle(color: VianTheme.headerBlack),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message Body'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          VianButton(
            text: 'Publish',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && messageCtrl.text.isNotEmpty) {
                await ApiService.addAnnouncement({
                  'title': titleCtrl.text,
                  'message': messageCtrl.text,
                  'targetRole': 'All',
                  'type': type,
                });
                Navigator.pop(context);
                setState(() => _loading = true);
                _loadAllData();
              }
            },
          ),
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

  TableRow _tableRow(
    Map<String, dynamic> proj,
    NumberFormat currencyFormatter,
  ) {
    final status = proj['status'] ?? 'Draft';
    final valuation = safeToDouble(
      proj['budgetedCost'] ?? proj['budget'] ?? 0.0,
    );
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VianTheme.goldBorder.withOpacity(0.4),
            width: 1,
          ),
        ),
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
                child: const Icon(
                  Icons.architecture,
                  color: VianTheme.primaryGold,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  proj['name'] ?? 'Untitled Project',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
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
              style: GoogleFonts.inter(
                color: VianTheme.lightText,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              proj['address'] ?? 'Kyoto, JP',
              style: GoogleFonts.inter(
                color: VianTheme.lightText,
                fontSize: 13,
              ),
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
                border: Border.all(
                  color: VianTheme.primaryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: VianTheme.primaryGold,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
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
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        VianTheme.primaryGold,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '65%',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'RESIDENTIAL',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          color: VianTheme.lightText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chartLegend(VianTheme.primaryGold, 'Residential (\$6.1M)'),
              const SizedBox(height: 10),
              _chartLegend(VianTheme.lightText, 'Commercial (\$2.3M)'),
              const SizedBox(height: 10),
              _chartLegend(VianTheme.goldBorder, 'Civic (\$1.0M)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11),
        ),
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
          color: isHighlighted
              ? VianTheme.primaryGold
              : VianTheme.goldBorder.withOpacity(0.5),
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
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
        ),
      );

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final curPerf = _analytics?['currentPerformance'] ?? {};
    final targets = _analytics?['targets'] ?? {};
    final forecasts = _analytics?['forecasts'] ?? {};
    final scoreData = _analytics?['scorecard'] ?? {};
    final depts = _analytics?['departments'] ?? {};

    final turnoverActual = safeToDouble(curPerf['actualTurnover']);
    final turnoverTarget = safeToDouble(
      targets['annualRevenueTarget'] ?? 10000000.0,
    );

    final profitActual = safeToDouble(curPerf['netProfit']);
    final profitTarget = safeToDouble(
      targets['annualProfitTarget'] ?? 3000000.0,
    );

    final projectsActual = safeToDouble(curPerf['projectsCompleted']);
    final projectsTarget = safeToDouble(
      targets['annualProjectTarget'] ?? 120.0,
    );

    final clientsActual = safeToDouble(
      (curPerf['newClients'] ?? 0) + (curPerf['repeatClients'] ?? 0),
    );
    final clientsTarget = safeToDouble(
      (targets['newClientTarget'] ?? 15) + (targets['repeatClientTarget'] ?? 5),
    );

    final monthlyRevenueData = List<double>.from(
      (_analytics?['monthlyRevenue'] ?? []).map((e) => safeToDouble(e)),
    );

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
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Managing Director Command Panel (Anand)',
                          style: GoogleFonts.inter(
                            color: VianTheme.lightText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.sync,
                        color: VianTheme.primaryGold,
                      ),
                      onPressed: () => setState(() {
                        _loading = true;
                        _loadAllData();
                      }),
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
                          painter: AtelierBracketPainter(
                            color: VianTheme.primaryGold,
                          ),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ACTIVE PROJECTS',
                                  style: GoogleFonts.outfit(
                                    color: VianTheme.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '142',
                                  style: GoogleFonts.bodoniModa(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: VianTheme.primaryGold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+12% since last month',
                                      style: GoogleFonts.inter(
                                        color: VianTheme.lightText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(
                            color: VianTheme.primaryGold,
                          ),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL REVENUE',
                                  style: GoogleFonts.outfit(
                                    color: VianTheme.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '₹9.4M',
                                  style: GoogleFonts.bodoniModa(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: VianTheme.primaryGold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+2.1M growth',
                                      style: GoogleFonts.inter(
                                        color: VianTheme.lightText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(
                            color: VianTheme.primaryGold,
                          ),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'UTILIZATION RATE',
                                  style: GoogleFonts.outfit(
                                    color: VianTheme.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '88%',
                                  style: GoogleFonts.bodoniModa(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: VianTheme.primaryGold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Optimal capacity',
                                      style: GoogleFonts.inter(
                                        color: VianTheme.lightText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: AtelierBracketPainter(
                            color: VianTheme.primaryGold,
                          ),
                          child: Container(
                            color: VianTheme.cardColor,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AVG COMPLETION',
                                  style: GoogleFonts.outfit(
                                    color: VianTheme.primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '240d',
                                  style: GoogleFonts.bodoniModa(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.arrow_downward,
                                      color: VianTheme.primaryGold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '-4% efficiency gain',
                                      style: GoogleFonts.inter(
                                        color: VianTheme.lightText,
                                        fontSize: 11,
                                      ),
                                    ),
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
                                Text(
                                  'REVENUE DISTRIBUTION',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
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
                                Text(
                                  'PROJECT VELOCITY',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
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
                Text(
                  'ANNUAL TARGETS ACHIEVEMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: VianTheme.primaryGold,
                    letterSpacing: 1.0,
                  ),
                ),
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
                          label:
                              '${projectsActual.toInt()} / ${projectsTarget.toInt()} Projects',
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
                        Text(
                          'GPS ATTENDANCE & GEOFENCE BREACHES',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: VianTheme.danger,
                            letterSpacing: 1.0,
                            fontSize: 13,
                          ),
                        ),
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
                                border: Border(
                                  bottom: BorderSide(
                                    color: VianTheme.goldBorder,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0x1ADB5545),
                                  child: Icon(
                                    Icons.gps_off,
                                    color: VianTheme.danger,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  '${warn['user']?['name'] ?? 'Employee'} left assigned site boundary',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Project: ${warn['project']?['name']} | Location: ${warn['currentLocation']}',
                                  style: GoogleFonts.inter(
                                    color: VianTheme.lightText,
                                    fontSize: 11.5,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.gavel,
                                        color: VianTheme.danger,
                                        size: 18,
                                      ),
                                      tooltip: 'Apply Fine',
                                      onPressed: () =>
                                          _showApplyFineDialog(warn),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: VianTheme.success,
                                        size: 18,
                                      ),
                                      tooltip: 'Ignore',
                                      onPressed: () async {
                                        await ApiService.updateWarningStatus(
                                          warn['id'],
                                          'Ignored',
                                        );
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
                          Text(
                            'GLOBAL PROJECT STATUS',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: VianTheme.primaryGold,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'EXPORT DATA',
                              style: GoogleFonts.outfit(
                                color: VianTheme.primaryGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_projects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No active projects registered.',
                              style: TextStyle(color: VianTheme.lightText),
                            ),
                          ),
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
                                border: Border(
                                  bottom: BorderSide(
                                    color: VianTheme.goldBorder,
                                    width: 1,
                                  ),
                                ),
                              ),
                              children: [
                                _tableHeader('Project Identifier'),
                                _tableHeader('Client'),
                                _tableHeader('Region'),
                                _tableHeader('Status'),
                                _tableHeader('Valuation', isRight: true),
                              ],
                            ),
                            ..._projects
                                .map((p) => _tableRow(p, currencyFormatter))
                                .toList(),
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
            border: Border(
              left: BorderSide(color: VianTheme.goldBorder, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE INSIGHTS',
                      style: GoogleFonts.outfit(
                        color: VianTheme.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time updates and alerts',
                      style: GoogleFonts.inter(
                        color: VianTheme.lightText,
                        fontSize: 12,
                      ),
                    ),
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
                      Text(
                        'RECENT ACTIVITY',
                        style: GoogleFonts.outfit(
                          color: VianTheme.lightText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_logs.isEmpty)
                        const Text(
                          'No recent activity logs.',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        )
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
                                    decoration: const BoxDecoration(
                                      color: VianTheme.primaryGold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['message'] ??
                                              log['action'] ??
                                              'System Action',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          log['createdAt'] != null
                                              ? DateFormat('hh:mm a').format(
                                                  DateTime.parse(
                                                    log['createdAt'],
                                                  ),
                                                )
                                              : 'Just now',
                                          style: GoogleFonts.inter(
                                            color: Colors.white24,
                                            fontSize: 10,
                                          ),
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
                          border: const Border(
                            left: BorderSide(
                              color: VianTheme.primaryGold,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MARKET TREND',
                              style: GoogleFonts.outfit(
                                color: VianTheme.primaryGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+18.4%',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Demand for sustainable concrete wireframes is rising sharply this quarter.',
                              style: GoogleFonts.inter(
                                color: VianTheme.lightText,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // System check status list
                      Text(
                        'COMMAND STATUS',
                        style: GoogleFonts.outfit(
                          color: VianTheme.lightText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
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
                        const SnackBar(
                          content: Text('Atelier Suite Report generated.'),
                        ),
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
        Text(
          label,
          style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12),
        ),
        Icon(
          active ? Icons.check_circle_outline : Icons.error_outline,
          color: active ? VianTheme.success : VianTheme.danger,
          size: 16,
        ),
      ],
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
                Text(
                  teamName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric,
                  style: const TextStyle(
                    color: VianTheme.lightText,
                    fontSize: 11,
                  ),
                ),
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
          Text(
            label,
            style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
              fontSize: 13,
            ),
          ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            style: const TextStyle(fontSize: 10, color: VianTheme.lightText),
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
          child: Text(
            'No revenue data available',
            style: TextStyle(color: VianTheme.lightText),
          ),
        ),
      );
    }

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double maxInterval = maxVal > 0 ? maxVal : 10.0;

    final List<String> months = [
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
      'Jan',
      'Feb',
      'Mar',
    ];

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
              return const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: VianTheme.lightText,
                      fontSize: 9,
                    ),
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
                        style: const TextStyle(
                          color: VianTheme.lightText,
                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
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
  final _assignDueDateCtrl = TextEditingController(
    text: DateTime.now().toString().split(' ').first,
  );
  final _assignTimeCtrl = TextEditingController(text: '05:00 PM');
  final _assignNotesCtrl = TextEditingController();

  final List<String> _checklistItems = [
    'Site Boundary',
    'Column Marking',
    'Footing',
    'Grade Beam',
    'Plinth',
    'Ground Floor',
    'First Floor',
    'Roof',
    'Brick Work',
    'Electrical',
    'Plumbing',
    'Painting',
    'Wood Work',
    'False Ceiling',
    'Flooring',
    'Finishing',
    'Handover',
  ];

  final List<String> _drawingItems = [
    'Working Drawing',
    'Floor Plan',
    'Section',
    'Elevation',
    'Compound Wall',
    'Gate Design',
    'Electrical',
    'Plumbing',
    '3D Interior',
    '3D Exterior',
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
    
    List<dynamic> emps = [];
    try {
      emps = await ApiService.getEmployees();
    } catch (e) {
      debugPrint("JayaHomeView: Failed to load employees: $e");
    }
    
    final attStats = await ApiService.getAttendanceDashboardStats();

    if (mounted) {
      setState(() {
        _attendance = att;
        _clients = cli;
        _invoices = inv;
        _announcements = anns;
        _tasks = tsk;
        _projects = projs;
        _employees = emps
            .where(
              (e) => e['role'] != 'Client' && e['role'] != 'Managing Director',
            )
            .toList();
        _pendingPayments = inv.where((i) => i['status'] != 'Paid').length;
        _attendanceStats = attStats['stats'];
        _loading = false;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_assignProjectId == null ||
        _assignUserId == null ||
        _assignChecklist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select Project, Staff, and Working Checklist Item.',
          ),
        ),
      );
      return;
    }

    final selectedProj = _projects.firstWhere(
      (p) => p['id'] == _assignProjectId,
    );
    final selectedClient = _clients.firstWhere(
      (c) => c['id'] == selectedProj['clientId'],
      orElse: () => {'name': 'Client'},
    );

    final descriptionObj = {
      'clientName': selectedClient['name'] ?? 'Client',
      'projectName': selectedProj['name'] ?? 'Project',
      'checklist': _assignChecklist,
      'drawing': _assignDrawing ?? 'None',
      'expectedCompletion': _assignTimeCtrl.text,
      'notes': _assignNotesCtrl.text.isEmpty
          ? 'Daily Work Assignment'
          : _assignNotesCtrl.text,
    };

    final success = await ApiService.createTask({
      'title': 'Daily Work: $_assignChecklist',
      'description': jsonEncode(descriptionObj),
      'projectId': _assignProjectId,
      'assignedTo': _assignUserId,
      'priority': _assignPriority,
      'dueDate': _assignDueDateCtrl.text,
      'status': 'Pending',
    });

    if (success) {
      _assignNotesCtrl.clear();
      setState(() {
        _assignChecklist = null;
        _assignDrawing = null;
      });
      _loadJayaData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Work assignment successfully saved and dispatched to Staff.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save work assignment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Office Administration Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
            ),
          ),
          const Text(
            'Jaya Home Screen: Clients, Accounts, Tasks & Operations',
            style: TextStyle(color: Color(0xFF70707C)),
          ),
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
                  VianMetricCard(
                    title: 'TOTAL CLIENTS',
                    value: _clients.length.toString(),
                    icon: Icons.people,
                  ),
                  VianMetricCard(
                    title: "TODAY'S ATTENDANCE",
                    value: _attendance.length.toString(),
                    icon: Icons.calendar_month,
                    iconColor: VianTheme.success,
                  ),
                  VianMetricCard(
                    title: 'UNPAID INVOICES',
                    value: _pendingPayments.toString(),
                    icon: Icons.receipt,
                    iconColor: VianTheme.danger,
                  ),
                  VianMetricCard(
                    title: 'TOTAL REVENUE INVOICED',
                    value: formatter.format(
                      _invoices.fold(
                        0.0,
                        (acc, item) => acc + safeToDouble(item['total']),
                      ),
                    ),
                    icon: Icons.payments,
                    iconColor: VianTheme.primaryGold,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'GPS GEOFENCE SECURITY & BIOMETRICS STATUS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
              letterSpacing: 0.5,
            ),
          ),
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
                  VianMetricCard(
                    title: 'EMPLOYEES OUTSIDE SITE',
                    value: '${_attendanceStats?['employeesOutsideSite'] ?? 0}',
                    icon: Icons.person_pin_circle_outlined,
                    iconColor: VianTheme.danger,
                  ),
                  VianMetricCard(
                    title: 'PENDING APPROVALS',
                    value:
                        '${_attendanceStats?['pendingAttendanceApproval'] ?? 0}',
                    icon: Icons.pending_actions_outlined,
                    iconColor: VianTheme.warning,
                  ),
                  VianMetricCard(
                    title: 'GPS BOUNDARY FAILURES',
                    value: '${_attendanceStats?['gpsFailures'] ?? 0}',
                    icon: Icons.gps_off_outlined,
                    iconColor: VianTheme.danger,
                  ),
                  VianMetricCard(
                    title: 'FACE MATCH FAILURES',
                    value: '${_attendanceStats?['faceFailures'] ?? 0}',
                    icon: Icons.face_unlock_outlined,
                    iconColor: VianTheme.danger,
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
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CLIENT METADATA DIRECTORY',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: VianTheme.primaryGold,
                                ),
                              ),
                              VianButton(
                                text: 'Onboard Wizard',
                                onPressed: () {},
                                isSecondary: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _clients.length > 3
                                ? 3
                                : _clients.length,
                            itemBuilder: (context, idx) {
                              final cli = _clients[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFF1F5F9),
                                  child: Icon(
                                    Icons.person,
                                    color: VianTheme.primaryGold,
                                  ),
                                ),
                                title: Text(cli['name'] ?? ''),
                                subtitle: Text(
                                  'Phone: ${cli['phone']} | Email: ${cli['email']}',
                                ),
                                trailing: Text(
                                  cli['gst'] != null
                                      ? 'GST: ${cli['gst']}'
                                      : 'No GST',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: VianTheme.lightText,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECENT INVOICES & PAYMENTS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invoices.length > 3
                                ? 3
                                : _invoices.length,
                            itemBuilder: (context, idx) {
                              final inv = _invoices[idx];
                              final isPaid = inv['status'] == 'Paid';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invoice #${inv['invoiceNumber']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${formatter.format(safeToDouble(inv['total']))}',
                                          style: const TextStyle(
                                            color: VianTheme.lightText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? const Color(0x3328A745)
                                            : const Color(0x33DC3545),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        inv['status'] ?? 'Draft',
                                        style: TextStyle(
                                          color: isPaid
                                              ? VianTheme.success
                                              : VianTheme.danger,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
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
                          const Text(
                            'ASSIGNED OFFICE TASKS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
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
                                  subtitle: Text(
                                    'Due: ${task['dueDate']} | Assignee: ${task['assignee']?['name'] ?? 'Unassigned'}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  trailing: Icon(
                                    task['status'] == 'Completed'
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: task['status'] == 'Completed'
                                        ? VianTheme.success
                                        : VianTheme.primaryGold,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECENT ANNOUNCEMENTS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length > 3
                                ? 3
                                : _announcements.length,
                            itemBuilder: (context, idx) {
                              final ann = _announcements[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ann['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ann['message'] ?? '',
                                      style: const TextStyle(
                                        color: VianTheme.lightText,
                                        fontSize: 10,
                                      ),
                                    ),
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

  Widget _buildDailyAssignmentForm() {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY WORK ASSIGNMENT DISPATCHER',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<dynamic>(
            value: _assignProjectId,
            dropdownColor: VianTheme.headerBlack,
            decoration: const InputDecoration(
              labelText: 'Select Project & Client',
            ),
            items: _projects.map((p) {
              return DropdownMenuItem<dynamic>(
                value: p['id'],
                child: Text(
                  '${p['name']} (Client ID: ${p['clientId']})',
                  style: const TextStyle(fontSize: 12),
                ),
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
                  decoration: const InputDecoration(
                    labelText: 'Working Checklist Item',
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Drawing Reference (Optional)',
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Assign Staff / Engineer',
                  ),
                  items: _employees.map((e) {
                    return DropdownMenuItem<dynamic>(
                      value: e['id'],
                      child: Text(
                        '${e['name']} (${e['role']})',
                        style: const TextStyle(fontSize: 12),
                      ),
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
                  decoration: const InputDecoration(
                    labelText: 'Priority Level',
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Due Date (YYYY-MM-DD)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _assignTimeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Expected Completion Time',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _assignNotesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Task Instructions / Remarks',
            ),
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
    
    List<dynamic> emps = [];
    try {
      emps = await ApiService.getEmployees();
    } catch (e) {
      debugPrint("MuthuiyaHomeView: Failed to load employees: $e");
    }
    
    final projs = await ApiService.getProjects();

    List<dynamic> drawList = [];
    if (projs.isNotEmpty && projs.first['id'] != null) {
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
    final designTeam = _employees
        .where((e) => e['username'] == 'gokul' || e['username'] == 'sivaraman')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Design & Architecture Command Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
            ),
          ),
          const Text(
            'Muthuiya Home Screen: Design Review, Blueprints, Team Attendance',
            style: TextStyle(color: Color(0xFF70707C)),
          ),
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
                  VianMetricCard(
                    title: 'PENDING DRAWINGS APPROVAL',
                    value: _drawings
                        .where((d) => d['status'] == 'Pending')
                        .length
                        .toString(),
                    icon: Icons.layers,
                    iconColor: VianTheme.primaryGold,
                  ),
                  VianMetricCard(
                    title: 'DESIGN TEAM SIZE',
                    value: designTeam.length.toString(),
                    icon: Icons.people,
                  ),
                  VianMetricCard(
                    title: 'ACTIVE PROJECTS',
                    value: _projects.length.toString(),
                    icon: Icons.architecture,
                    iconColor: VianTheme.success,
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
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DRAWINGS APPROVAL QUEUE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_drawings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'No drawings uploaded yet.',
                                  style: TextStyle(color: VianTheme.lightText),
                                ),
                              ),
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
                                    leading: const Icon(
                                      Icons.picture_as_pdf,
                                      color: VianTheme.primaryGold,
                                    ),
                                    title: Text(d['title'] ?? ''),
                                    subtitle: Text(
                                      'Type: ${d['type']} | Version: ${d['version']} | Status: ${d['status']}',
                                    ),
                                    trailing: d['status'] == 'Pending'
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: VianTheme.success,
                                                ),
                                                onPressed: () async {
                                                  await ApiService.approveDrawing(
                                                    d['id'],
                                                    'Approved',
                                                  );
                                                  setState(
                                                    () => _loading = true,
                                                  );
                                                  _loadMuthuiyaData();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: VianTheme.danger,
                                                ),
                                                onPressed: () async {
                                                  await ApiService.approveDrawing(
                                                    d['id'],
                                                    'Rejected',
                                                  );
                                                  setState(
                                                    () => _loading = true,
                                                  );
                                                  _loadMuthuiyaData();
                                                },
                                              ),
                                            ],
                                          )
                                        : Text(
                                            d['status'] ?? '',
                                            style: TextStyle(
                                              color: d['status'] == 'Approved'
                                                  ? VianTheme.success
                                                  : VianTheme.danger,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DESIGN TEAM ATTENDANCE STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: designTeam.length,
                            itemBuilder: (context, idx) {
                              final member = designTeam[idx];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFF1F5F9),
                                  child: Icon(
                                    Icons.person,
                                    color: VianTheme.primaryGold,
                                  ),
                                ),
                                title: Text(member['name'] ?? ''),
                                subtitle: Text('Role: ${member['role']}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x3328A745),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Checked In',
                                    style: TextStyle(
                                      color: VianTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DESIGN & CREATIVE TASKS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
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
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task['title'] ?? ''),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Assignee: ${task['assignee']?['name'] ?? 'Unassigned'} | Due: ${task['dueDate']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: VianTheme.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROJECT PROGRESS METRICS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          proj['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${proj['progressPercentage']}%',
                                          style: const TextStyle(
                                            color: VianTheme.primaryGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value:
                                          (proj['progressPercentage'] ?? 0) /
                                          100.0,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      valueColor: const AlwaysStoppedAnimation(
                                        VianTheme.primaryGold,
                                      ),
                                    ),
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
}

// ==========================================
// 4. SITE MANAGER DASHBOARD VIEW (Murugan Home)
// ==========================================
class SiteManagerDashboardView extends StatefulWidget {
  const SiteManagerDashboardView({Key? key}) : super(key: key);

  @override
  State<SiteManagerDashboardView> createState() =>
      _SiteManagerDashboardViewState();
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
    if (_projects.isNotEmpty && _projects.first['id'] != null) {
      _selectedProjectId = _projects.first['id'];
      final res = await ApiService.getWorkersAttendance(_selectedProjectId!);
      _workers = res['workers'] ?? [];
      _attendance = res['attendance'] ?? [];

      for (final w in _workers) {
        _workerStatus[w['id']] = 'Present';
        _workerRemarks[w['id']] = 'Standard shift';
        _workerOt[w['id']] = 0.0;
      }

      final progressData = await ApiService.getHourlyProgress(
        _selectedProjectId!,
      );
      _hourlyProgressList = progressData;
    } else {
      _selectedProjectId = null;
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
        'remarks': _workerRemarks[key] ?? '',
      });
    });

    final res = await ApiService.submitLabourAttendance(
      submitList,
      '28.4595, 77.0266',
      DateTime.now().toString().split(' ').first,
    );
    if (!res['success'] && res['message'] != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text(
            'ATTENDANCE RECORDED',
            style: TextStyle(color: VianTheme.danger),
          ),
          content: Text(
            res['message'] ?? 'Attendance already recorded for today.',
          ),
          actions: [
            VianButton(
              text: 'Close',
              isSecondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance recorded successfully!')),
      );
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
      'photoUrls': [],
    };

    await ApiService.submitHourlyProgress(data);
    _hourlyProgressCtrl.clear();
    _hourlyRemarksCtrl.clear();
    _hourlyMaterialsCtrl.clear();
    _hourlyDelayCtrl.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hourly progress uploaded!')));
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
          const Text(
            'Site Operations Command Center',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
            ),
          ),
          const Text(
            'Murugan Home Screen: Workers Attendance, GPS, Hourly Progress Logs',
            style: TextStyle(color: Color(0xFF70707C)),
          ),
          const SizedBox(height: 24),
          if (_selectedProjectId == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: VianTheme.primaryGold.withOpacity(0.08),
                border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: VianTheme.primaryGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No active site project assigned to your profile. Please contact an Administrator to assign a project.',
                      style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          VianMetricCard(
            title: 'LABOUR ON-SITE TODAY',
            value: _workers.length.toString(),
            icon: Icons.engineering,
            iconColor: VianTheme.success,
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
                              const Text(
                                'LABOUR MANUAL ATTENDANCE WIZARD',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: VianTheme.primaryGold,
                                ),
                              ),
                              VianButton(
                                text: 'Submit Attendance',
                                onPressed: _submitManualAttendance,
                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            worker['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Skill: ${worker['skillType']} | Wage: ₹${worker['dailyWage']}',
                                            style: const TextStyle(
                                              color: VianTheme.lightText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: _workerStatus[id] ?? 'Present',
                                      dropdownColor: VianTheme.cardColor,
                                      items: ['Present', 'Absent', 'Half Day']
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  color: VianTheme.headerBlack,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => _workerStatus[id] = val!,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 60,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'OT Hrs',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => _workerOt[id] =
                                            double.tryParse(val) ?? 0.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Remarks',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        onChanged: (val) =>
                                            _workerRemarks[id] = val,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    VianCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SUBMIT HOURLY PROGRESS REPORT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hourlyProgressCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Work Progress Details',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hourlyRemarksCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Remarks',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hourlyWorkersCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Workers Present',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hourlyPercentageCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Completion %',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hourlyWeatherCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Weather',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hourlyMaterialsCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Materials Used',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hourlyDelayCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Delay Reason (optional)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          VianButton(
                            text: 'Upload Site Progress',
                            onPressed: _submitHourlyProgressReport,
                          ),
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
                          const Text(
                            'HOURLY PROGRESS LOGS TODAY',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_hourlyProgressList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'No hourly logs submitted today.',
                                  style: TextStyle(color: VianTheme.lightText),
                                ),
                              ),
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
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log['user']?['name'] ?? 'Engineer',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: VianTheme.headerBlack,
                                            ),
                                          ),
                                          Text(
                                            '${log['completionPercentage']}% Complete',
                                            style: const TextStyle(
                                              color: VianTheme.primaryGold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log['workProgress'] ?? '',
                                        style: const TextStyle(
                                          color: VianTheme.headerBlack,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (log['remarks'] != null &&
                                          log['remarks'].toString().isNotEmpty)
                                        Text(
                                          'Note: ${log['remarks']}',
                                          style: const TextStyle(
                                            color: VianTheme.lightText,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
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
      if (a['userId'] == ApiService.currentUser?['id'] &&
          a['date'] == todayStr) {
        myTodayAtt = a;
        break;
      }
    }
    final hasCheckedIn =
        myTodayAtt != null && myTodayAtt['checkOutTime'] == null;

    if (projs.isNotEmpty && projs.first['id'] != null) {
      _selectedProjectId = projs.first['id'];
    } else {
      _selectedProjectId = null;
    }

    if (mounted) {
      setState(() {
        _projects = projs;
        _tasks = tsk;
        _announcements = anns;
        _checkedIn = hasCheckedIn;
        _fines =
            (finesData['fines'] as List<dynamic>?)
                ?.where((f) => f['employeeId'] == ApiService.currentUser?['id'])
                .toList() ??
            [];
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
      'notes': _notesCtrl.text,
    };

    await ApiService.submitDailyReport(data);
    _workReportCtrl.clear();
    _quantityCompletedCtrl.clear();
    _notesCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('EOD Report submitted successfully!')),
    );
  }

  void _showPhotoUploadModal(String slotName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: Text(
          'Upload 5 Photos - Slot: $slotName',
          style: const TextStyle(color: VianTheme.primaryGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload 5 geofenced site photos for this progress audit slot.',
              style: TextStyle(color: VianTheme.lightText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: VianTheme.primaryGold, size: 36),
                    Text(
                      '5 Photos Selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: VianTheme.headerBlack,
                      ),
                    ),
                    Text(
                      'GPS: 28.4630° N, 77.0300° E',
                      style: TextStyle(
                        fontSize: 10,
                        color: VianTheme.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Short progress remarks description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
                  'https://images.unsplash.com/photo-1503387762-592ded58c454?auto=format&fit=crop&w=800&q=80',
                ]),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully uploaded photos for slot $slotName.',
                  ),
                ),
              );
              _loadEmployeeData();
            },
          ),
        ],
      ),
    );
  }

  void _showPendingWorkModal(dynamic task) {
    String selectedReason = 'Material Delay';
    final dateCtrl = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 2))
          .toString()
          .split(' ')
          .first,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: const Text(
            'Report Pending Work / Delay Reason',
            style: TextStyle(color: VianTheme.primaryGold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                dropdownColor: VianTheme.cardColor,
                decoration: const InputDecoration(
                  labelText: 'Reason for Delay',
                ),
                items:
                    [
                          'Material Delay',
                          'Rain',
                          'Labour Issue',
                          'Client Delay',
                          'Site Closed',
                          'Other',
                        ]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(
                                color: VianTheme.headerBlack,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  setModalState(() {
                    selectedReason = val!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expected Completion Date (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            VianButton(
              text: 'Submit Delay Report',
              onPressed: () async {
                await ApiService.updateTask(task['id'], {
                  'status': 'Pending',
                  'description':
                      '${task['description']}\n\n[DELAY REPORTED] Reason: $selectedReason | New Expected Completion: ${dateCtrl.text}',
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Delay reason submitted. MD and Admin notified.',
                    ),
                  ),
                );
                _loadEmployeeData();
              },
            ),
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
          const Text(
            'DAILY PROGRESS PHOTO UPLOADS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: VianTheme.primaryGold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload 5 site photos for each designated hourly slot. Captures location automatically.',
            style: TextStyle(color: Color(0xFF70707C), fontSize: 11),
          ),
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
                    Text(
                      slot['time']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: VianTheme.headerBlack,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VianTheme.primaryGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onPressed: () {
                            _showPhotoUploadModal(slot['slot']!);
                          },
                          icon: const Icon(Icons.camera_alt, size: 12),
                          label: const Text(
                            'Upload',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
                  Text(
                    'Welcome, ${ApiService.currentUser?['name'] ?? 'Employee'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: VianTheme.primaryGold,
                    ),
                  ),
                  const Text(
                    'Employee Workspace: GPS Attendance, Tasks, EOD reporting',
                    style: TextStyle(color: Color(0xFF70707C)),
                  ),
                ],
              ),
              VianButton(
                text: _checkedIn ? 'Check Out' : 'GPS Check In',
                color: _checkedIn ? VianTheme.danger : VianTheme.success,
                onPressed: _checkedIn ? _triggerCheckOut : _triggerCheckIn,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_activeWarning != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x33DC3545),
                border: Border.all(color: VianTheme.danger),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: VianTheme.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'WARNING: You have left the project area geofence! Supervisors notified in ${_activeWarning!['duration']} minutes.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
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
                          const Text(
                            'YOUR ASSIGNED TASKS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            itemBuilder: (context, idx) {
                              final task = _tasks[idx];
                              Map<String, dynamic>? meta;
                              try {
                                if (task['description'] != null &&
                                    task['description'].toString().startsWith(
                                      '{',
                                    )) {
                                  meta = jsonDecode(
                                    task['description'].toString(),
                                  );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isCompleted
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: VianTheme.primaryGold,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              task['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: VianTheme.headerBlack,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? const Color(0x3328A745)
                                                  : const Color(0x33FFC107),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              task['status'] ?? 'Pending',
                                              style: TextStyle(
                                                color: isCompleted
                                                    ? VianTheme.success
                                                    : VianTheme.primaryGold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (meta != null) ...[
                                        Text(
                                          'Client: ${meta['clientName']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.headerBlack,
                                          ),
                                        ),
                                        Text(
                                          'Project: ${meta['projectName']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.headerBlack,
                                          ),
                                        ),
                                        Text(
                                          'Checklist: ${meta['checklist']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.primaryGold,
                                          ),
                                        ),
                                        Text(
                                          'Drawing: ${meta['drawing']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.lightText,
                                          ),
                                        ),
                                        Text(
                                          'Expected Completion: ${meta['expectedCompletion']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.danger,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Instructions: ${meta['notes']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: VianTheme.lightText,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          task['description'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: VianTheme.lightText,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        'Due Date: ${task['dueDate']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: VianTheme.lightText,
                                        ),
                                      ),
                                      if (!isCompleted) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 14,
                                                color: VianTheme.danger,
                                              ),
                                              label: const Text(
                                                'Report Delay',
                                                style: TextStyle(
                                                  color: VianTheme.danger,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _showPendingWorkModal(task),
                                            ),
                                            const SizedBox(width: 12),
                                            VianButton(
                                              text: 'Mark Complete',
                                              onPressed: () async {
                                                await ApiService.updateTaskStatus(
                                                  task['id'],
                                                  'Completed',
                                                );
                                                _loadEmployeeData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
                          const Text(
                            'SUBMIT DAILY EOD WORK REPORT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  dropdownColor: VianTheme.headerBlack,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                  ),
                                  items:
                                      [
                                            'Brick Work',
                                            'Painting',
                                            'Interior Design',
                                            'Plumbing',
                                            'Electrical',
                                            'Site Audit',
                                          ]
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCategory = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _quantityCompletedCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity (e.g. 1200 Sq Ft)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _workReportCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Work Description',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Special Notes / Issues faced',
                            ),
                          ),
                          const SizedBox(height: 16),
                          VianButton(
                            text: 'Submit EOD Report',
                            onPressed: _submitEodReport,
                          ),
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
                    if (_fines.isNotEmpty) ...[
                      VianCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR ACTIVE FINES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: VianTheme.danger,
                              ),
                            ),
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
                                    title: Text(
                                      'Fine Amount: ₹${f['amount']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(f['reason'] ?? ''),
                                    trailing: isAck
                                        ? const Text(
                                            'Acknowledged',
                                            style: TextStyle(
                                              color: VianTheme.success,
                                              fontSize: 11,
                                            ),
                                          )
                                        : VianButton(
                                            text: 'Acknowledge',
                                            onPressed: () async {
                                              await ApiService.acknowledgeFine(
                                                f['id'],
                                              );
                                              _loadEmployeeData();
                                            },
                                          ),
                                  ),
                                );
                              },
                            ),
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
                            const Text(
                              'YOUR MONTHLY INCENTIVE STATUS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: VianTheme.primaryGold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Performance Score:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${safeToDouble(_myIncentive!['totalScore']).toStringAsFixed(1)} / 100',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Suggested Incentive:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${safeToDouble(_myIncentive!['suggestedAmount']).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Approved Payout:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${safeToDouble(_myIncentive!['finalAmount']).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Status:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                _statusTag(_myIncentive!['status'] ?? 'Draft'),
                              ],
                            ),
                            if (_myIncentive!['adminRemarks'] != null &&
                                _myIncentive!['adminRemarks']
                                    .toString()
                                    .isNotEmpty) ...[
                              const Divider(color: Colors.white10),
                              const Text(
                                'Admin Remarks:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: VianTheme.primaryGold,
                                ),
                              ),
                              Text(
                                _myIncentive!['adminRemarks'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            if (_myIncentive!['superAdminRemarks'] != null &&
                                _myIncentive!['superAdminRemarks']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Management Remarks:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: VianTheme.primaryGold,
                                ),
                              ),
                              Text(
                                _myIncentive!['superAdminRemarks'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
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
                          const Text(
                            'COMPANY ANNOUNCEMENTS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _announcements.length > 2
                                ? 2
                                : _announcements.length,
                            itemBuilder: (context, idx) {
                              final ann = _announcements[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ann['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ann['message'] ?? '',
                                      style: const TextStyle(
                                        color: VianTheme.lightText,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        VianButton(
                                          text: 'Acknowledge',
                                          isSecondary: true,
                                          onPressed: () async {
                                            await ApiService.acknowledgeAnnouncement(
                                              ann['id'],
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Announcement acknowledged.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
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
      child: Text(
        status,
        style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold),
      ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF70707C)),
        ),
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
  List<dynamic> _projects = [];
  Map<String, dynamic>? _selectedProject;

  // Project Detail Tab state: 0 = Photos, 1 = Updates, 2 = Documents
  int _detailTab = 0;
  bool _loadingDetails = false;
  List<dynamic> _projectPhotos = [];
  List<dynamic> _projectUpdates = [];
  List<dynamic> _projectDocs = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getClientProjects();
      if (mounted) {
        setState(() {
          _projects = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectProject(Map<String, dynamic> project) async {
    setState(() {
      _selectedProject = project;
      _loadingDetails = true;
      _detailTab = 0;
    });

    final int pId = safeToInt(project['id']);
    try {
      final photos = await ApiService.getProjectPhotos(pId);
      final updates = await ApiService.getProjectUpdates(pId);
      List<dynamic> docs = [];
      try {
        docs = await ApiService.getDocuments(pId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _projectPhotos = photos;
          _projectUpdates = updates;
          _projectDocs = docs;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  String _resolvePhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final String serverBase = ApiService.baseUrl.replaceAll('/api', '');
    return '$serverBase$rawUrl';
  }

  void _showPhotoPreviewDialog(Map<String, dynamic> photo) {
    final String fullUrl = _resolvePhotoUrl(photo['url'] ?? photo['thumbnailUrl']);
    final String category = photo['category'] ?? 'Site Progress';
    final String description = photo['description'] ?? '';
    final String createdAt = photo['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(photo['createdAt'].toString()) ?? DateTime.now())
        : 'Recently uploaded';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: VianTheme.headerBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VianTheme.primaryGold, width: 1),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: VianTheme.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: VianTheme.primaryGold.withOpacity(0.5)),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: VianTheme.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          createdAt,
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Image display
              Flexible(
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: VianTheme.primaryGold),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to load photo preview',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Description Footer
              if (description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16161E),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Text(
                    description,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: VianTheme.headerBlack,
        body: Center(
          child: CircularProgressIndicator(color: VianTheme.primaryGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VianTheme.headerBlack,
      body: _selectedProject == null ? _buildDashboardView() : _buildProjectDetailView(),
    );
  }

  // ==========================================
  // 1. DASHBOARD VIEW: MY PROJECTS
  // ==========================================
  Widget _buildDashboardView() {
    final clientName = ApiService.currentUser?['name'] ?? 'Client';
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: VianTheme.primaryGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VianTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 24 : 30,
                    backgroundColor: VianTheme.primaryGold.withOpacity(0.15),
                    child: const Icon(Icons.person_outline, color: VianTheme.primaryGold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $clientName',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your architectural progress, view on-site photos, and monitor updates.',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'MY PROJECTS',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_projects.length} Assigned',
                  style: GoogleFonts.inter(
                    color: VianTheme.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Empty State
            if (_projects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: VianTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_work_outlined, color: Colors.white38, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'No Projects Assigned Yet',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your project will appear here once your architect or site engineer links it to your account.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              // Projects Grid / List
              LayoutBuilder(
                builder: (context, constraints) {
                  final int crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 1.3 : 1.25,
                    ),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final proj = _projects[index];
                      return _buildProjectCard(proj);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Project Card
  Widget _buildProjectCard(Map<String, dynamic> proj) {
    final String name = proj['name'] ?? 'Project';
    final String location = proj['siteAddress'] ?? proj['location'] ?? 'Site Location Specified';
    final int progress = safeToInt(proj['progressPercentage'] ?? 0);
    final String status = proj['status'] ?? 'In Progress';
    final photosList = proj['photos'] as List<dynamic>? ?? [];
    final updatesList = proj['updates'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VianTheme.primaryGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: VianTheme.primaryGold.withOpacity(0.4)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: VianTheme.primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Progress Bar & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Construction Progress',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$progress%',
                style: GoogleFonts.outfit(
                  color: VianTheme.primaryGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
            ),
          ),
          const SizedBox(height: 14),

          // Photos & Updates count
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${photosList.length} Photos',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.update, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${updatesList.length} Updates',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View Project Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VianTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text(
                'VIEW PROJECT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              onPressed: () => _selectProject(proj),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. CLIENT PROJECT PAGE (Section 10, 16, 17, 19)
  // ==========================================
  Widget _buildProjectDetailView() {
    final proj = _selectedProject!;
    final String name = proj['name'] ?? 'Project Details';
    final String location = proj['siteAddress'] ?? proj['location'] ?? 'Site Location Specified';
    final String status = proj['status'] ?? 'In Progress';
    final int progress = safeToInt(proj['progressPercentage'] ?? 0);
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 32.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: VianTheme.primaryGold,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              'Back to My Projects',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: () => setState(() => _selectedProject = null),
          ),
          const SizedBox(height: 16),

          // Project Banner Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VianTheme.primaryGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: VianTheme.primaryGold),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: VianTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white60, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Construction Completion',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '$progress% Complete',
                      style: GoogleFonts.outfit(
                        color: VianTheme.primaryGold,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (progress / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detail Section Tabs: Photos | Updates | Documents
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Photos (${_projectPhotos.length})', Icons.photo_library_outlined),
                _buildTabButton(1, 'Updates (${_projectUpdates.length})', Icons.campaign_outlined),
                _buildTabButton(2, 'Documents (${_projectDocs.length})', Icons.folder_open_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_loadingDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(color: VianTheme.primaryGold),
              ),
            )
          else if (_detailTab == 0)
            _buildPhotosTab()
          else if (_detailTab == 1)
            _buildUpdatesTab()
          else
            _buildDocumentsTab(),
        ],
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, String title, IconData icon) {
    final bool active = _detailTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _detailTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? VianTheme.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.black : Colors.white70),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: active ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 1: Photos Gallery (Clean Read-Only for Clients)
  Widget _buildPhotosTab() {
    if (_projectPhotos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: VianTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.photo_camera_back_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'No Project Photos Yet',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Site progress photos uploaded by your management team will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 650 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
          ),
          itemCount: _projectPhotos.length,
          itemBuilder: (context, index) {
            final photo = _projectPhotos[index];
            final String url = _resolvePhotoUrl(photo['thumbnailUrl'] ?? photo['url']);
            final String category = photo['category'] ?? 'Site Progress';

            return InkWell(
              onTap: () => _showPhotoPreviewDialog(photo),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: VianTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: VianTheme.primaryGold),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 36),
                      ),
                    ),
                    // Bottom gradient badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: GoogleFonts.outfit(
                                color: VianTheme.primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.fullscreen, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Tab 2: Updates Timeline (Clean Chronological Feed)
  Widget _buildUpdatesTab() {
    if (_projectUpdates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: VianTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.campaign_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'No Project Updates Yet',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Site milestones and progress announcements will be published here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _projectUpdates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final update = _projectUpdates[index];
        final String message = update['message'] ?? '';
        final int progress = safeToInt(update['progressPercentage'] ?? 0);
        final String dateStr = update['createdAt'] != null
            ? DateFormat('dd MMMM yyyy').format(DateTime.tryParse(update['createdAt'].toString()) ?? DateTime.now())
            : 'Recent';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: VianTheme.primaryGold, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (progress > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: VianTheme.primaryGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: VianTheme.primaryGold.withOpacity(0.5)),
                      ),
                      child: Text(
                        '$progress% Complete',
                        style: GoogleFonts.outfit(
                          color: VianTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab 3: Documents (Read/Download for Authorized Client)
  Widget _buildDocumentsTab() {
    if (_projectDocs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: VianTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_open_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'No Documents Uploaded Yet',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Drawings, agreements, and specifications will be accessible here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _projectDocs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _projectDocs[index];
        final String title = doc['title'] ?? doc['name'] ?? 'Project Document';
        final String category = doc['category'] ?? 'Drawing';
        final String fileUrl = _resolvePhotoUrl(doc['fileUrl'] ?? doc['url']);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VianTheme.primaryGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.description_outlined, color: VianTheme.primaryGold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (fileUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: VianTheme.primaryGold, size: 20),
                  tooltip: 'Open Document',
                  onPressed: () {
                    // Open document
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
