import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mhj_maps/mhj_maps.dart';

import 'location_helper.dart';
import 'report_service.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _reportService = ReportService();
  final _picker = ImagePicker();

  XFile? _pickedFile; // The selected image (XFile)
  Uint8List? _imageBytes; // Used for web preview
  Position? _position; // GPS coordinates
  String? _selectedCategory; // Category dropdown value
  bool _isLocating = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Pothole',
    'Broken Streetlight',
    'Garbage Overflow',
    'Water Leak',
    'Damaged Sidewalk',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ---------------- LOCATION ----------------
  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    final pos = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _position = pos;
      _isLocating = false;
    });
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Please enable GPS.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _pickedFile = picked;
        });
      } else {
        setState(() => _pickedFile = picked);
      }
    } catch (e) {
      debugPrint('❌ Image pick error: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for GPS location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await _reportService.submitReport(
      imageFile: _pickedFile!,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      category: _selectedCategory!,
      description: _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Report submitted!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to submit report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot an Issue'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- Photo Picker ----------
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : (_pickedFile != null && !kIsWeb)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_pickedFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- GPS Location Card ----------
              Card(
                child: ListTile(
                  leading: _isLocating
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.location_on, color: Colors.teal),
                  title: Text(
                    _position == null
                        ? 'Getting location...'
                        : '${_position!.latitude.toStringAsFixed(5)}, '
                              '${_position!.longitude.toStringAsFixed(5)}',
                  ),
                  subtitle: const Text('GPS Tag'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _getLocation,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Mini Map Preview ----------
              if (_position != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: MhjMapsMap(
                      center: MhjMapsLatLng(
                        lat: _position!.latitude,
                        lng: _position!.longitude,
                      ),
                      zoom: 15,
                      showZoomControls: false,
                      showAttribution: false,
                      interactive: true,
                      theme: MhjMapsMapThemes.cleanLight,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ---------- Category Dropdown ----------
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // ---------- Description ----------
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue briefly...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please add a description';
                  }
                  if (v.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ---------- Submit Button ----------
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
