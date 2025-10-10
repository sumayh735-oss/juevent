
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:withfbase/models/selected_slot.dart';

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
  final List<String> selectedShifts;
  final List<DateTime> validDates;
  final Map<DateTime, Set<String>> selectedShiftsMap;
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
    this.validDates = const [],
    this.selectedShiftsMap = const {},
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
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyLocationController = TextEditingController();

  final TextEditingController _organizerPhoneController =
      TextEditingController();

  String? _selectedCategory;
  String? _selectedVenue;
  int? _selectedVenueCapacity;
  String? _imageUrl;

  File? _businessDocument;
  String? _businessDocName;
  bool _isDocUploading = false;
  String? _businessDocUrl;

  List<String> _categories = [];

Future<void> _fetchCategories() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  } catch (e) {
    debugPrint('Error fetching categories: $e');
  }
}

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
     _fetchCategories(); 
  }

void _checkAndInitUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final isBlacklisted = userDoc.data()?['isBlacklisted'] ?? false;

    if (isBlacklisted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚫 Your account is blocked. You cannot create events."),
          ),
        );
        Navigator.of(context).pop(); // iska saar AddEventPage
      }
    }
  }
}

  void _initializeDatesAndTimes() {
    final DateTime start = widget.startDate ?? widget.date;
    final DateTime end = widget.endDate ?? widget.date;
    String firstShiftStr = '8:00 AM';
    String lastShiftStr = '5:00 PM';
    if (widget.selectedShifts.isNotEmpty) {
      final allMorning = widget.selectedShifts.every(
        (s) => s.contains("08:00"),
      );
      final allAfternoon = widget.selectedShifts.every(
        (s) => s.contains("02:00"),
      );
      if (allMorning) {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '12:00 PM';
      } else if (allAfternoon) {
        firstShiftStr = '2:00 PM';
        lastShiftStr = '5:00 PM';
      }
    } else if (widget.timeSlot.isNotEmpty) {
      if (widget.timeSlot.contains("08:00")) {
        firstShiftStr = '8:00 AM';
        lastShiftStr = '12:00 PM';
      } else if (widget.timeSlot.contains("02:00")) {
        firstShiftStr = '2:00 PM';
        lastShiftStr = '5:00 PM';
      }
    } else if (widget.shift.toLowerCase().contains('am')) {
      firstShiftStr = '8:00 AM';
      lastShiftStr = '12:00 PM';
    } else if (widget.shift.toLowerCase().contains('pm')) {
      firstShiftStr = '2:00 PM';
      lastShiftStr = '5:00 PM';
    }
    _startDateController.text = DateFormat('yyyy-MM-dd').format(start);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(end);
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
    if (await blacklistedDoc(_businessDocName!)) {
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
      setState(() => _isUploading = true);

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dphogtuy2/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'ml_default';

      if (pickedFile.path.isNotEmpty && !kIsWeb) {
        // 📱 Mobile & Desktop native
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      } else {
        // 🌐 Flutter Web
        final bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        setState(() {
          _imageUrl = data['secure_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.reasonPhrase}')));
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Upload error: $e')));
  } finally {
    setState(() => _isUploading = false);
  }
}
    Future<bool> blacklistedDoc(String docName) async {
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create an event.')),
      );
      return;
    }

    // Hubi user doc
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found.')),
      );
      return;
    }

    final data = userDoc.data()!;
    final isBlacklisted = data['isBlacklisted'] ?? false;
    if (isBlacklisted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 Your account is blocked. You cannot create events.')),
      );
      return;
    }

    // --------- Halkan abuur event haddii aan la block gareynin ----------
    final datesToSave =
        widget.validDates.isNotEmpty ? widget.validDates : [widget.date];

    for (var date in datesToSave) {
      final shifts = widget.selectedShiftsMap[date] ?? widget.selectedShifts;
      if (shifts.isEmpty) continue;

      // ✅ Samee ID gaar ah oo ku saleysan waqtiga hadda
      final now = DateTime.now();
      final String customId =
          "event_${now.toIso8601String().replaceAll(':', '-')}";

      // ✅ Samee date format la akhriyi karo
      final String createdDateFormatted =
          "${now.day.toString().padLeft(2, '0')} ${_monthName(now.month)} ${now.year}";

      // ✅ diyaari event data
      final Map<String, dynamic> eventData = {
        'customId': customId,
        'title': _titleController.text.trim(),
        'venue': widget.venue,
        'description': _descriptionController.text.trim(),
        'startDateTime': Timestamp.fromDate(date),
        'endDateTime': Timestamp.fromDate(date.add(const Duration(hours: 4))),
        'createdAt': FieldValue.serverTimestamp(),
        'createdDateFormatted': createdDateFormatted, // ✅ Human readable date
        'status': 'pending',
        'selectedShifts': shifts.toList(),
        'organizerName': _organizerNameController.text.trim(),
        'organizerEmail': _organizerEmailController.text.trim(),
        'organizerPhone': _organizerPhoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'companyLocation': _companyLocationController.text.trim(),
        'category': _selectedCategory,
        'createdBy': user.uid,
      };

      // ✅ Hubi URLs
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        eventData['imageUrl'] = _imageUrl;
      }
      if (_businessDocUrl != null && _businessDocUrl!.isNotEmpty) {
        eventData['businessDocUrl'] = _businessDocUrl;
      }

      debugPrint('📦 Event data prepared: $eventData');

      // ✅ Ku kaydi Firestore adigoo isticmaalaya customId
      await FirebaseFirestore.instance
          .collection('events')
          .doc(customId)
          .set(eventData);

      debugPrint('✅ Event saved with ID: $customId');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Event(s) created successfully!')),
    );
  } catch (e) {
    debugPrint('❌ Error creating event: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error creating event: $e')),
    );
  }
}

/// Helper function for month names
String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}
  String? _validateSeats(String? value) {
    if (value == null || value.isEmpty) return 'Enter number of seats';
    final seats = int.tryParse(value);
    if (seats == null) return 'Enter a valid number';
    if (seats < 10) {
      return 'Seats cannot be less than 10';
    }
    if (seats > 600) {
      return 'Seats cannot exceed 600';
    }
    if (_selectedVenueCapacity != null && seats > _selectedVenueCapacity!) {
      return 'Seats cannot exceed venue capacity ($_selectedVenueCapacity)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter organizer phone';
    if (value.length < 7) return 'Phone number must be at least 7 digits';
    if (value.length > 13) return 'Phone number cannot exceed 13 digits';
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
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter company name' : null,
              ),
              TextFormField(
  controller: _companyLocationController,
  decoration: const InputDecoration(labelText: 'Company Location'),
  validator: (v) => v == null || v.isEmpty ? 'Enter company location' : null,
),
const SizedBox(height: 16),

              const SizedBox(height: 16),
              const SizedBox(height: 16),
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
      StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('categories')
      .orderBy('createdAt', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Category'),
        items: [],
        onChanged: null,
        hint: const Text("No categories found"),
      );
    }

    final categories = snapshot.data!.docs
        .map((doc) => doc['name'] as String)
        .toList();

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Category'),
      value: _selectedCategory,
      items: categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val),
      validator: (val) => val == null ? 'Select a category' : null,
    );
  },
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
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Seats (Min 10, Max 600)',
                  hintText: 'Enter seats between 10 and 600',
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


