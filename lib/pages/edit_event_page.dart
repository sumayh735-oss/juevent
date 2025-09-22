import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventPage extends StatefulWidget {
  final DocumentSnapshot eventData;

  const EditEventPage({
    super.key,
    required String docId,
    required this.eventData,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _venueController;
  late TextEditingController _organizerController;
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['title']);
    _dateController = TextEditingController(
      text: widget.eventData['startDate'],
    );
    _venueController = TextEditingController(text: widget.eventData['venue']);
    _organizerController = TextEditingController(
      text: widget.eventData['organizerName'],
    );
    _statusController = TextEditingController(text: widget.eventData['status']);
  }

  void _updateEvent() async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventData.id)
        .update({
          'title': _titleController.text,
          'startDate': _dateController.text,
          'venue': _venueController.text,
          'organizerName': _organizerController.text,
          'status': _statusController.text,
        });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _organizerController,
                decoration: const InputDecoration(labelText: 'Organizer'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
