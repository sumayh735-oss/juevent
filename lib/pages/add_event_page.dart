import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:withfbase/models/selected_slot.dart';
import 'package:withfbase/pages/user_service.dart';

class AddEventPage extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<SelectedSlot>? selectedSlots;

  final String venue;
  final DateTime date;
  final String timeSlot;
  final String eventId;
  final bool isUserMode;
  final String shift;
  final List<String> selectedShifts; // ✅ cusub
  const AddEventPage({
    super.key,
    this.startDate,
    this.endDate,
    this.selectedSlots,
    required this.venue,
    required this.date,
    required this.timeSlot,
    required this.eventId,
    required this.isUserMode,
    required this.shift,
    required this.selectedShifts,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _organizerNameController =
      TextEditingController();
  final TextEditingController _organizerEmailController =
      TextEditingController();
  final TextEditingController _seatsController = TextEditingController();

  // ✅ cusub: company, phone
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _organizerPhoneController =
      TextEditingController();

  String? _selectedCategory;
  String? _selectedVenue;
  int? _selectedVenueCapacity;
  String? _imageUrl;

  // Business License Document
  File? _businessDocument;
  String? _businessDocName;
  bool _isDocUploading = false;
  String? _businessDocUrl;

  final List<String> _categories = const [
    "Conferences",
    "Workshops",
    "Seminars",
    "Cultural",
    "Sports",
    "Competitions",
    "Guest Talks",
  ];

  final List<String> _venues = [];
  final Map<String, int> _venueCapacities = {};
  bool _isUploading = false;

  bool get _isBusy => _isDocUploading || _isUploading;

  @override
  void initState() {
    super.initState();
    _fetchVenueCapacities();
    _initializeDatesAndTimes();
    if (widget.venue.isNotEmpty) _selectedVenue = widget.venue;
    _checkAndInitUser();
  }

  void _checkAndInitUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ensureUserFields(user.uid);

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final isBlacklisted = userDoc.data()?['isBlacklisted'] ?? false;

      if (isBlacklisted) {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Blocked"),
                  content: const Text(
                    "You are blacklisted and cannot create events.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                        Navigator.of(
                          context,
                        ).pop(); // go back from AddEventPage
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }

  void _initializeDatesAndTimes() {
    final DateTime start = widget.startDate ?? widget.date;
    final DateTime end = widget.endDate ?? widget.date;

    String firstShiftStr;
    String lastShiftStr;

    if (widget.selectedSlots != null && widget.selectedSlots!.isNotEmpty) {
      final sel = [...widget.selectedSlots!];
      sel.sort((a, b) {
        final int cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.shiftKey.compareTo(b.shiftKey);
      });
      final first = sel.first;
      final last = sel.last;

      final bool allMorning = sel.every((s) => s.shiftKey == 'morning');
      final bool allAfternoon = sel.every((s) => s.shiftKey == 'afternoon');

      if (allMorning) {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '12:00 PM';
      } else if (allAfternoon) {
        firstShiftStr = '2:00 PM';
        lastShiftStr = '5:00 PM';
      } else {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '5:00 PM';
      }

      _startDateController.text = DateFormat('yyyy-MM-dd').format(first.date);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(last.date);
    } else {
      if (widget.shift.toLowerCase().contains('8') ||
          widget.shift.toLowerCase().contains('am')) {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '12:00 PM';
      } else if (widget.shift.toLowerCase().contains('2') ||
          widget.shift.toLowerCase().contains('pm')) {
        firstShiftStr = '2:00 PM';
        lastShiftStr = '5:00 PM';
      } else {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '5:00 PM';
      }
      _startDateController.text = DateFormat('yyyy-MM-dd').format(start);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(end);
    }
    _startTimeController.text = firstShiftStr;
    _endTimeController.text = lastShiftStr;
  }

  Future<void> _fetchVenueCapacities() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('venues').get();
      setState(() {
        _venueCapacities.clear();
        _venues.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final name = data['name'] as String?;
          final capacity = data['capacity'] as int?;
          if (name != null && capacity != null) {
            _venues.add(name);
            _venueCapacities[name] = capacity;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching venue capacities: $e');
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _pickBusinessDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final pickedFile = File(filePath);

      if (pickedFile.existsSync()) {
        setState(() {
          _businessDocument = pickedFile;
          _businessDocName = result.files.single.name;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found on device.')),
        );
      }
    }
  }

  Future<String?> _uploadBusinessDocument() async {
    if (_businessDocument == null || !_businessDocument!.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid document.')),
      );
      return null;
    }

    // Check if document is blacklisted
    if (await isBlacklistedDoc(_businessDocName!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document is blacklisted. Upload denied.'),
        ),
      );
      return null;
    }

    setState(() => _isDocUploading = true);

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dphogtuy2/raw/upload',
      );

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = 'ml_default'
            ..files.add(
              await http.MultipartFile.fromPath(
                'file',
                _businessDocument!.path,
              ),
            );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'];
      } else {
        debugPrint('Cloudinary Upload Failed: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    } finally {
      setState(() => _isDocUploading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        setState(() => _isUploading = true);
        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/dphogtuy2/image/upload',
        );
        final request =
            http.MultipartRequest('POST', uri)
              ..fields['upload_preset'] = 'ml_default'
              ..files.add(
                await http.MultipartFile.fromPath('file', imageFile.path),
              );

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          setState(() {
            _imageUrl = data['secure_url'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.reasonPhrase}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<bool> isBlacklistedDoc(String docName) async {
    final result =
        await FirebaseFirestore.instance
            .collection('users')
            .where('docName', isEqualTo: docName)
            .where('isUnblocked', isEqualTo: false)
            .get();

    return result.docs.isNotEmpty;
  }

  Future<void> _createEvent() async {
    try {
      final startDateTime = DateFormat(
        "yyyy-MM-dd HH:mm",
      ).parse("${_startDateController.text} ${_startTimeController.text}");
      final endDateTime = DateFormat(
        "yyyy-MM-dd HH:mm",
      ).parse("${_endDateController.text} ${_endTimeController.text}");

      // Check for blacklist BEFORE upload
      if (await isBlacklistedDoc(_businessDocName ?? '')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This document is blacklisted. Cannot create event.'),
          ),
        );
        return;
      }

      // Upload document
      _businessDocUrl = await _uploadBusinessDocument();
      if (_businessDocUrl == null) return; // Don't continue if upload fails

      // ✅ DocumentReference si loo helo ID-ga
      final docRef = FirebaseFirestore.instance.collection('events').doc();

      await docRef.set({
        'id': docRef.id, // ✅ Event ID gudaha la geliyay
        'title': _titleController.text.trim(),
        'category': _selectedCategory ?? '',
        'venue': _selectedVenue ?? '',
        'description': _descriptionController.text.trim(),
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
        'organizerName': _organizerNameController.text.trim(),
        'organizerEmail': _organizerEmailController.text.trim(),
        'organizerPhone': _organizerPhoneController.text.trim(),
        'seats': int.tryParse(_seatsController.text) ?? 0,
        'imageUrl': _imageUrl ?? '',
        'businessDocumentUrl': _businessDocUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',

        // ✅ cusub
        'companyName': _companyNameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
    }
  }

  String? _validateSeats(String? value) {
    if (value == null || value.isEmpty) return 'Enter number of seats';
    final seats = int.tryParse(value);
    if (seats == null) return 'Enter a valid number';

    if (seats < 10) {
      return 'Seats cannot be less than 10';
    }

    if (_selectedVenueCapacity != null && seats > _selectedVenueCapacity!) {
      return 'Seats cannot exceed venue capacity ($_selectedVenueCapacity)';
    }

    return null;
  }

  Future<void> _pickStartDate() async {
    final current = DateFormat('yyyy-MM-dd').parse(_startDateController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final current = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickStartTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        _startTimeController.text = _formatTimeOfDay(picked);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        _endTimeController.text = _formatTimeOfDay(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserMode = widget.isUserMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (isUserMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Start/End Date & Time waa laga doortay Availability. Lama beddeli karo.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),

              // ✅ cusub: Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter company name' : null,
              ),
              const SizedBox(height: 16),

              // Business Document Upload
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Business License Document",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isDocUploading ? null : _pickBusinessDocument,
                          icon: const Icon(Icons.upload_file, size: 20),
                          label: const Text("Choose File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _businessDocName ?? "No file selected",
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  _businessDocName != null
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                              fontWeight:
                                  _businessDocName != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_isDocUploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: _selectedCategory,
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Venue'),
                value: _selectedVenue,
                items:
                    _venues
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedVenue = val;
                    _selectedVenueCapacity =
                        val != null ? _venueCapacities[val] : null;
                  });
                },
                validator: (val) => val == null ? 'Select a venue' : null,
              ),
              if (_selectedVenueCapacity != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Capacity: $_selectedVenueCapacity seats',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(labelText: 'Start Date'),
                readOnly: true,
                enabled: !isUserMode,
                onTap: !isUserMode ? _pickStartDate : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                readOnly: true,
                enabled: !isUserMode,
                onTap: !isUserMode ? _pickStartTime : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(labelText: 'End Date'),
                readOnly: true,
                enabled: !isUserMode,
                onTap: !isUserMode ? _pickEndDate : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
                readOnly: true,
                enabled: !isUserMode,
                onTap: !isUserMode ? _pickEndTime : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerNameController,
                decoration: const InputDecoration(labelText: 'Organizer Name'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerEmailController,
                decoration: const InputDecoration(labelText: 'Organizer Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerPhoneController,
                decoration: const InputDecoration(labelText: 'Organizer Phone'),
                keyboardType: TextInputType.phone,
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Enter organizer phone' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Seats (Min 10)',
                  hintText: 'Enter at least 10 seats',
                ),
                keyboardType: TextInputType.number,
                validator: _validateSeats,
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: const Text('Upload Event Image'),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_isUploading) const CircularProgressIndicator(),

              ElevatedButton.icon(
                onPressed:
                    _isBusy
                        ? null
                        : () {
                          if (_formKey.currentState!.validate()) {
                            _createEvent();
                          }
                        },
                icon: const Icon(Icons.check_circle),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                  'Status: Pending (awaiting admin approval)',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
