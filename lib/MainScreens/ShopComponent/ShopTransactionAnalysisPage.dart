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
    final resp = await http.get(
      Uri.parse('$baseUrl/api/shop-transactions/history/user/${widget.userId}'),
    );
    if (resp.statusCode != 200) throw Exception('Failed to load');
    final List data = json.decode(resp.body);
    return data.map((e) => ShopTxn.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:Colors.white,
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
          onRefresh: () async => setState(() {
            _futureHistory = _fetchHistory();
          }),
          child: FutureBuilder<List<ShopTxn>>(
            future: _futureHistory,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              return SafeArea(
                child: _buildMainView(snap.data!, isDark),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Main UI ---------- //

  Widget _buildMainView(List<ShopTxn> history, bool isDark) {
    final stats = _aggregate(history);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: kToolbarHeight + 16), // clear AppBar shadow
        // --- summary chips ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _summaryChip(
                title: "Today",
                amount: stats.todayTotal,
                icon: Icons.today_rounded,
                gradient: const [Color(0xFF8E9BFF), Color(0xFF5568FF)],
              ),
              _chipSpacer(),
              _summaryChip(
                title: "This Month",
                amount: stats.monthTotal,
                icon: Icons.calendar_month_rounded,
                gradient: const [Color(0xFF5EFCE8), Color(0xFF736EFE)],
              ),
              _chipSpacer(),
              _summaryChip(
                title: "This Year",
                amount: stats.yearTotal,
                icon: Icons.timeline_rounded,
                gradient: const [Color(0xFFFFB75E), Color(0xFFED8F03)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // --- tabs ---
        TabBar(
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
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            physics: const BouncingScrollPhysics(),
            children: [
              _chartPage('Last 7 Days (Income)',
                  stats.last7Days, ChartType.bar, true),
              _chartPage('Last 12 Months (Income)',
                  stats.last12Months, ChartType.bar, true),
              _chartPage('Last 5 Years (Income)',
                  stats.last5Years, ChartType.bar, true),
              _chartPage('Monthly Transaction Count',
                  stats.last12Months, ChartType.line, false),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Auto-refresh every 30 s • Pull to refresh',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _chipSpacer() => const SizedBox(width: 12);

  // ---------- Summary Chip ---------- //

  Widget _summaryChip({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      width: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400)),
          Text('£${amount.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ---------- Chart wrapper ---------- //

  Widget _chartPage(
      String title, List<ChartData> d, ChartType t, bool colourfulBars) {
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
                  style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Expanded(
                child: t == ChartType.bar
                    ? _buildBarChart(d, colourfulBars)
                    : _buildLineChart(d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Charts ---------- //

  Widget _buildBarChart(List<ChartData> data, bool colourful) {
    final maxY = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25;

    final palette = [
      const [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
      const [Color(0xFFFFA17F), Color(0xFFFFE29F)],
      const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
      const [Color(0xFF83F4EC), Color(0xFF63B5F6)],
      const [Color(0xFFF093FB), Color(0xFFBFA6FF)],
    ];

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, r, __) => BarTooltipItem(
              '£${r.toY.toStringAsFixed(2)}',
              const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: _titles(data),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(strokeWidth: .45, color: Colors.grey.shade300),
        ),
        barGroups: data.asMap().entries.map((e) {
          final g = colourful
              ? LinearGradient(
              colors: palette[e.key % palette.length],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
              : const LinearGradient(
              colors: [Color(0xFF0054FF), Color(0xFF0054FF)]);
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                width: 18,
                borderRadius: BorderRadius.circular(6),
                gradient: g,
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(List<ChartData> data) {
    final maxC = data.map((e) => e.count ?? 0).fold<int>(0, (p, c) => c > p ? c : p);
    const gCols = [Color(0xFF0054FF), Color(0xFF42A5F5)];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxC == 0 ? 1 : maxC * 1.25).toDouble(),
        titlesData: _titles(data, showY: true),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxC / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(strokeWidth: .45, color: Colors.grey.shade300),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), (e.value.count ?? 0).toDouble()))
                .toList(),
            isCurved: true,
            gradient: const LinearGradient(colors: gCols),
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

  FlTitlesData _titles(List<ChartData> d, {bool showY = false}) {
    return FlTitlesData(
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
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
    );
  }

  // ---------- Aggregation ---------- //

  _Stats _aggregate(List<ShopTxn> h) {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    double todayTotal = 0;
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
      if (day == todayKey) todayTotal += t.amount;
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
      todayTotal: todayTotal,
      monthTotal: last12.fold(0, (s, e) => s + e.value),
      yearTotal: last5.fold(0, (s, e) => s + e.value),
      last7Days: last7,
      last12Months: last12,
      last5Years: last5,
    );
  }
}

// ---------- Data Models ---------- //

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
