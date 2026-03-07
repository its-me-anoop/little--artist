import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';

/// Full-screen add-child flow styled to match the SwiftUI implementation.
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

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) {
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() => _avatarImageData = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(firestoreRepositoryProvider)
          .createChild(
            name: name,
            avatarColor: _selectedColor,
            avatarImageData: _avatarImageData,
          );
      HapticService.success();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameController.text.trim().isEmpty
        ? '?'
        : _nameController.text.trim()[0].toUpperCase();
    final avatarColor = Color(int.parse('FF$_selectedColor', radix: 16));

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        title: Text(
          'New Little Artist',
          style: Brand.title2Font.copyWith(color: Brand.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _ChildProfileBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  _buildFormCard(initial, avatarColor),
                  const SizedBox(height: 24),
                  _buildAddButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(String initial, Color avatarColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _avatarImageData == null
                ? null
                : () => setState(() => _avatarImageData = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor,
                    boxShadow: Brand.avatarShadow,
                  ),
                  child: _avatarImageData != null
                      ? ClipOval(
                          child: Image.memory(
                            _avatarImageData!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: Brand.displayFont.copyWith(
                              color: Colors.white,
                              fontSize: 48,
                            ),
                          ),
                        ),
                ),
                if (_avatarImageData != null)
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(Icons.cancel, color: Brand.dustyRose, size: 28),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onPressed: () => _pickAvatar(ImageSource.camera),
              ),
              const SizedBox(width: 16),
              _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onPressed: () => _pickAvatar(ImageSource.gallery),
              ),
              const SizedBox(width: 16),
              const _SourceButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Create',
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            style: Brand.title3Font.copyWith(color: Brand.charcoal),
            decoration: InputDecoration(
              hintText: "Child's name",
              hintStyle: Brand.title3Font.copyWith(color: Brand.warmGray),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.82),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Brand.softTan, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Brand.primary, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          Text(
            'Pick a color',
            style: Brand.subheadlineFont.copyWith(color: Brand.warmGray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (final hex in Brand.avatarColors)
                _ColorSwatch(
                  hex: hex,
                  isSelected: hex == _selectedColor,
                  onTap: () => setState(() => _selectedColor = hex),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    final buttonColor = _isNameValid ? Brand.primary : Brand.disabled;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [buttonColor, buttonColor.withValues(alpha: 0.88)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isNameValid && !_isSaving ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Add Child',
                  style: Brand.title2Font.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ChildProfileBackground extends StatelessWidget {
  const _ChildProfileBackground();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned.fill(child: Container(color: Brand.cream)),
            Positioned(
              left: -width * 0.15,
              top: -height * 0.12,
              child: Container(
                width: width * 1.25,
                height: width * 1.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.primary.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(
              right: -width * 0.05,
              bottom: -height * 0.05,
              child: Container(
                width: width * 1.05,
                height: width * 1.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.sky.withValues(alpha: 0.12),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Brand.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: Brand.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Brand.captionFont.copyWith(color: Brand.warmGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF$hex', radix: 16));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Center(
                child: Icon(Icons.check, color: Colors.white, size: 18),
              )
            : null,
      ),
    );
  }
}
