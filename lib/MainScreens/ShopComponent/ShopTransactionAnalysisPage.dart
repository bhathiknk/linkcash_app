// lib/pages/shop_transaction_analysis_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config.dart';

enum ChartType { bar, line }

class ShopTransactionAnalysisPage extends StatefulWidget {
  final int userId;
  const ShopTransactionAnalysisPage({Key? key, required this.userId})
      : super(key: key);

  @override
  State<ShopTransactionAnalysisPage> createState() =>
      _ShopTransactionAnalysisPageState();
}

class _ShopTransactionAnalysisPageState
    extends State<ShopTransactionAnalysisPage> with TickerProviderStateMixin {
  static const _autoRefreshSeconds = 30;
  late Future<List<ShopTxn>> _futureHistory;
  late final TabController _tabCtrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _futureHistory = _fetchHistory();
    _tabCtrl = TabController(length: 4, vsync: this);
    _timer = Timer.periodic(
      const Duration(seconds: _autoRefreshSeconds),
          (_) => setState(() => _futureHistory = _fetchHistory()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<List<ShopTxn>> _fetchHistory() async {
    final resp = await http.get(Uri.parse(
        '$baseUrl/api/shop-transactions/history/user/${widget.userId}'));
    if (resp.statusCode != 200) throw Exception('Failed to load');
    final List data = json.decode(resp.body);
    return data.map((e) => ShopTxn.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Shop Transaction Analysis'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFCCE4FF), const Color(0xFFE8F3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _futureHistory = _fetchHistory()),
          child: FutureBuilder<List<ShopTxn>>(
            future: _futureHistory,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              return SafeArea(child: _buildMainView(context, snap.data!, isDark));
            },
          ),
        ),
      ),
    );
  }

  // ===================  MAIN VIEW  =================== //
  Widget _buildMainView(BuildContext ctx, List<ShopTxn> hist, bool isDark) {
    final st = _aggregate(hist);
    return Column(
      children: [
        const SizedBox(height: kToolbarHeight + 16),
        _summaryRow(st),
        const SizedBox(height: 24),
        _tabBar(isDark),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            physics: const BouncingScrollPhysics(),
            children: [
              _chartPage(ctx, 'Last 7 Days (Income)', st.last7Days,
                  ChartType.bar, true),
              _chartPage(ctx, 'Last 12 Months (Income)', st.last12Months,
                  ChartType.bar, true),
              _chartPage(ctx, 'Last 5 Years (Income)', st.last5Years,
                  ChartType.bar, true),
              _chartPage(ctx, 'Monthly Transaction Count', st.last12Months,
                  ChartType.line, false),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Auto-refresh every 30 s • Pull to refresh',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ----------------  helpers  ---------------- //
  Widget _summaryRow(_Stats s) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      _chip('Today', s.todayTotal, Icons.today_rounded,
          const [Color(0xFF8E9BFF), Color(0xFF5568FF)]),
      const SizedBox(width: 12),
      _chip('This Month', s.monthTotal, Icons.calendar_month_rounded,
          const [Color(0xFF5EFCE8), Color(0xFF736EFE)]),
      const SizedBox(width: 12),
      _chip('This Year', s.yearTotal, Icons.timeline_rounded,
          const [Color(0xFFFFB75E), Color(0xFFED8F03)]),
    ]),
  );

  Widget _tabBar(bool isDark) => TabBar(
    controller: _tabCtrl,
    labelColor: isDark ? Colors.white : const Color(0xFF0054FF),
    unselectedLabelColor: Colors.grey,
    indicatorColor: isDark ? Colors.white : const Color(0xFF0054FF),
    tabs: const [
      Tab(text: '7 Days'),
      Tab(text: '12 Months'),
      Tab(text: '5 Years'),
      Tab(text: '# / Month'),
    ],
  );

  Widget _chip(String t, double v, IconData ic, List<Color> g) => Container(
    width: 125,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: g),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: g.last.withOpacity(.35),
            blurRadius: 10,
            offset: const Offset(0, 5))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ic, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(t,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w400)),
        Text('£${v.toStringAsFixed(2)}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    ),
  );

  // ===================  CHART  CARD  =================== //
  Widget _chartPage(BuildContext ctx, String title, List<ChartData> d,
      ChartType t, bool colourful) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Expanded(
                child: t == ChartType.bar
                    ? _bar(ctx, d, colourful)
                    : _line(d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================  BAR  =================== //
  Widget _bar(BuildContext ctx, List<ChartData> data, bool colourful) {
    final rawMax =
    data.isEmpty ? 0 : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = rawMax == 0 ? 1.0 : rawMax * 1.25;
    final palette = [
      const [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
      const [Color(0xFFFFA17F), Color(0xFFFFE29F)],
      const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
      const [Color(0xFF83F4EC), Color(0xFF63B5F6)],
      const [Color(0xFFF093FB), Color(0xFFBFA6FF)],
    ];
    final interval = (maxY / 4).clamp(1, double.infinity).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, r, __) => BarTooltipItem(
              '£${r.toY.toStringAsFixed(2)}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          touchCallback: (ev, resp) {
            if (!ev.isInterestedForInteractions ||
                resp == null ||
                resp.spot == null) return;
            final idx = resp.spot!.touchedBarGroupIndex;
            _showDetailPopup(ctx, data[idx]);
          },
        ),
        titlesData: _titles(data, showY: true),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(strokeWidth: .45, color: Colors.grey.shade300),
        ),
        barGroups: data.asMap().entries.map((e) {
          final grad = colourful
              ? LinearGradient(
              colors: palette[e.key % palette.length],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
              : const LinearGradient(
              colors: [Color(0xFF0054FF), Color(0xFF0054FF)]);
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
                toY: e.value.value,
                width: 18,
                borderRadius: BorderRadius.circular(6),
                gradient: grad)
          ]);
        }).toList(),
      ),
    );
  }

  // popup with single-point XY chart
  Future<void> _showDetailPopup(BuildContext ctx, ChartData cd) {
    final theme = Theme.of(ctx);
    return showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: theme.dialogBackgroundColor.withOpacity(.95),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 260,
          height: 260,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cd.label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Income: £${cd.value.toStringAsFixed(2)}',
                    style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 18),
                Expanded(
                  child: ScatterChart(
                    ScatterChartData(
                      minX: -1,
                      maxX: 1,
                      minY: 0,
                      maxY: cd.value * 1.2 + 1,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      scatterSpots: [
                        ScatterSpot(
                          0,
                          cd.value,
                          dotPainter: FlDotCirclePainter(
                            radius: 12,
                            color: const Color(0xFF0054FF),
                            strokeWidth: 0,
                            strokeColor: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================  LINE  =================== //
  Widget _line(List<ChartData> data) {
    final maxC =
    data.map((e) => e.count ?? 0).fold<int>(0, (p, c) => c > p ? c : p);
    final gCols = [const Color(0xFF0054FF), const Color(0xFF42A5F5)];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxC == 0 ? 1 : maxC * 1.25).toDouble(),
        titlesData: _titles(data, showY: true),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxC / 4).clamp(1, double.infinity).toDouble(),
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(strokeWidth: .45, color: Colors.grey.shade300),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries
                .map((e) => FlSpot(
                e.key.toDouble(), (e.value.count ?? 0).toDouble()))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(colors: gCols),
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gCols.map((c) => c.withOpacity(.25)).toList(),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ------------- axis labels ------------- //
  FlTitlesData _titles(List<ChartData> d, {bool showY = false}) => FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: showY,
        reservedSize: 40,
        getTitlesWidget: (v, _) =>
            Text('£${v.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
      ),
    ),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          return Text(
              i >= 0 && i < d.length ? d[i].label : '',
              style: const TextStyle(fontSize: 10));
        },
      ),
    ),
  );

  // ============ aggregation ============ //
  _Stats _aggregate(List<ShopTxn> h) {
    final now = DateTime.now();
    final keyToday = DateFormat('yyyy-MM-dd').format(now);
    double today = 0;
    final Map<String, double> d = {}, m = {}, y = {};
    final Map<String, int> mCnt = {};
    for (var t in h) {
      final day = DateFormat('yyyy-MM-dd').format(t.transactionCreatedAt);
      final mon = DateFormat('yyyy-MM').format(t.transactionCreatedAt);
      final yr = DateFormat('yyyy').format(t.transactionCreatedAt);
      d[day] = (d[day] ?? 0) + t.amount;
      m[mon] = (m[mon] ?? 0) + t.amount;
      y[yr] = (y[yr] ?? 0) + t.amount;
      mCnt[mon] = (mCnt[mon] ?? 0) + 1;
      if (day == keyToday) today += t.amount;
    }
    final last7 = List.generate(7, (i) {
      final dt = now.subtract(Duration(days: 6 - i));
      final k = DateFormat('yyyy-MM-dd').format(dt);
      return ChartData(label: DateFormat('EEE').format(dt), value: d[k] ?? 0);
    });
    final last12 = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - 11 + i);
      final k = DateFormat('yyyy-MM').format(dt);
      return ChartData(
          label: DateFormat('MMM').format(dt),
          value: m[k] ?? 0,
          count: mCnt[k] ?? 0);
    });
    final last5 = List.generate(5, (i) {
      final yr = (now.year - 4 + i).toString();
      return ChartData(label: yr, value: y[yr] ?? 0);
    });
    return _Stats(
        todayTotal: today,
        monthTotal: last12.fold(0, (s, e) => s + e.value),
        yearTotal: last5.fold(0, (s, e) => s + e.value),
        last7Days: last7,
        last12Months: last12,
        last5Years: last5);
  }
}

// ===================  MODELS  =================== //
class ChartData {
  final String label;
  final double value;
  final int? count;
  ChartData({required this.label, required this.value, this.count});
}

class ShopTxn {
  final int transactionId;
  final String stripeTransactionId;
  final double amount;
  final DateTime transactionCreatedAt;
  ShopTxn(
      {required this.transactionId,
        required this.stripeTransactionId,
        required this.amount,
        required this.transactionCreatedAt});
  factory ShopTxn.fromJson(Map<String, dynamic> j) => ShopTxn(
    transactionId: j['transactionId'],
    stripeTransactionId: j['stripeTransactionId'],
    amount: (j['amount'] as num).toDouble(),
    transactionCreatedAt: DateTime.parse(j['transactionCreatedAt']),
  );
}

class _Stats {
  final double todayTotal, monthTotal, yearTotal;
  final List<ChartData> last7Days, last12Months, last5Years;
  _Stats(
      {required this.todayTotal,
        required this.monthTotal,
        required this.yearTotal,
        required this.last7Days,
        required this.last12Months,
        required this.last5Years});
}
