import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/firestore_repository.dart';
import '../../utils/brand_tokens.dart';

/// Sharing management flow copied from the SwiftUI structure.
class ShareManagementView extends ConsumerStatefulWidget {
  const ShareManagementView({
    super.key,
    required this.child,
    required this.shareId,
    this.isNewShare = false,
    this.onStoppedSharing,
    this.onLeftProfile,
  });

  final Child child;
  final String shareId;
  final bool isNewShare;
  final Future<void> Function()? onStoppedSharing;
  final VoidCallback? onLeftProfile;

  @override
  ConsumerState<ShareManagementView> createState() =>
      _ShareManagementViewState();
}

class _ShareManagementViewState extends ConsumerState<ShareManagementView> {
  List<ShareParticipant> _participants = const [];
  bool _isLoadingParticipants = true;
  bool _isStoppingShare = false;
  bool _isLeavingProfile = false;

  bool get _isCurrentUserOwner => !widget.child.isShared;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = await ref
          .read(firestoreRepositoryProvider)
          .fetchParticipants(widget.shareId);
      if (!mounted) {
        return;
      }
      setState(() {
        _participants = participants;
        _isLoadingParticipants = false;
      });
      if (widget.isNewShare) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _presentShareLink(),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingParticipants = false);
    }
  }

  Future<void> _presentShareLink() async {
    final text =
        "Join me on Artling to see ${widget.child.name}'s artwork! Open the app, go to Settings -> Join Shared Profile, and enter this code:\n\n${widget.shareId}";
    await Share.share(text);
  }

  Future<void> _stopSharing() async {
    if (_isStoppingShare) {
      return;
    }

    setState(() => _isStoppingShare = true);
    try {
      await ref.read(firestoreRepositoryProvider).stopSharing(widget.shareId);
      await ref
          .read(databaseProvider)
          .childDao
          .updateChild(widget.child.copyWith(isShared: false));
      await widget.onStoppedSharing?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isStoppingShare = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _leaveProfile() async {
    if (_isLeavingProfile) {
      return;
    }

    setState(() => _isLeavingProfile = true);
    try {
      await ref.read(firestoreRepositoryProvider).leaveShare(widget.shareId);
      await ref.read(databaseProvider).childDao.deleteChild(widget.child.id);
      widget.onLeftProfile?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLeavingProfile = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.child.name.isEmpty
        ? '?'
        : widget.child.name[0].toUpperCase();
    final avatarColor = Color(
      int.parse('FF${widget.child.avatarColor}', radix: 16),
    );

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        title: Text(
          'Sharing',
          style: Brand.title2Font.copyWith(color: Brand.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Done',
              style: Brand.bodyFont.copyWith(
                color: Brand.charcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            _buildChildHeader(initial, avatarColor),
            const SizedBox(height: 28),
            _buildPeopleSection(),
            const SizedBox(height: 24),
            _buildShareOptionsSection(),
            const SizedBox(height: 24),
            if (_isCurrentUserOwner)
              _buildDangerButton(
                label: 'Stop Sharing',
                isBusy: _isStoppingShare,
                onPressed: _stopSharing,
              )
            else
              _buildDangerButton(
                label: 'Leave Profile',
                isBusy: _isLeavingProfile,
                onPressed: _leaveProfile,
                icon: Icons.person_remove_alt_1_rounded,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildHeader(String initial, Color avatarColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
            boxShadow: Brand.cardShadow,
          ),
          child: widget.child.avatarImageData != null
              ? ClipOval(
                  child: Image.memory(
                    widget.child.avatarImageData!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: Brand.displayFont.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.child.name,
          style: Brand.title2Font.copyWith(color: Brand.charcoal),
        ),
      ],
    );
  }

  Widget _buildPeopleSection() {
    return _LabeledCardSection(
      title: 'People',
      child: Column(
        children: [
          _PersonRow(
            icon: Icons.account_circle_rounded,
            iconColor: Brand.primary,
            title: _isCurrentUserOwner ? 'You' : 'Owner',
            subtitle: 'Owner',
          ),
          if (_isLoadingParticipants)
            const _DividerWithInset()
          else
            const SizedBox.shrink(),
          if (_isLoadingParticipants)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading participants...',
                    style: Brand.captionFont.copyWith(color: Brand.warmGray),
                  ),
                ],
              ),
            ),
          for (final participant in _participants) ...[
            const _DividerWithInset(),
            _PersonRow(
              icon: Icons.account_circle_outlined,
              iconColor: Brand.sky,
              title:
                  '${participant.userId.substring(0, participant.userId.length.clamp(0, 8))}...',
              subtitle: _participantRoleLabel(participant.role),
              trailing: participant.acceptedAt == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Brand.primaryTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Pending',
                        style: Brand.captionFont.copyWith(color: Brand.primary),
                      ),
                    )
                  : null,
            ),
          ],
          if (_isCurrentUserOwner) ...[
            const _DividerWithInset(),
            InkWell(
              onTap: _presentShareLink,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_rounded,
                      color: Brand.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share With More People',
                      style: Brand.bodyFont.copyWith(color: Brand.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareOptionsSection() {
    return _LabeledCardSection(
      title: 'Share Options',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_note_rounded, color: Brand.sage, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'People you invite can make changes and add others.',
                style: Brand.captionFont.copyWith(color: Brand.charcoal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton({
    required String label,
    required VoidCallback onPressed,
    required bool isBusy,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Brand.surface,
          foregroundColor: Brand.dustyRose,
          disabledBackgroundColor: Brand.surface,
          disabledForegroundColor: Brand.dustyRose,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Brand.radiusCard),
          ),
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

  String _participantRoleLabel(String role) {
    switch (role) {
      case 'editor':
        return 'Can make changes';
      case 'viewer':
        return 'View only';
      default:
        return 'Participant';
    }
  }
}

class _LabeledCardSection extends StatelessWidget {
  const _LabeledCardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Brand.captionFont.copyWith(
              color: Brand.warmGray,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(Brand.radiusCard),
            boxShadow: Brand.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Brand.captionFont.copyWith(color: Brand.warmGray),
                ),
              ],
            ),
          ),
          ...switch (trailing) {
            final Widget widget => [widget],
            null => const <Widget>[],
          },
        ],
      ),
    );
  }
}

class _DividerWithInset extends StatelessWidget {
  const _DividerWithInset();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: Brand.softTan),
    );
  }
}
