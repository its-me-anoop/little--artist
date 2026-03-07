import 'dart:ui';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/haptic_service.dart';
import '../../utils/brand_tokens.dart';
import '../paywall_view.dart';
import 'share_management_view.dart';

/// Edit-child flow aligned to the SwiftUI profile editor.
class EditChildView extends ConsumerStatefulWidget {
  const EditChildView({super.key, required this.childId});

  final int childId;

  @override
  ConsumerState<EditChildView> createState() => _EditChildViewState();
}

class _EditChildViewState extends ConsumerState<EditChildView> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  Child? _child;
  String _selectedColor = Brand.defaultAvatarColor;
  Uint8List? _avatarImageData;
  String? _activeShareId;
  bool _clearAvatarImage = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isLeavingShare = false;

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;
  bool get _isChildShared =>
      _child != null &&
      (_child!.isShared ||
          (_child!.firestoreId != null && _activeShareId != null));
  bool get _isCurrentUserOwner => _child != null && !_child!.isShared;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadChild() async {
    final db = ref.read(databaseProvider);
    final child = await db.childDao.getChildById(widget.childId);
    if (child == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    String? activeShareId;
    if (child.firestoreId != null) {
      final share = await ref
          .read(firestoreRepositoryProvider)
          .findShare(child.firestoreId!);
      if (share?.status == 'active') {
        activeShareId = share!.shareId;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _child = child;
      _nameController.text = child.name;
      _selectedColor = child.avatarColor;
      _avatarImageData = child.avatarImageData;
      _activeShareId = activeShareId;
      _isLoading = false;
    });
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
    setState(() {
      _avatarImageData = bytes;
      _clearAvatarImage = false;
    });
  }

  Future<void> _save() async {
    final child = _child;
    if (child == null || !_isNameValid || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(firestoreRepositoryProvider)
          .updateChild(
            child,
            name: _nameController.text.trim(),
            avatarColor: _selectedColor,
            avatarImageData: _avatarImageData,
            clearAvatarImage: _clearAvatarImage,
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

  Future<void> _deleteChild() async {
    final child = _child;
    if (child == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this child profile?'),
        content: Text(
          _isChildShared
              ? 'This will permanently delete ${child.name} and all their artworks for everyone this profile is shared with.'
              : 'All artworks for ${child.name} will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(firestoreRepositoryProvider).deleteChild(widget.childId);
    HapticService.warning();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _leaveSharedProfile() async {
    final child = _child;
    if (child == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this shared profile?'),
        content: Text(
          "${child.name}'s profile and all artworks will be removed from your device. The owner will keep their copy.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isLeavingShare = true);

    try {
      if (_activeShareId != null) {
        await ref.read(firestoreRepositoryProvider).leaveShare(_activeShareId!);
      }
      await ref.read(databaseProvider).childDao.deleteChild(widget.childId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLeavingShare = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave: $e')));
    }
  }

  Future<void> _presentSharing() async {
    final child = _child;
    if (child == null || _isSharing) {
      return;
    }

    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const PaywallView()));
      return;
    }

    setState(() => _isSharing = true);

    try {
      var shareId = _activeShareId;
      var isNewShare = false;
      final repo = ref.read(firestoreRepositoryProvider);

      if (shareId == null && child.firestoreId != null) {
        final existingShare = await repo.findShare(child.firestoreId!);
        if (existingShare?.status == 'active') {
          shareId = existingShare!.shareId;
        }
      }

      if (shareId == null) {
        shareId = await repo.shareChild(child.id);
        isNewShare = true;
      }

      if (!mounted) {
        return;
      }

      final freshChild =
          await ref.read(databaseProvider).childDao.getChildById(child.id) ??
          child;
      setState(() {
        _child = freshChild;
        _activeShareId = shareId;
      });
      await _openShareManagement(freshChild, shareId, isNewShare: isNewShare);
      await _loadChild();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sharing unavailable: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _openShareManagement(
    Child child,
    String shareId, {
    required bool isNewShare,
  }) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShareManagementView(
          child: child,
          shareId: shareId,
          isNewShare: isNewShare,
          onStoppedSharing: () async {
            final db = ref.read(databaseProvider);
            final latestChild = await db.childDao.getChildById(child.id);
            if (latestChild != null) {
              await db.childDao.updateChild(
                latestChild.copyWith(isShared: false),
              );
            }
            if (mounted) {
              setState(() => _activeShareId = null);
            }
          },
          onLeftProfile: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    final isPremium = ref.watch(isPremiumProvider);

    if (_isLoading || child == null) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(
          backgroundColor: Brand.cream,
          title: Text(
            'Edit Profile',
            style: Brand.title2Font.copyWith(color: Brand.charcoal),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final initial = _nameController.text.trim().isEmpty
        ? '?'
        : _nameController.text.trim()[0].toUpperCase();
    final avatarColor = Color(int.parse('FF$_selectedColor', radix: 16));

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        title: Text(
          'Edit Profile',
          style: Brand.title2Font.copyWith(color: Brand.charcoal),
        ),
      ),
      body: Stack(
        children: [
          const _ChildProfileBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  _buildFormCard(initial, avatarColor, isPremium),
                  const SizedBox(height: 28),
                  if (_isChildShared && !_isCurrentUserOwner)
                    _buildDestructiveButton(
                      label: 'Leave Profile',
                      isBusy: _isLeavingShare,
                      icon: Icons.person_remove_alt_1_rounded,
                      onPressed: _leaveSharedProfile,
                    )
                  else
                    _buildDestructiveButton(
                      label: 'Delete Profile',
                      onPressed: _deleteChild,
                    ),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(String initial, Color avatarColor, bool isPremium) {
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
                : () => setState(() {
                    _avatarImageData = null;
                    _clearAvatarImage = true;
                  }),
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
          if (isPremium) ...[
            const SizedBox(height: 26),
            OutlinedButton(
              onPressed: _isSharing ? null : _presentSharing,
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.sky,
                side: const BorderSide(color: Brand.sky, width: 1.5),
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
              ),
              child: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isChildShared
                              ? Icons.people_alt_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isChildShared ? 'Manage Sharing' : 'Share Profile',
                          style: Brand.headlineFont.copyWith(color: Brand.sky),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite another parent to view and edit this profile',
              textAlign: TextAlign.center,
              style: Brand.captionFont.copyWith(color: Brand.warmGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDestructiveButton({
    required String label,
    required VoidCallback onPressed,
    bool isBusy = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Brand.dustyRose,
          side: const BorderSide(color: Brand.dustyRose, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
        ),
        child: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Brand.dustyRose,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: Brand.headlineFont.copyWith(color: Brand.dustyRose),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isNameValid && !_isSaving ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isNameValid ? Brand.primary : Brand.disabled,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Brand.disabled,
          minimumSize: const Size.fromHeight(58),
          elevation: 0,
          shape: const StadiumBorder(),
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
                'Save Changes',
                style: Brand.headlineFont.copyWith(color: Colors.white),
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
