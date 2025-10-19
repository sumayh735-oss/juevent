// -----------------------------------------------------------------------------
// report_mobile_final.dart — Mobile-Optimized Reports (Cards + Filters + Export)
// -----------------------------------------------------------------------------
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class FullEventReport22 extends StatefulWidget {
  const FullEventReport22({super.key});
  @override
  State<FullEventReport22> createState() => _FullEventReport22eState();
}

class _FullEventReport22eState extends State<FullEventReport22> {
  // Data
  List<Map<String, dynamic>> _reports = [];
  List<String> _categories = ["All"];
  List<String> _companies = ["All"];

  // Filters
  String _selectedStatus = "All";
  String _selectedCategory = "All";
  String _selectedCompany = "All";
  DateTime? _startDate;
  DateTime? _endDate;

  // Insights
  String _mostCompany = 'N/A';
  int _mostCount = 0;
  String _mostcompanyLocation = 'N/A';

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchTerm = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchTerm = _searchCtrl.text.trim().toLowerCase());
    });
    _fetchCategories();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------------------------- FIRESTORE FETCH ---------------------------

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = ["All"];
        _categories.addAll(snapshot.docs.map((d) => (d['name'] ?? '').toString()).where((e) => e.isNotEmpty));
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _fetchReports() async {
  setState(() => _loading = true);
  try {
    Query query = FirebaseFirestore.instance.collection('events');

    // status filter (note: in db sometimes lowercase/uppercase)
    if (_selectedStatus != "All") {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    if (_selectedCategory != "All") {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_selectedCompany != "All") {
      query = query.where('companyName', isEqualTo: _selectedCompany);
    }

    final snapshot = await query.get();
    final List<Map<String, dynamic>> allData = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final startDateTime = (data['startDateTime'] as Timestamp?)?.toDate();

      // date range filter on startDateTime
      if (_startDate != null && _endDate != null) {
        if (startDateTime == null ||
            startDateTime.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day)) ||
            startDateTime.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) {
          continue;
        }
      }

      allData.add({
        'title': data['title'] ?? '',
        'companyName': data['companyName'] ?? '',
        'companyLocation': data['companyLocation'] ?? '',
        'organizerName': data['organizerName'] ?? '',
        'organizerEmail': data['organizerEmail'] ?? '',
        'organizerPhone': data['organizerPhone'] ?? '',
        'seats': data['seats'] ?? 0,
        'createdAt': createdAt,
        'startDateTime': startDateTime,
        'status': (data['status'] ?? '').toString(),
        'category': data['category'] ?? '',
      });
    }

    // build companies list + insight
    final Map<String, int> companyCount = {};
    final Map<String, String> companyLocations = {};
    for (final r in allData) {
      final company = (r['companyName'] ?? '').toString();
      final location = (r['companyLocation'] ?? '').toString();
      if (company.isNotEmpty) {
        companyCount[company] = (companyCount[company] ?? 0) + 1;
        companyLocations.putIfAbsent(company, () => location);
      }
    }

    String mostCompany = 'N/A';
    int mostCount = 0;
    String mostLocation = 'N/A';
    if (companyCount.isNotEmpty) {
      final sorted = companyCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      mostCompany = sorted.first.key;
      mostCount = sorted.first.value;
      mostLocation = companyLocations[mostCompany] ?? 'N/A';
    }

    if (!mounted) return;
    setState(() {
      _reports = allData;
      _mostCompany = mostCompany;
      _mostCount = mostCount;
      _mostcompanyLocation = mostLocation;
      _companies = ["All", ...companyCount.keys];

      // ✅ FIX: make sure _selectedCompany is valid
      if (!_companies.contains(_selectedCompany)) {
        _selectedCompany = "All";
      }

      _loading = false;
    });
  } catch (e) {
    debugPrint("Error fetching reports: $e");
    if (!mounted) return;
    setState(() => _loading = false);
  }
}


  // --------------------------- UI HELPERS ---------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      case "deleted":
        return Colors.purple;
      case "canceled":
      case "cancelled":
        return Colors.grey;
      case "expired":
        return Colors.black;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        (status.isEmpty ? '-' : status),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // --------------------------- EXPORTS ---------------------------

  Future<void> _exportPDF() async {
    try {
      final pdf = pw.Document();
      final logoBytes = await rootBundle.load('assets/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Container(
              color: PdfColors.blue700,
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(children: [
                pw.Image(logoImage, height: 40, width: 40),
                pw.SizedBox(width: 10),
                pw.Text(
                  "Jazeera University - Event Reports (Mobile Export)",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ]),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "🏆 Most Active Company: $_mostCompany ($_mostCount events) | 📍 ${_mostcompanyLocation}",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ["#", "Title", "Company", "Location", "Organizer", "Phone", "Email", "Booked", "Event", "Status", "Category", "Seats"],
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue100),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              data: List.generate(_reports.length, (i) {
                final r = _reports[i];
                return [
                  (i + 1).toString(),
                  r['title'] ?? "",
                  r['companyName'] ?? "",
                  r['companyLocation'] ?? "",
                  r['organizerName'] ?? "",
                  r['organizerPhone'] ?? "",
                  r['organizerEmail'] ?? "",
                  r['createdAt'] != null ? DateFormat.yMMMd().format(r['createdAt']) : "N/A",
                  r['startDateTime'] != null ? DateFormat.yMMMd().format(r['startDateTime']) : "N/A",
                  r['status'] ?? "",
                  r['category'] ?? "",
                  (r['seats'] ?? 0).toString(),
                ];
              }),
            ),
          ],
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: "JazeeraUniversity_EventReports_Mobile.pdf");
    } catch (e) {
      debugPrint("PDF export error: $e");
    }
  }

  Future<void> _exportExcel() async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = "Reports";

      // Logo
      final logoBytes = await rootBundle.load('assets/logo.png');
      final logoBase64 = base64Encode(logoBytes.buffer.asUint8List());
      final picture = sheet.pictures.addBase64(1, 1, logoBase64);
      picture.height = 60;
      picture.width = 60;

      sheet.getRangeByName('B1:N1').merge();
      final header = sheet.getRangeByName('B1');
      header.setText("Jazeera University - Event Reports (Mobile Export)");
      header.cellStyle
        ..bold = true
        ..fontSize = 16
        ..hAlign = xlsio.HAlignType.center
        ..backColor = '#2196F3'
        ..fontColor = '#FFFFFF';

      sheet.getRangeByName('B2:N2').merge();
      sheet.getRangeByName('B2')
        ..setText("Most Active: $_mostCompany ($_mostCount) • ${_mostcompanyLocation}")
        ..cellStyle.bold = true;

      final headers = ["#", "Title", "Company", "Location", "Organizer", "Email", "Phone", "Booking Date", "Event Date", "Status", "Category", "Seats"];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(3, i + 1);
        cell
          ..setText(headers[i])
          ..cellStyle.bold = true
          ..cellStyle.backColor = '#BBDEFB'
          ..cellStyle.hAlign = xlsio.HAlignType.center;
      }

      for (var i = 0; i < _reports.length; i++) {
        final r = _reports[i];
        sheet.getRangeByIndex(i + 4, 1).setNumber((i + 1).toDouble());
        sheet.getRangeByIndex(i + 4, 2).setText(r['title'] ?? "");
        sheet.getRangeByIndex(i + 4, 3).setText(r['companyName'] ?? "");
        sheet.getRangeByIndex(i + 4, 4).setText(r['companyLocation'] ?? "");
        sheet.getRangeByIndex(i + 4, 5).setText(r['organizerName'] ?? "");
        sheet.getRangeByIndex(i + 4, 6).setText(r['organizerEmail'] ?? "");
        sheet.getRangeByIndex(i + 4, 7).setText(r['organizerPhone'] ?? "");
        sheet.getRangeByIndex(i + 4, 8).setText(r['createdAt'] != null ? DateFormat.yMMMd().format(r['createdAt']) : "N/A");
        sheet.getRangeByIndex(i + 4, 9).setText(r['startDateTime'] != null ? DateFormat.yMMMd().format(r['startDateTime']) : "N/A");
        sheet.getRangeByIndex(i + 4, 10).setText(r['status'] ?? "");
        sheet.getRangeByIndex(i + 4, 11).setText(r['category'] ?? "");
        sheet.getRangeByIndex(i + 4, 12).setNumber(((r['seats'] ?? 0) as num).toDouble());
      }

      for (int i = 1; i <= 12; i++) {
        sheet.autoFitColumn(i);
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/JazeeraUniversity_EventReports_Mobile.xlsx");
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: "📊 Jazeera University - Event Reports (Mobile)");
    } catch (e) {
      debugPrint("Excel export error: $e");
    }
  }

  // --------------------------- DATE RANGE ---------------------------

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Date Range',
      saveText: 'Apply',
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      _fetchReports();
    }
  }

  // --------------------------- BUILD ---------------------------

  @override
  Widget build(BuildContext context) {
    final filtered = _reports.where((r) {
      if (_searchTerm.isEmpty) return true;
      final hay = "${r['title']} ${r['companyName']} ${r['organizerName']}".toLowerCase();
      return hay.contains(_searchTerm);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
        

          // Filters (stacked for mobile)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              children: [
                // row 1: search + export
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search title, company, organizer...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _exportPDF,
                      tooltip: 'Export PDF',
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    IconButton(
                      onPressed: _exportExcel,
                      tooltip: 'Export Excel',
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // row 2: status + category
                Row(
                  children: [
                    Expanded(
                      child: _DropdownBox<String>(
                        label: 'Status',
                        value: _selectedStatus,
                        items: const [
                          "All", "pending", "approved", "rejected", "deleted", "canceled", "expired"
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _selectedStatus = val);
                          _fetchReports();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DropdownBox<String>(
                        label: 'Category',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _selectedCategory = val);
                          _fetchReports();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // row 3: company + date range
                Row(
                  children: [
                    Expanded(
                      child: _DropdownBox<String>(
                        label: 'Company',
                        value: _selectedCompany,
                        items: _companies,
                        itemBuilder: (c) {
                          if (c == "All") return const Text("All Companies");
                          final cnt = _reports.where((r) => r['companyName'] == c).length;
                          return Text("$c ($cnt)");
                        },
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _selectedCompany = val);
                          _fetchReports();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          (_startDate != null && _endDate != null)
                              ? "${DateFormat.MMMd().format(_startDate!)} - ${DateFormat.MMMd().format(_endDate!)}"
                              : "Pick Date Range",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Insight
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "🏆 Most Active: $_mostCompany ($_mostCount) • ${_mostcompanyLocation}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          ),

          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (filtered.isEmpty
                    ? const Center(child: Text('No results'))
                    : RefreshIndicator(
                        onRefresh: () async => _fetchReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final r = filtered[i];
                            return _ReportCard(
                              index: i + 1,
                              title: r['title'] ?? '',
                              company: r['companyName'] ?? '',
                              location: r['companyLocation'] ?? '',
                              organizer: r['organizerName'] ?? '',
                              email: r['organizerEmail'] ?? '',
                              phone: r['organizerPhone'] ?? '',
                              bookedAt: r['createdAt'] as DateTime?,
                              eventAt: r['startDateTime'] as DateTime?,
                              status: (r['status'] ?? '').toString(),
                              category: r['category'] ?? '',
                              statusChipBuilder: _buildStatusChip,
                            );
                          },
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}

// --------------------------- SMALL WIDGETS ---------------------------

class _DropdownBox<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final Widget Function(T value)? itemBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: itemBuilder != null ? itemBuilder!(e) : Text(e.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final int index;
  final String title;
  final String company;
  final String location;
  final String organizer;
  final String email;
  final String phone;
  final DateTime? bookedAt;
  final DateTime? eventAt;
  final String status;
  final String category;
  final Widget Function(String status) statusChipBuilder;

  const _ReportCard({
    required this.index,
    required this.title,
    required this.company,
    required this.location,
    required this.organizer,
    required this.email,
    required this.phone,
    required this.bookedAt,
    required this.eventAt,
    required this.status,
    required this.category,
    required this.statusChipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final createdTxt = bookedAt != null ? DateFormat.yMMMd().format(bookedAt!) : 'N/A';
    final eventTxt = eventAt != null ? DateFormat.yMMMd().format(eventAt!) : 'N/A';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue.shade50,
                  child: Text('$index', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.isEmpty ? 'Untitled' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                statusChipBuilder(status),
              ],
            ),
            const SizedBox(height: 6),

            // info rows
            _kv("Company", company.isEmpty ? '-' : company),
            _kv("Location", location.isEmpty ? '-' : location),
            _kv("Organizer", organizer.isEmpty ? '-' : organizer),
            if (phone.isNotEmpty) _kv("Phone", phone),
            if (email.isNotEmpty) _kv("Email", email),
            const SizedBox(height: 6),

            // dates
            Row(
              children: [
                Expanded(child: _pill("Booking", createdTxt, Icons.event_note)),
                const SizedBox(width: 8),
                Expanded(child: _pill("Event", eventTxt, Icons.event)),
              ],
            ),
            const SizedBox(height: 6),

            // footer tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _tag("Category: ${category.isEmpty ? '-' : category}"),
                _tag("Status: ${status.isEmpty ? '-' : status}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              "$label: $value",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueGrey.withOpacity(.25)),
      ),
      child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
