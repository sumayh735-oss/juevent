import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';

class FullEventReportPage extends StatefulWidget {
  const FullEventReportPage({super.key});

  @override
  State<FullEventReportPage> createState() => _FullEventReportPageState();
}

class _FullEventReportPageState extends State<FullEventReportPage> {
  List<Map<String, dynamic>> _reports = [];
  String _selectedStatus = "All";
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _fetchReports() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .orderBy('createdAt', descending: true)
              .get();

      debugPrint("✅ Reports fetched: ${snapshot.docs.length}");

      List<Map<String, dynamic>> allData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allData.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'companyName': data['companyName'] ?? '',
          'organizerName': data['organizerName'] ?? '',
          'organizerEmail': data['organizerEmail'] ?? '',
          'organizerPhone': data['organizerPhone'] ?? '',
          'seats': data['seats'] ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'startDateTime': (data['startDateTime'] as Timestamp?)?.toDate(),
          'endDateTime': (data['endDateTime'] as Timestamp?)?.toDate(),
          'status': data['status'] ?? '',
        });
      }

      if (!mounted) return;
      setState(() => _reports = allData);

      debugPrint("✅ Reports in state: ${_reports.length}");
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  /// ✅ Export PDF
  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                "Event Reports",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
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
                ],
                data: List.generate(_reports.length, (index) {
                  final r = _reports[index];
                  return [
                    (index + 1).toString(),
                    r['title'],
                    r['companyName'],
                    r['organizerName'],
                    r['organizerEmail'],
                    r['organizerPhone'],
                    r['createdAt'] != null
                        ? DateFormat.yMMMd().format(r['createdAt'])
                        : "N/A",
                    r['seats'].toString(),
                    r['startDateTime'] != null
                        ? DateFormat.yMMMd().format(r['startDateTime'])
                        : "N/A",
                    r['status'],
                  ];
                }),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// ✅ Export Excel
  Future<void> _exportExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Reports'];

    // Headers
    sheetObject.appendRow([
      TextCellValue("SN"),
      TextCellValue("Title"),
      TextCellValue("Company"),
      TextCellValue("Organizer"),
      TextCellValue("Email"),
      TextCellValue("Phone"),
      TextCellValue("Booking Date"),
      TextCellValue("Seats"),
      TextCellValue("Event Date"),
      TextCellValue("Status"),
    ]);

    // Data
    for (var i = 0; i < _reports.length; i++) {
      final r = _reports[i];
      sheetObject.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r['title'].toString()),
        TextCellValue(r['companyName'].toString()),
        TextCellValue(r['organizerName'].toString()),
        TextCellValue(r['organizerEmail'].toString()),
        TextCellValue(r['organizerPhone'].toString()),
        TextCellValue(
          r['createdAt'] != null
              ? DateFormat.yMMMd().format(r['createdAt'])
              : "N/A",
        ),
        IntCellValue(r['seats'] as int),
        TextCellValue(
          r['startDateTime'] != null
              ? DateFormat.yMMMd().format(r['startDateTime'])
              : "N/A",
        ),
        TextCellValue(r['status'].toString()),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: "EventReports.xlsx",
      );
    }
  }

  /// ✅ choose date range
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
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
      appBar: AppBar(
        title: const Text("📊 Event Reports"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: _exportPDF,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "Export Excel",
            onPressed: _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Filters
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All Status")),
                    DropdownMenuItem(value: "pending", child: Text("Pending")),
                    DropdownMenuItem(
                      value: "approved",
                      child: Text("Approved"),
                    ),
                    DropdownMenuItem(
                      value: "rejected",
                      child: Text("Rejected"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                      _fetchReports();
                    }
                  },
                ),
                const SizedBox(width: 16),
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
          ),
          const Divider(),
          // ✅ Table
          Expanded(
            child:
                _reports.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.blue[50],
                        ),
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
                        ],
                        rows: List.generate(_reports.length, (index) {
                          final r = _reports[index];
                          return DataRow(
                            cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(Text(r['title'])),
                              DataCell(Text(r['companyName'])),
                              DataCell(Text(r['organizerName'])),
                              DataCell(Text(r['organizerEmail'])),
                              DataCell(Text(r['organizerPhone'])),
                              DataCell(
                                Text(
                                  r['createdAt'] != null
                                      ? DateFormat.yMMMd().format(
                                        r['createdAt'],
                                      )
                                      : "N/A",
                                ),
                              ),
                              DataCell(Text(r['seats'].toString())),
                              DataCell(
                                Text(
                                  r['startDateTime'] != null
                                      ? DateFormat.yMMMd().format(
                                        r['startDateTime'],
                                      )
                                      : "N/A",
                                ),
                              ),
                              DataCell(Text(r['status'])),
                            ],
                          );
                        }),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
