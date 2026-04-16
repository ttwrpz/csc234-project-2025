import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../config/constants.dart';
import '../../models/mood_entry.dart';
import '../../models/mood_type.dart';
import '../../providers/mood_provider.dart';
import '../../utils/date_helpers.dart';
import '../../utils/error_handler.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/mood_chip.dart';
import '../../widgets/attachment_preview.dart';

class EntryDetailScreen extends StatefulWidget {
  final MoodEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _isEditing = false;
  MoodType? _editMood;
  late TextEditingController _editTextController;
  Uint8List? _newAttachmentData;
  String? _newAttachmentFileName;
  String? _newAttachmentContentType;
  String? _newAttachmentType;
  bool _removeAttachment = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _editTextController = TextEditingController(text: widget.entry.text);
    _editMood = MoodType.fromString(widget.entry.mood);
    _initVideo();
  }

  void _initVideo() {
    if (widget.entry.attachmentType == 'video' &&
        widget.entry.attachmentUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.entry.attachmentUrl!),
      )..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _editTextController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _editMood = MoodType.fromString(widget.entry.mood);
        _editTextController.text = widget.entry.text;
        _newAttachmentData = null;
        _removeAttachment = false;
      }
    });
  }

  Future<void> _saveEdit() async {
    if (_editMood == null) return;

    final moodProvider = context.read<MoodProvider>();
    final success = await moodProvider.updateEntry(
      entry: widget.entry,
      moodType: _editMood!,
      text: _editTextController.text.trim(),
      newAttachmentData: _newAttachmentData,
      newAttachmentFileName: _newAttachmentFileName,
      newAttachmentContentType: _newAttachmentContentType,
      newAttachmentType: _newAttachmentType,
      removeAttachment: _removeAttachment,
    );

    if (success && mounted) {
      ErrorHandler.showSuccessSnackBar(context, 'Entry updated.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final moodProvider = context.read<MoodProvider>();
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Entry',
      message:
          'Are you sure you want to delete this entry? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    final success = await moodProvider.deleteEntry(widget.entry);
    if (success && mounted) {
      ErrorHandler.showSuccessSnackBar(context, 'Entry deleted.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickNewImage() async {
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
        ErrorHandler.showErrorSnackBar(context, 'File is too large. Maximum 5MB.');
      }
      return;
    }
    setState(() {
      _newAttachmentData = data;
      _newAttachmentFileName = picked.name;
      _newAttachmentContentType = picked.mimeType ?? 'image/jpeg';
      _newAttachmentType = 'image';
      _removeAttachment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = MoodType.fromString(widget.entry.mood);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Mood Entry'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
          ] else ...[
            TextButton(onPressed: _toggleEdit, child: const Text('Cancel')),
            TextButton(onPressed: _saveEdit, child: const Text('Save')),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _isEditing ? _buildEditView() : _buildDetailView(mood),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(MoodType? mood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mood display
        Center(
          child: Column(
            children: [
              Hero(
                tag: 'mood_emoji_${widget.entry.id}',
                child: Text(
                  mood?.emoji ?? '\u{2753}',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mood?.label ?? widget.entry.mood,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Date/time
        Center(
          child: Text(
            DateHelpers.formatFull(widget.entry.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Text content
        if (widget.entry.text.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.entry.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Attachment
        if (widget.entry.attachmentUrl != null) ...[
          if (widget.entry.attachmentType == 'video')
            _buildVideoPlayer()
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.entry.attachmentUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: AnimatedOpacity(
                opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodType.values.map((mood) {
            return MoodChip(
              moodType: mood,
              isSelected: _editMood == mood,
              onTap: () => setState(() => _editMood = mood),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Notes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: _editTextController,
          maxLines: 4,
          maxLength: AppConstants.maxTextLength,
          decoration: const InputDecoration(hintText: 'How are you feeling?'),
        ),
        const SizedBox(height: 16),

        // Attachment management
        Text('Attachment', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_newAttachmentData != null)
          AttachmentPreview(
            localData: _newAttachmentData,
            type: _newAttachmentType,
            size: 120,
            onRemove: () => setState(() {
              _newAttachmentData = null;
              _newAttachmentFileName = null;
              _newAttachmentContentType = null;
              _newAttachmentType = null;
            }),
          )
        else if (widget.entry.attachmentUrl != null && !_removeAttachment)
          AttachmentPreview(
            networkUrl: widget.entry.attachmentUrl,
            type: widget.entry.attachmentType,
            size: 120,
            onRemove: () => setState(() => _removeAttachment = true),
          )
        else
          OutlinedButton.icon(
            onPressed: _pickNewImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Add Photo'),
          ),
      ],
    );
  }
}
