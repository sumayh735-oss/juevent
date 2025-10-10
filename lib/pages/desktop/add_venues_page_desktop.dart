import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AddVenuesPageDesktop extends StatefulWidget {
  const AddVenuesPageDesktop({super.key, required this.venueId});
  final String venueId;

  @override
  State<AddVenuesPageDesktop> createState() => _AddVenuesPageDesktopState();
}

class _AddVenuesPageDesktopState extends State<AddVenuesPageDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _status = 'Available';
  File? _selectedImage;
  String? _imageUrl; // 🔹 Cloudinary secure_url
  bool _isUploading = false;

  // Static services
  final List<String> availableServices = [
    'WiFi',
    'Catering',
    'Projector',
    'Parking',
    'Sound System',
    'Air Conditioning',
  ];
  Set<String> selectedServices = {};

  final String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/dphogtuy2/image/upload';
  final String uploadPreset = 'ml_default';

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // 🔹 Web support
      );

      if (result != null) {
        if (kIsWeb && result.files.single.bytes != null) {
          // 🌐 Web → bytes to Cloudinary
          final bytes = result.files.single.bytes!;
          final request =
              http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl))
                ..fields['upload_preset'] = uploadPreset
                ..files.add(http.MultipartFile.fromBytes(
                  'file',
                  bytes,
                  filename: result.files.single.name,
                ));

          final response = await request.send();
          if (response.statusCode == 200) {
            final responseData =
                json.decode(await response.stream.bytesToString());
            final imageUrl = responseData['secure_url'];
            setState(() {
              _imageUrl = imageUrl;
              _imageUrlController.text = imageUrl;
            });
          } else {
            throw Exception(
                'Cloudinary upload failed: ${response.statusCode}');
          }
        } else if (result.files.single.path != null) {
          // 💻 Desktop/Mobile
          final file = File(result.files.single.path!);
          setState(() => _selectedImage = file);

          final request =
              http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl))
                ..fields['upload_preset'] = uploadPreset
                ..files
                    .add(await http.MultipartFile.fromPath('file', file.path));

          final response = await request.send();

          if (response.statusCode == 200) {
            final responseData =
                json.decode(await response.stream.bytesToString());
            final imageUrl = responseData['secure_url'];
            setState(() {
              _imageUrl = imageUrl;
              _imageUrlController.text = imageUrl;
            });
          } else {
            throw Exception(
                'Cloudinary upload failed: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }

    final venueData = {
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageUrl ?? _imageUrlController.text.trim(),
      'status': _status,
      'services': selectedServices.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('venues').add(venueData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venue created successfully')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.1,
        vertical: 20,
      ),
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      "➕ Create New Venue",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),

                const SizedBox(height: 16),

                // Two-column layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Venue Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Enter venue name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Enter location' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacity',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Enter capacity' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Available', 'Unavailable']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _status = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed:
                                _isUploading ? null : _pickAndUploadImage,
                            icon: const Icon(Icons.upload),
                            label: Text(
                                _isUploading ? "Uploading..." : "Upload Image"),
                          ),

                          // 🔹 Show preview correctly (Web vs Desktop/Mobile)
                          if (_imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (!kIsWeb && _selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Services
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Services Offered",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: availableServices.map((service) {
                    return FilterChip(
                      label: Text(service),
                      selected: selectedServices.contains(service),
                      onSelected: (checked) {
                        setState(() {
                          if (checked) {
                            selectedServices.add(service);
                          } else {
                            selectedServices.remove(service);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Create Venue"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
