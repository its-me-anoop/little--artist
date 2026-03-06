import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/database.dart';
import '../../components/chips/tag_picker_view.dart';
import '../../providers/children_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/image_processing_service.dart';
import '../../utils/brand_tokens.dart';

/// Modal sheet for creating or editing an artwork.
///
/// When [existingArtwork] is null a new artwork is created; otherwise the
/// existing artwork is updated.
class AddArtworkView extends ConsumerStatefulWidget {
  /// Pre-selected child ID (optional).
  final int? childId;

  /// If non-null the sheet operates in edit mode.
  final Artwork? existingArtwork;

  const AddArtworkView({
    super.key,
    this.childId,
    this.existingArtwork,
  });

  @override
  ConsumerState<AddArtworkView> createState() => _AddArtworkViewState();
}

class _AddArtworkViewState extends ConsumerState<AddArtworkView> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  int? _selectedChildId;
  List<String> _selectedTags = [];
  List<String> _availableTags = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingArtwork != null;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;

    if (_isEditing) {
      final artwork = widget.existingArtwork!;
      _titleController.text = artwork.title;
      _captionController.text = artwork.caption;
      _imageBytes = artwork.imageData;
      _selectedChildId = artwork.childId;
      _loadExistingTags(artwork.id);
    }

    _loadAvailableTags();
  }

  Future<void> _loadExistingTags(int artworkId) async {
    final db = ref.read(databaseProvider);
    final tags = await db.tagDao.getTagsForArtwork(artworkId);
    if (mounted) {
      setState(() {
        _selectedTags = tags.map((t) => t.name).toList();
      });
    }
  }

  Future<void> _loadAvailableTags() async {
    final db = ref.read(databaseProvider);
    final tags = await db.tagDao.getAllTags();
    if (mounted) {
      setState(() {
        _availableTags = tags.map((t) => t.name).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // MARK: - Image Picking
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  // ---------------------------------------------------------------------------
  // MARK: - Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_imageBytes == null || _selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _imageBytes == null
                ? 'Please add an image'
                : 'Please select a child',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(firestoreRepositoryProvider);
      final processed =
          await ImageProcessingService().processForStorage(_imageBytes!);

      if (_isEditing) {
        await repo.updateArtwork(
          widget.existingArtwork!,
          title: _titleController.text.trim(),
          caption: _captionController.text.trim(),
          imageData: processed.imageData,
          tagNames: _selectedTags,
        );
      } else {
        await repo.createArtwork(
          title: _titleController.text.trim(),
          caption: _captionController.text.trim(),
          imageData: processed.imageData,
          thumbnailData: processed.thumbnailData,
          childId: _selectedChildId!,
          tagNames: _selectedTags,
        );
      }

      HapticService.success();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Brand.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Brand.radiusSheet),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Brand.softTan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Brand.screenPadding,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: Brand.bodyFont.copyWith(color: Brand.warmGray),
                      ),
                    ),
                    Text(
                      _isEditing ? 'Edit Artwork' : 'New Artwork',
                      style: Brand.title3Font.copyWith(color: Brand.charcoal),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Brand.screenPadding,
                  ),
                  children: [
                    const SizedBox(height: 8),

                    // Image section
                    _buildImageSection(),

                    const SizedBox(height: Brand.sectionSpacing),

                    // Title
                    TextField(
                      controller: _titleController,
                      style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                      decoration: _fieldDecoration('Title'),
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 16),

                    // Caption
                    TextField(
                      controller: _captionController,
                      style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                      decoration: _fieldDecoration('Caption'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    // Child selector
                    _buildChildSelector(childrenAsync),

                    const SizedBox(height: 16),

                    // Tags
                    Text(
                      'Tags',
                      style:
                          Brand.headlineFont.copyWith(color: Brand.charcoal),
                    ),
                    const SizedBox(height: 8),
                    TagPickerView(
                      selectedTags: _selectedTags,
                      availableTags: _availableTags,
                      onTagsChanged: (tags) {
                        setState(() => _selectedTags = tags);
                      },
                    ),

                    const SizedBox(height: Brand.sectionSpacing),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Brand.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Brand.disabled,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Brand.radiusButton),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save Artwork',
                                style: Brand.headlineFont
                                    .copyWith(color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: Brand.formPadding),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Image Section
  // ---------------------------------------------------------------------------

  Widget _buildImageSection() {
    if (_imageBytes != null) {
      return GestureDetector(
        onTap: () => _showImageSourcePicker(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Brand.radiusImage),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SourceButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(width: 24),
        _SourceButton(
          icon: Icons.photo_library,
          label: 'Photos',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(width: 24),
        _SourceButton(
          icon: Icons.document_scanner,
          label: 'Scanner',
          onTap: () => _pickImage(ImageSource.camera),
        ),
      ],
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photos'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Remove image'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _imageBytes = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Child Selector
  // ---------------------------------------------------------------------------

  Widget _buildChildSelector(AsyncValue<List<Child>> childrenAsync) {
    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return Text(
            'Add a child profile first',
            style: Brand.bodyFont.copyWith(color: Brand.warmGray),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child',
              style: Brand.headlineFont.copyWith(color: Brand.charcoal),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children.map((child) {
                final isSelected = _selectedChildId == child.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChildId = child.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Brand.primary : Brand.surface,
                      borderRadius:
                          BorderRadius.circular(Brand.radiusButton),
                      border: isSelected
                          ? null
                          : Border.all(color: Brand.softTan),
                    ),
                    child: Text(
                      child.name,
                      style: Brand.subheadlineFont.copyWith(
                        color: isSelected ? Colors.white : Brand.charcoal,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, s) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Helpers
  // ---------------------------------------------------------------------------

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Brand.bodyFont.copyWith(color: Brand.warmGray),
      filled: true,
      fillColor: Brand.surface,
      contentPadding: const EdgeInsets.all(Brand.fieldPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusField),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusField),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Brand.radiusField),
        borderSide: const BorderSide(color: Brand.primary, width: 1.5),
      ),
    );
  }
}

// MARK: - Source Button

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Brand.sourceButtonSize,
            height: Brand.sourceButtonSize,
            decoration: BoxDecoration(
              color: Brand.surface,
              shape: BoxShape.circle,
              boxShadow: Brand.cardShadow,
            ),
            child: Icon(
              icon,
              size: 24,
              color: Brand.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Brand.captionFont.copyWith(color: Brand.warmGray),
          ),
        ],
      ),
    );
  }
}
