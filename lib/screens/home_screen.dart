import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final AiService _aiService = AiService();

  File? _originalImage;
  Uint8List? _enhancedImageBytes;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile == null) {
        _showSnackBar('No image selected.');
        return;
      }

      setState(() {
        _originalImage = File(pickedFile.path);
        _enhancedImageBytes = null;
      });

      _showSnackBar('Image selected successfully.');
    } catch (_) {
      _showSnackBar('Could not pick image. Please try again.');
    }
  }

  Future<void> _showSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enhanceImage() async {
    if (_originalImage == null) {
      _showSnackBar('Please select an image first.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final Uint8List enhancedBytes =
          await _aiService.enhanceImage(_originalImage!);

      if (!mounted) return;

      setState(() {
        _enhancedImageBytes = enhancedBytes;
      });
      _showSnackBar('Image enhanced successfully.');
    } on AiServiceException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Something went wrong while enhancing image.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveEnhancedImage() async {
    if (_enhancedImageBytes == null) {
      _showSnackBar('No enhanced image available to save.');
      return;
    }

    try {
      final String savedPath = await _aiService.saveEnhancedImage(
        _enhancedImageBytes!,
      );
      if (!mounted) return;
      _showSnackBar('Enhanced image saved to: $savedPath');
    } on AiServiceException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not save image. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo Enhancer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _showSourcePicker,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Pick Image'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _enhanceImage,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Enhance Image'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _saveEnhancedImage,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Save Enhanced Image'),
              ),
              const SizedBox(height: 16),
              if (_isProcessing) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Uploading and enhancing image...',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _buildImagePreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_originalImage == null) {
      return const Center(
        child: Text(
          'Select an image to get started.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ImagePanel(
            title: 'Before',
            child: Image.file(
              _originalImage!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ImagePanel(
            title: 'After',
            child: _enhancedImageBytes == null
                ? const Center(
                    child: Text(
                      'Enhanced image will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Image.memory(
                    _enhancedImageBytes!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey.shade200,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}