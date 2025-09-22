import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AddVenuePage extends StatefulWidget {
  const AddVenuePage({super.key, required String venueId});

  @override
  State<AddVenuePage> createState() => _AddVenuePageState();
}

class _AddVenuePageState extends State<AddVenuePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _status = 'Available';
  File? _selectedImage;
  bool _isUploading = false;

  // Static list of services
  final List<String> availableServices = [
    'WiFi',
    'Catering',
    'Projector',
    'Parking',
    'Sound System',
    'Air Conditioning',
  ];

  // Services selected by user
  Set<String> selectedServices = {};

  final String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/dphogtuy2/image/upload';
  final String uploadPreset = 'ml_default';

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() => _selectedImage = file);

        final request =
            http.MultipartRequest('POST', Uri.parse(cloudinaryUploadUrl))
              ..fields['upload_preset'] = uploadPreset
              ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseData = json.decode(
            await response.stream.bytesToString(),
          );
          final imageUrl = responseData['secure_url'];
          setState(() {
            _imageUrlController.text = imageUrl;
          });
        } else {
          throw Exception('Cloudinary upload failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
      'imageUrl': _imageUrlController.text.trim(),
      'status': _status,
      'services': selectedServices.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('venues').add(venueData);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Venue created successfully')));
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
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Create New Venue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Venue Name',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter venue name' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter location' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Capacity (seats)',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter capacity' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select Services Offered',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: ListView(
                            children:
                                availableServices
                                    .map(
                                      (service) => CheckboxListTile(
                                        title: Text(
                                          service,
                                          style: TextStyle(
                                            color: Colors.black,
                                          ), // qoraalka si fiican u muuqda
                                        ),
                                        value: selectedServices.contains(
                                          service,
                                        ),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              selectedServices.add(service);
                                            } else {
                                              selectedServices.remove(service);
                                            }
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),

                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                          icon: const Icon(Icons.upload),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload Image',
                          ),
                        ),
                        if (_selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items:
                              ['Available', 'Unavailable']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _status = value!),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Create Venue'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
