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
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';

class ReportDesktop extends StatefulWidget {
  const ReportDesktop({super.key});

  @override
  State<ReportDesktop> createState() => _ReportDesktopState();
}

class _ReportDesktopState extends State<ReportDesktop> {
  List<Map<String, dynamic>> _reports = [];
  String _selectedStatus = "All";
  String _selectedCategory = "All";
  List<String> _categories = ["All"];
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = ["All"];
        _categories.addAll(snapshot.docs.map((d) => d['name'] as String));
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _fetchReports() async {
    try {
      Query query = FirebaseFirestore.instance.collection('events');
      if (_selectedStatus != "All") {
        query = query.where('status', isEqualTo: _selectedStatus);
      }
      if (_selectedCategory != "All") {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> allData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final startDateTime = (data['startDateTime'] as Timestamp?)?.toDate();

        if (_startDate != null &&
            _endDate != null &&
            (startDateTime == null ||
                startDateTime.isBefore(_startDate!) ||
                startDateTime.isAfter(_endDate!))) {
          continue;
        }

        allData.add({
          'title': data['title'] ?? '',
          'companyName': data['companyName'] ?? '',
          'organizerName': data['organizerName'] ?? '',
          'organizerEmail': data['organizerEmail'] ?? '',
          'organizerPhone': data['organizerPhone'] ?? '',
          'seats': data['seats'] ?? 0,
          'createdAt': createdAt,
          'startDateTime': startDateTime,
          'status': data['status'] ?? '',
          'category': data['category'] ?? '',
        });
      }

      if (!mounted) return;
      setState(() => _reports = allData);
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchReports();
  }

  /// ✅ Status Chip
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case "approved":
        color = Colors.green;
        break;
      case "pending":
        color = Colors.orange;
        break;
      case "rejected":
        color = Colors.red;
        break;
      case "deleted":
        color = Colors.purple;
        break;
      case "canceled":
        color = Colors.grey;
        break;
      case "expired":
        color = Colors.black;
        break;
      default:
        color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// ✅ Export PDF
  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        build: (context) => [
          pw.Container(
            color: PdfColors.blue700,
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(logoImage, height: 50, width: 50),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  "Jazeera University - Event Reports",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              "SN",
              "Title",
              "Company",
              "Organizer",
              "Email",
              "Phone",
              "Booking Date",
              "Seats",
              "Event Date",
              "Status",
              "Category",
            ],
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue100),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            cellStyle: pw.TextStyle(fontSize: 10),
            border: pw.TableBorder.all(color: PdfColors.grey),
            oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey200),
            data: List.generate(_reports.length, (index) {
              final r = _reports[index];
              return [
                (index + 1).toString(),
                r['title'] ?? "",
                r['companyName'] ?? "",
                r['organizerName'] ?? "",
                r['organizerEmail'] ?? "",
                r['organizerPhone'] ?? "",
                r['createdAt'] != null ? DateFormat.yMMMd().format(r['createdAt']) : "N/A",
                r['seats'].toString(),
                r['startDateTime'] != null ? DateFormat.yMMMd().format(r['startDateTime']) : "N/A",
                r['status'],
                r['category'],
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "JazeeraUniversity_EventReports.pdf",
    );
  }

  /// ✅ Export Excel
  Future<void> _exportExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = "Reports";

    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoBase64 = base64Encode(logoBytes.buffer.asUint8List());
    final picture = sheet.pictures.addBase64(1, 1, logoBase64);
    picture.height = 70;
    picture.width = 70;

    sheet.getRangeByName('B1:K1').merge();
    final headerCell = sheet.getRangeByName('B1');
    headerCell.setText("Jazeera University - Event Reports");
    headerCell.cellStyle.bold = true;
    headerCell.cellStyle.fontSize = 18;
    headerCell.cellStyle.hAlign = xlsio.HAlignType.center;
    headerCell.cellStyle.vAlign = xlsio.VAlignType.center;
    headerCell.cellStyle.fontColor = '#FFFFFF';
    headerCell.cellStyle.backColor = '#2196F3';

    final headers = [
      "SN",
      "Title",
      "Company",
      "Organizer",
      "Email",
      "Phone",
      "Booking Date",
      "Seats",
      "Event Date",
      "Status",
      "Category",
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(3, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#BBDEFB';
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
    }

    for (var i = 0; i < _reports.length; i++) {
      final r = _reports[i];
      sheet.getRangeByIndex(i + 4, 1).setNumber((i + 1).toDouble());
      sheet.getRangeByIndex(i + 4, 2).setText(r['title'] ?? "");
      sheet.getRangeByIndex(i + 4, 3).setText(r['companyName'] ?? "");
      sheet.getRangeByIndex(i + 4, 4).setText(r['organizerName'] ?? "");
      sheet.getRangeByIndex(i + 4, 5).setText(r['organizerEmail'] ?? "");
      sheet.getRangeByIndex(i + 4, 6).setText(r['organizerPhone'] ?? "");
      sheet.getRangeByIndex(i + 4, 7).setText(r['createdAt'] != null ? DateFormat.yMMMd().format(r['createdAt']) : "N/A");
      sheet.getRangeByIndex(i + 4, 8).setNumber((r['seats'] as int).toDouble());
      sheet.getRangeByIndex(i + 4, 9).setText(r['startDateTime'] != null ? DateFormat.yMMMd().format(r['startDateTime']) : "N/A");
      sheet.getRangeByIndex(i + 4, 10).setText(r['status'] ?? "");
      sheet.getRangeByIndex(i + 4, 11).setText(r['category'] ?? "");
    }

    for (int i = 1; i <= 11; i++) {
      sheet.autoFitColumn(i);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/JazeeraUniversity_EventReports.xlsx");
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: "📊 Jazeera University - Event Reports");
  }

  /// ✅ Pick Date Range
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) => AdminHomeHeaderDesktop(
              onMenuTap: () => Scaffold.of(context).openEndDrawer(),
              title: '📊 Jazeera University Reports',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All Status")),
                        DropdownMenuItem(value: "pending", child: Text("Pending")),
                        DropdownMenuItem(value: "approved", child: Text("Approved")),
                        DropdownMenuItem(value: "rejected", child: Text("Rejected")),
                        DropdownMenuItem(value: "deleted", child: Text("Deleted")),
                        DropdownMenuItem(value: "canceled", child: Text("Canceled")),
                        DropdownMenuItem(value: "expired", child: Text("Expired")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _fetchReports();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                          _fetchReports();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? "${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}"
                            : "Pick Date Range",
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      tooltip: "Export PDF",
                      onPressed: _exportPDF,
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      tooltip: "Export Excel",
                      onPressed: _exportExcel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columns: const [
                          DataColumn(label: Text("SN")),
                          DataColumn(label: Text("Title")),
                          DataColumn(label: Text("Company")),
                          DataColumn(label: Text("Organizer")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Phone")),
                          DataColumn(label: Text("Booking Date")),
                          DataColumn(label: Text("Seats")),
                          DataColumn(label: Text("Event Date")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Category")),
                        ],
                        rows: List.generate(_reports.length, (index) {
                          final r = _reports[index];
                          return DataRow(
                            cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(Text(r['title'] ?? "")),
                              DataCell(Text(r['companyName'] ?? "")),
                              DataCell(Text(r['organizerName'] ?? "")),
                              DataCell(Text(r['organizerEmail'] ?? "")),
                              DataCell(Text(r['organizerPhone'] ?? "")),
                              DataCell(Text(r['createdAt'] != null ? DateFormat.yMMMd().format(r['createdAt']) : "N/A")),
                              DataCell(Text(r['seats'].toString())),
                              DataCell(Text(r['startDateTime'] != null ? DateFormat.yMMMd().format(r['startDateTime']) : "N/A")),
                              DataCell(_buildStatusChip(r['status'] ?? "")), // ✅ Badge status
                              DataCell(Text(r['category'] ?? "")),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
