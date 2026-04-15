import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/mood_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/mood_chip.dart';
import '../../widgets/attachment_preview.dart';
import '../../widgets/success_animation.dart';

class LogMoodScreen extends StatefulWidget {
  const LogMoodScreen({super.key});

  @override
  State<LogMoodScreen> createState() => _LogMoodScreenState();
}

class _LogMoodScreenState extends State<LogMoodScreen> {
  MoodType? _selectedMood;
  final _textController = TextEditingController();
  Uint8List? _attachmentData;
  String? _attachmentFileName;
  String? _attachmentContentType;
  String? _attachmentType; // "image" or "video"
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;

    final data = await picked.readAsBytes();
    if (data.length > AppConstants.maxAttachmentSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Maximum 5MB.')),
        );
      }
      return;
    }

    setState(() {
      _attachmentData = data;
      _attachmentFileName = picked.name;
      _attachmentContentType = picked.mimeType ?? 'image/jpeg';
      _attachmentType = 'image';
    });
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: AppConstants.maxVideoSeconds),
    );
    if (picked == null) return;

    final data = await picked.readAsBytes();
    if (data.length > AppConstants.maxAttachmentSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Maximum 5MB.')),
        );
      }
      return;
    }

    setState(() {
      _attachmentData = data;
      _attachmentFileName = picked.name;
      _attachmentContentType = picked.mimeType ?? 'video/mp4';
      _attachmentType = 'video';
    });
  }

  void _removeAttachment() {
    setState(() {
      _attachmentData = null;
      _attachmentFileName = null;
      _attachmentContentType = null;
      _attachmentType = null;
    });
  }

  Future<void> _save() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a mood.')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final moodProvider = context.read<MoodProvider>();

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Save Mood Entry',
      message: 'Save this mood entry?',
      confirmText: 'Save',
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);

    final success = await moodProvider.saveMoodEntry(
      userId: auth.user!.uid,
      moodType: _selectedMood!,
      text: _textController.text.trim(),
      attachmentData: _attachmentData,
      attachmentFileName: _attachmentFileName,
      attachmentContentType: _attachmentContentType,
      attachmentType: _attachmentType,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      // Show success animation overlay
      await showSuccessAnimation(context);
      // Reset form
      if (mounted) {
        setState(() {
          _selectedMood = null;
          _textController.clear();
          _removeAttachment();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Mood')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood selector
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MoodType.values.map((mood) {
                    return MoodChip(
                      moodType: mood,
                      isSelected: _selectedMood == mood,
                      onTap: () => setState(() => _selectedMood = mood),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Text entry
                Text(
                  'Tell us more (optional)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  maxLength: AppConstants.maxTextLength,
                  decoration: const InputDecoration(
                    hintText: 'How are you feeling today?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Attachment
                Text(
                  'Add Photo or Video',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (_attachmentData != null)
                  AttachmentPreview(
                    localData: _attachmentData,
                    type: _attachmentType,
                    size: 120,
                    onRemove: _removeAttachment,
                  )
                else
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Photo'),
                      ),
                      const SizedBox(width: 8),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Video'),
                        ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Mood Entry'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
