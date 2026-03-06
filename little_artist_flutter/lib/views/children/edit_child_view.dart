import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';

/// Edit screen for an existing child profile.
class EditChildView extends ConsumerStatefulWidget {
  final int childId;

  const EditChildView({
    super.key,
    required this.childId,
  });

  @override
  ConsumerState<EditChildView> createState() => _EditChildViewState();
}

class _EditChildViewState extends ConsumerState<EditChildView> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedColor = Brand.defaultAvatarColor;
  Uint8List? _avatarImageData;
  bool _isSaving = false;
  bool _isLoading = true;
  Child? _child;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    final db = ref.read(databaseProvider);
    final child = await db.childDao.getChildById(widget.childId);
    if (child == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (mounted) {
      setState(() {
        _child = child;
        _nameController.text = child.name;
        _selectedColor = child.avatarColor;
        _avatarImageData = child.avatarImageData;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // MARK: - Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarImageData = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    if (_child == null) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(firestoreRepositoryProvider);
      await repo.updateChild(
        _child!,
        name: name,
        avatarColor: _selectedColor,
        avatarImageData: _avatarImageData,
      );
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

  Future<void> _deleteChild() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Child'),
        content: const Text(
          'This will permanently delete this child profile and all their artwork. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(firestoreRepositoryProvider);
    await repo.deleteChild(widget.childId);
    HapticService.warning();
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // MARK: - Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(
          backgroundColor: Brand.cream,
          title: Text(
            'Edit Child',
            style: Brand.title3Font.copyWith(color: Brand.charcoal),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final initial =
        _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()[0].toUpperCase()
            : '?';
    final avatarColorValue =
        Color(int.parse('FF$_selectedColor', radix: 16));

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Edit Child',
          style: Brand.title3Font.copyWith(color: Brand.charcoal),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar preview
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: Brand.avatarPreviewSize,
                  height: Brand.avatarPreviewSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColorValue,
                    boxShadow: Brand.avatarShadow,
                  ),
                  child: _avatarImageData != null
                      ? ClipOval(
                          child: Image.memory(
                            _avatarImageData!,
                            fit: BoxFit.cover,
                            width: Brand.avatarPreviewSize,
                            height: Brand.avatarPreviewSize,
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: Brand.displayFont.copyWith(
                              color: Colors.white,
                              fontSize: 44,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // "Change Photo" label
            Center(
              child: TextButton.icon(
                onPressed: _pickAvatar,
                icon: Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                  color: Brand.primary,
                ),
                label: Text(
                  'Change Photo',
                  style: Brand.captionFont.copyWith(color: Brand.primary),
                ),
              ),
            ),

            const SizedBox(height: Brand.sectionSpacing),

            // Name field
            TextField(
              controller: _nameController,
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
              decoration: InputDecoration(
                hintText: 'Name',
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
                  borderSide:
                      const BorderSide(color: Brand.primary, width: 1.5),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: Brand.sectionSpacing),

            // Color picker
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Avatar Color',
                style: Brand.headlineFont.copyWith(color: Brand.charcoal),
              ),
            ),
            const SizedBox(height: 12),
            _buildColorPicker(),

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
                    borderRadius: BorderRadius.circular(Brand.radiusButton),
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
                        'Save Changes',
                        style:
                            Brand.headlineFont.copyWith(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _deleteChild,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Brand.dustyRose,
                  side: const BorderSide(color: Brand.dustyRose),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Brand.radiusButton),
                  ),
                ),
                child: Text(
                  'Delete Child',
                  style:
                      Brand.headlineFont.copyWith(color: Brand.dustyRose),
                ),
              ),
            ),

            const SizedBox(height: Brand.formPadding),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Color Picker
  // ---------------------------------------------------------------------------

  Widget _buildColorPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Brand.avatarColors.map((hex) {
          final isSelected = hex == _selectedColor;
          final color = Color(int.parse('FF$hex', radix: 16));
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedColor = hex),
              child: Container(
                width: Brand.colorCircleSize,
                height: Brand.colorCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isSelected
                      ? Border.all(color: Brand.charcoal, width: 2.5)
                      : null,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 20,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
