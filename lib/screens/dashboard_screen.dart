import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GeminiDiseaseService _diseaseService = GeminiDiseaseService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String? _diagnosisResult;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('[LeafDoctor] Opening image picker: $source');
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('[LeafDoctor] Image picking cancelled by user.');
        return;
      }

      final file = File(pickedFile.path);
      debugPrint('[LeafDoctor] Image selected: ${file.path} (${await file.length()} bytes)');

      setState(() {
        _selectedImage = file;
        _isLoading = true;
        _diagnosisResult = null;
        _errorMessage = null;
      });

      final result = await _diseaseService.analyzeLeaf(file);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _diagnosisResult = result;
      });
      debugPrint('[LeafDoctor] Analysis complete.');
    } catch (e, stackTrace) {
      debugPrint('[LeafDoctor] Error during pick/analysis: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to pick or analyze image: $e';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Tomato Leaf Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Take a Photo (Camera)'),
                subtitle: const Text('Capture live leaf from plant'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _isLoading = false;
      _diagnosisResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_hospital_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'CropDoc AI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_selectedImage != null || _diagnosisResult != null)
            IconButton(
              tooltip: 'Reset Scan',
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageCard(theme),
              const SizedBox(height: 20),
              _buildDiagnosisSection(theme),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showImageSourceDialog,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan Leaf'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildImageCard(ThemeData theme) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isLoading ? null : _showImageSourceDialog,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cached, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Change Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: _showImageSourceDialog,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Leaf Image Selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to snap a photo or choose from gallery',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDiagnosisSection(ThemeData theme) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Analyzing Leaf with Gemini Vision...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking for blight, spots, viruses, and nutritional deficiencies',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Detection Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ],
          ),
        ),
      );
    }

    if (_diagnosisResult != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Diagnostic Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              SelectableText(
                _diagnosisResult!,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default empty placeholder advice
    return Card(
      elevation: 0,
      color: Colors.green.shade50.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text(
                  'Quick Guide for Best Results',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• Place the leaf flat with good natural lighting.\n'
              '• Focus clearly on the discolored spots or damaged areas.\n'
              '• Avoid blurry or far-away shots for accurate AI diagnosis.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.green.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
