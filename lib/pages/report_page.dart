import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:withfbase/widgets/home_header.dart';

// ====== CONFIG ======
// Events: isticmaal waqtiga dhabta ah ee event-ka
const String kEventsTimeField = 'startDateTime'; // IMPORTANT
const String kVenuesTimeField = 'createdAt';
const String kUsersTimeField = 'createdAt';

enum DateRangeMode { today, thisMonth, custom }

// ---------- Models ----------
class _TrendPoint {
  final DateTime day; // midnight
  final int count;
  _TrendPoint(this.day, this.count);
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _kHeaderHeight = 170;

  bool _loading = true;

  int _eventsCount = 0;
  int _venuesCount = 0;
  int _blacklistedUsersCount = 0;
  int _noShowEventsCount = 0;

  // CEO metrics
  int _approvedEvents = 0;
  int _rejectedEvents = 0;
  int _avgSeats = 0;
  Map<String, int> _categoryCounts = {};
  Map<String, int> _organizerCounts = {}; // <-- NEW (organizer/department)
  List<_TrendPoint> _eventsPerDay = [];

  // Date range
  DateRangeMode _mode = DateRangeMode.today;
  DateTime? _start; // inclusive
  DateTime? _end; // exclusive

  List<_StatItem> get _stats => [
    _StatItem('Events', _eventsCount, Icons.event),
    _StatItem('Approved', _approvedEvents, Icons.check_circle),
    _StatItem('Rejected', _rejectedEvents, Icons.cancel),
    _StatItem('No-Show Events', _noShowEventsCount, Icons.event_busy),
    _StatItem('Venues', _venuesCount, Icons.apartment),
    _StatItem('Avg Seats', _avgSeats, Icons.chair_alt),
    _StatItem('Blacklisted', _blacklistedUsersCount, Icons.block),
  ];

  @override
  void initState() {
    super.initState();
    _computePresetRange(_mode);
    _loadStats();
  }

  // ---------- Date Helpers ----------
  void _computePresetRange(DateRangeMode m) {
    final now = DateTime.now();
    if (m == DateRangeMode.today) {
      final start = DateTime(now.year, now.month, now.day);
      _start = start;
      _end = start.add(const Duration(days: 1));
    } else if (m == DateRangeMode.thisMonth) {
      final start = DateTime(now.year, now.month, 1);
      _start = start;
      _end = DateTime(now.year, now.month + 1, 1);
    } else {
      _start ??= DateTime(now.year, now.month, now.day);
      _end ??= _start!.add(const Duration(days: 1));
    }
  }

  String _rangeLabel() {
    if (_start == null || _end == null) return 'No range';
    final fmt = DateFormat('dd MMM yyyy');
    final s = fmt.format(_start!);
    final e = fmt.format(_end!.subtract(const Duration(seconds: 1)));
    return '$s — $e';
  }

  Query _applyRange(Query q, String timeField) {
    if (_start == null || _end == null) return q;
    return q
        .where(timeField, isGreaterThanOrEqualTo: Timestamp.fromDate(_start!))
        .where(timeField, isLessThan: Timestamp.fromDate(_end!));
  }

  // ---------- Aggregations ----------
  Future<int> _countAggregation(Query q) async {
    final agg = await q.count().get();
    return agg.count!;
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final fs = FirebaseFirestore.instance;
      final eventsCol = fs.collection('events');
      final venuesCol = fs.collection('venues');
      final usersCol = fs.collection('users');

      // Range queries
      final eventsQ = _applyRange(eventsCol, kEventsTimeField);
      final venuesQ = _applyRange(venuesCol, kVenuesTimeField);
      final blacklistQ = _applyRange(
        usersCol.where('blacklisted', isEqualTo: true),
        kUsersTimeField,
      );

      // ---- EVENTS: single fetch → compute all CEO metrics (no composite indexes) ----
      final eventsSnap = await eventsQ.limit(1000).get(); // adjust if needed
      final docs = eventsSnap.docs;

      int approved = 0, rejected = 0, noshow = 0;
      int totalSeats = 0;
      final cat = <String, int>{};
      final org = <String, int>{}; // organizer/department leaderboard
      final perDay = <DateTime, int>{};

      DateTime midnight(DateTime d) => DateTime(d.year, d.month, d.day);

      for (final d in docs) {
        final m = d.data() as Map<String, dynamic>?;

        final status = (m?['status'] ?? '').toString().toLowerCase().trim();
        if (status == 'approved') approved++;
        if (status == 'rejected') rejected++;
        if (status == 'no-show' || status == 'noshow') noshow++;

        // seats
        final seats =
            (m?['seats'] is int)
                ? (m?['seats'] as int)
                : int.tryParse('${m?['seats']}') ?? 0;
        totalSeats += seats;

        // categories
        final category = (m?['category'] ?? 'Other').toString().trim();
        cat[category] = (cat[category] ?? 0) + 1;

        // organizers / departments
        //  - doorbidi 'department' haddii aad leedahay; haddii kale isticmaal organizerName/email
        final dept = (m?['department'] ?? '').toString().trim();
        final orgName = (m?['organizerName'] ?? '').toString().trim();
        final orgEmail = (m?['organizerEmail'] ?? '').toString().trim();
        final key =
            dept.isNotEmpty
                ? 'Dept: $dept'
                : (orgName.isNotEmpty
                    ? orgName
                    : (orgEmail.isNotEmpty ? orgEmail : 'Unknown'));
        org[key] = (org[key] ?? 0) + 1;

        // trend
        final startTs = m?[kEventsTimeField] as Timestamp?;
        final start = startTs?.toDate();
        if (start != null) {
          final day = midnight(start);
          perDay[day] = (perDay[day] ?? 0) + 1;
        }
      }

      // Sort trend
      final trendDays = perDay.keys.toList()..sort();
      final trendPts =
          trendDays.map((d) => _TrendPoint(d, perDay[d]!)).toList();

      // other collections
      final venuesCount = await _countAggregation(venuesQ);
      final blacklisted = await _countAggregation(blacklistQ);

      if (!mounted) return;
      setState(() {
        _eventsCount = docs.length;
        _approvedEvents = approved;
        _rejectedEvents = rejected;
        _noShowEventsCount = noshow;
        _avgSeats = docs.isEmpty ? 0 : (totalSeats / docs.length).round();
        _categoryCounts = cat;
        _organizerCounts = org; // <-- NEW
        _eventsPerDay = trendPts;
        _venuesCount = venuesCount;
        _blacklistedUsersCount = blacklisted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load reports: $e')));
    }
  }

  Future<void> _pickCustomRange() async {
    final initial = DateTimeRange(
      start: _start ?? DateTime.now(),
      end: _end ?? DateTime.now().add(const Duration(days: 1)),
    );
    final res = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 1, 1),
      helpText: 'Select date range',
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            child: child!,
          ),
    );
    if (res != null) {
      setState(() {
        _mode = DateRangeMode.custom;
        _start = DateTime(res.start.year, res.start.month, res.start.day);
        _end = DateTime(
          res.end.year,
          res.end.month,
          res.end.day,
        ).add(const Duration(days: 1)); // exclusive
      });
      await _loadStats();
    }
  }

  // ---------- PDF ----------
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pw.Widget pdfBarChart() {
      final maxVal =
          (_stats.map((e) => e.value).fold<int>(0, math.max)).toDouble();
      final barColor = PdfColors.blue;

      return pw.Container(
        height: 180,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children:
              _stats.map((s) {
                final h = maxVal == 0 ? 0.0 : (s.value / maxVal) * 150.0;
                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(width: 30, height: h, color: barColor),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      s.value.toString(),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: 52,
                      child: pw.Text(
                        s.label,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      );
    }

    final fmt = DateFormat('dd MMM yyyy');
    final rangeTitle =
        (_start == null || _end == null)
            ? 'All Time'
            : '${fmt.format(_start!)} — ${fmt.format(_end!.subtract(const Duration(seconds: 1)))}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (ctx) => pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Jazeera Hall Events – Admin Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Range: $rangeTitle',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now()}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey600,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Metric',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Count',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ..._stats.map(
                        (s) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(s.label),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(s.value.toString()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'Overview Chart',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pdfBarChart(),
                ],
              ),
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final rangeLabel = _rangeLabel();
    return Scaffold(
      key: _scaffoldKey,

      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: _kHeaderHeight)),

                // Filters / Actions
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Today',
                            selected: _mode == DateRangeMode.today,
                            onSelected: (v) async {
                              if (!v) return;
                              setState(() {
                                _mode = DateRangeMode.today;
                                _computePresetRange(_mode);
                              });
                              await _loadStats();
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'This Month',
                            selected: _mode == DateRangeMode.thisMonth,
                            onSelected: (v) async {
                              if (!v) return;
                              setState(() {
                                _mode = DateRangeMode.thisMonth;
                                _computePresetRange(_mode);
                              });
                              await _loadStats();
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Custom',
                            selected: _mode == DateRangeMode.custom,
                            onSelected: (v) async {
                              if (!v) return;
                              await _pickCustomRange();
                            },
                            trailing: IconButton(
                              tooltip: 'Pick range',
                              icon: const Icon(Icons.date_range),
                              onPressed: _pickCustomRange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Refresh',
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadStats,
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Range label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Range: $rangeLabel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // KPI cards
                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2; // Default: mobile → 2 columns
                        if (constraints.maxWidth >= 1000) {
                          crossAxisCount = 3; // desktop
                        } else if (constraints.maxWidth >= 600) {
                          crossAxisCount = 2; // tablet
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.6, // ballac/dherer isku dheelitir
                          children:
                              _stats.map((s) => _StatCard(item: s)).toList(),
                        );
                      },
                    ),
                  ),

                  // KPI bar
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _BarChart(stats: _stats)),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  // Trend (events/day)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _LineTrend(points: _eventsPerDay),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Top Categories & Top Organizers (two pies)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (ctx, c) {
                          // side-by-side if wide enough
                          final wide = c.maxWidth >= 800;
                          final pies = [
                            Expanded(
                              child: _PieCard(
                                title: 'Top Categories',
                                data: _categoryCounts,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PieCard(
                                title: 'Top Organizers / Departments',
                                data: _organizerCounts,
                              ),
                            ),
                          ];
                          return wide
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: pies,
                              )
                              : Column(
                                children: [
                                  _PieCard(
                                    title: 'Top Categories',
                                    data: _categoryCounts,
                                  ),
                                  const SizedBox(height: 12),
                                  _PieCard(
                                    title: 'Top Organizers / Departments',
                                    data: _organizerCounts,
                                  ),
                                ],
                              );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Notes
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: const SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• Filters apply to all counts (events/venues/users) using event time = startDateTime.\n'
                            '• No-Show Events counted client-side (avoids composite index: status + date).\n'
                            '• Top Organizers groups by department if available; otherwise by organizerName/email.',
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // FIXED header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder:
                  (context) => HomeHeader(
                    onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                    title: '',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Widgets ======

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? trailing;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final selColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color:
            selected
                ? selColor.withOpacity(.12)
                : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? selColor : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onSelected(true),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: selected ? selColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? selColor : null,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  _StatItem(this.label, this.value, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedCount(label: item.label, value: item.value),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  final String label;
  final int value;
  const _AnimatedCount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder:
              (_, val, __) => Text(
                val.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ],
    );
  }
}

class _LineTrend extends StatelessWidget {
  final List<_TrendPoint> points;
  const _LineTrend({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No trend data')),
      );
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].count.toDouble()));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 18, 18),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: spots.isEmpty ? 0 : spots.last.x,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  dotData: const FlDotData(show: false),
                ),
              ],
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (spots.length / 6).clamp(1, 999).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final d = points[idx].day;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('MM/dd').format(d),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  const _PieCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries =
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    if (top.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 220,
          child: Center(child: Text('No $title data')),
        ),
      );
    }

    final total = top.fold<int>(0, (p, e) => p + e.value);
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < top.length; i++) {
      final e = top[i];
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          title: '${e.key} (${((e.value / total) * 100).toStringAsFixed(0)}%)',
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 6),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: PieChart(
                  PieChartData(sections: sections, sectionsSpace: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_StatItem> stats;
  const _BarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxVal = stats.map((e) => e.value).fold<int>(0, math.max).toDouble();
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < stats.length; i++) {
      final v = stats[i].value.toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: v, borderRadius: BorderRadius.circular(6)),
          ],
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 24, 18),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              barGroups: groups,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final label = stats[val.toInt()].label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Transform.rotate(
                          angle: -math.pi / 8,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: (maxVal == 0 ? 5 : (maxVal * 1.25)).ceilToDouble(),
            ),
          ),
        ),
      ),
    );
  }
}
