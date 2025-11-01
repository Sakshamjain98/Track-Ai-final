// lib/PublishArticleScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// This import is correct, as your ManageReviewersScreen.dart file
// provides both of these classes.
import 'ManageReviewersScreen.dart' show Reviewer, ReviewerService;
import 'article_service.dart';

// Import the new ArticleService
// (This path might be different for you)

class PublishArticleScreen extends StatefulWidget {
  const PublishArticleScreen({Key? key}) : super(key: key);

  @override
  State<PublishArticleScreen> createState() => _PublishArticleScreenState();
}

class _PublishArticleScreenState extends State<PublishArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  // --- ADDED NEW CONTROLLERS ---
  final _takeawayController = TextEditingController();
  final _referencesController = TextEditingController();
  // -----------------------------
  final List<String> _categories = [
    'Reproductive Health 101',
    'Periods',
    'Fertility',
    'Pregnancy',
    'Sex',
    'Health & Wellness',
    'Mental Health'
  ];
  String? _selectedCategory;
  List<Reviewer> _reviewers = [];
  Reviewer? _selectedReviewer;

  // --- ADDED STATE FOR IMAGE & UPLOAD ---
  XFile? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchReviewers();
    _selectedCategory = _categories.first; // <-- ADD THIS LINE
  }

  Future<void> _fetchReviewers() async {
    try {
      ReviewerService.getReviewersStream().listen((reviewers) {
        if (!mounted) return;
        setState(() {
          _reviewers = reviewers;
          if (_selectedReviewer == null && _reviewers.isNotEmpty) {
            _selectedReviewer = _reviewers.first;
          }
        });
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to fetch reviewers: $e', isError: true);
      }
    }
  }

  // --- ADDED IMAGE PICKER FUNCTION ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _clearForm() {
    _titleController.clear();
    setState(() {
      _selectedImage = null;
      _selectedCategory = _categories.first; // <-- ADD THIS LINE
      if (_reviewers.isNotEmpty) {
        _selectedReviewer = _reviewers.first;
      }
    });    _contentController.clear();
    // --- CLEAR NEW FIELDS ---
    _takeawayController.clear();
    _referencesController.clear();
    // ------------------------
    setState(() {
      _selectedImage = null;
      if (_reviewers.isNotEmpty) {
        _selectedReviewer = _reviewers.first;
      }
    });
  }

  // --- UPDATED PUBLISH FUNCTION ---
  Future<void> _publishArticle() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedReviewer == null ||
        _selectedImage == null ||
        _selectedCategory == null ||
        // --- ADDED VALIDATION ---
        _takeawayController.text.isEmpty ||
        _referencesController.text.isEmpty) {

      // ------------------------
      _showSnackBar(
          'Please fill all fields, select a reviewer, and add a cover image',
          isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // --- Helper to split references ---
      final List<String> referencesList = _referencesController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      // --------------------------------

      // Call the new service
      await ArticleService.createArticle(
        title: _titleController.text,
        category: _selectedCategory!,
        content: _contentController.text,
        reviewer: _selectedReviewer!,
        imageFile: _selectedImage!,
        // --- PASS NEW DATA ---
        takeaway: _takeawayController.text,
        references: referencesList,
        // ---------------------
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      _clearForm();
      if (mounted) {
        _showSnackBar('Article published successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to publish article: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Publish New Article',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_titleController, 'Title'),
            _buildCategoryDropdown(),
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildReviewerDropdown(),
            _buildTextField(_contentController,
                'Full Article Content (Markdown supported)',
                maxLines: 15),
            // --- ADDED NEW FIELDS ---
            _buildTextField(_takeawayController, 'The takeaway', maxLines: 5),
            _buildTextField(
                _referencesController, 'References (one per line)',
                maxLines: 5),
            // ------------------------
            const SizedBox(height: 16),
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  color: const Color(0xFFE91E63),
                  backgroundColor: const Color(0xFFF5E6F1),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _publishArticle,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publish Article'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          hint: const Text('Select a Category'),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
  // -----------------
  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE91E63)),
          ),
        ),
      ),
    );
  }

  // --- ADDED IMAGE PICKER WIDGET ---
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImage == null
                ? Colors.grey[400]!
                : const Color(0xFFE91E63),
            width: 1,
          ),
        ),
        child: _selectedImage != null
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(_selectedImage!.path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            )
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add cover image',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Reviewer>(
          isExpanded: true,
          value: _selectedReviewer,
          hint: const Text('Select a Reviewer'),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (Reviewer? newValue) {
            setState(() {
              _selectedReviewer = newValue;
            });
          },
          items:
          _reviewers.map<DropdownMenuItem<Reviewer>>((Reviewer reviewer) {
            return DropdownMenuItem<Reviewer>(
              value: reviewer,
              child: Text(reviewer.name),
            );
          }).toList(),
        ),
      ),
    );
  }
}