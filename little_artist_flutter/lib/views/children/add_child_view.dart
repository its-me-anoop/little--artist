import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';

/// Modal sheet for creating a new child profile.
class AddChildView extends ConsumerStatefulWidget {
  const AddChildView({super.key});

  @override
  ConsumerState<AddChildView> createState() => _AddChildViewState();
}

class _AddChildViewState extends ConsumerState<AddChildView> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedColor = Brand.defaultAvatarColor;
  Uint8List? _avatarImageData;
  bool _isSaving = false;

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

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(firestoreRepositoryProvider);
      await repo.createChild(
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

  // ---------------------------------------------------------------------------
  // MARK: - Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final initial =
        _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()[0].toUpperCase()
            : '?';
    final avatarColorValue =
        Color(int.parse('FF$_selectedColor', radix: 16));

    return Container(
      decoration: const BoxDecoration(
        color: Brand.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Brand.radiusSheet),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                      'Add Child',
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

                    // "Add Photo" label
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: Brand.primary,
                        ),
                        label: Text(
                          'Add Photo',
                          style: Brand.captionFont.copyWith(
                            color: Brand.primary,
                          ),
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
                        hintStyle:
                            Brand.bodyFont.copyWith(color: Brand.warmGray),
                        filled: true,
                        fillColor: Brand.surface,
                        contentPadding:
                            const EdgeInsets.all(Brand.fieldPadding),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Brand.radiusField),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Brand.radiusField),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Brand.radiusField),
                          borderSide: const BorderSide(
                            color: Brand.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: Brand.sectionSpacing),

                    // Color picker
                    Text(
                      'Avatar Color',
                      style:
                          Brand.headlineFont.copyWith(color: Brand.charcoal),
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
                                'Add Child',
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
