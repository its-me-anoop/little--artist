import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/database.dart';
import '../providers/artwork_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../providers/database_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/sync_provider.dart';
import '../services/gemini_usage_tracker.dart';
import '../services/notification_service.dart';
import '../services/pdf_export_service.dart';
import '../services/premium_manager.dart';
import '../utils/brand_tokens.dart';
import 'children/add_child_view.dart';
import 'children/edit_child_view.dart';
import 'paywall_view.dart';
import 'privacy_policy_view.dart';

/// SwiftUI-style settings screen with children, sync, account, and data tools.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final GeminiUsageTracker _usageTracker = GeminiUsageTracker();

  bool _aiCaptionsEnabled = true;
  bool _defaultCameraBack = true;
  bool _notificationsEnabled = false;
  bool _isRestoring = false;
  bool _isExporting = false;
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initialiseUsageTracker();
  }

  Future<void> _initialiseUsageTracker() async {
    await _usageTracker.initialise();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _aiCaptionsEnabled = prefs.getBool('aiCaptionsEnabled') ?? true;
      _defaultCameraBack = prefs.getBool('defaultCameraBack') ?? true;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _syncPreferences() async {
    await ref
        .read(firestoreRepositoryProvider)
        .syncUserPreferencesToFirestore();
  }

  Future<void> _setAiCaptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiCaptionsEnabled', value);
    if (mounted) {
      setState(() => _aiCaptionsEnabled = value);
    }
    await _syncPreferences();
  }

  Future<void> _setDefaultCameraBack(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('defaultCameraBack', value);
    if (mounted) {
      setState(() => _defaultCameraBack = value);
    }
    await _syncPreferences();
  }

  Future<void> _setNotificationsEnabled(
    bool value,
    List<Artwork> artworks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission was denied.'),
            ),
          );
        }
        return;
      }
      await NotificationService.scheduleAll(artworks);
    } else {
      await NotificationService.cancelAll();
    }

    await prefs.setBool('notificationsEnabled', value);
    if (mounted) {
      setState(() => _notificationsEnabled = value);
    }
    await _syncPreferences();
  }

  Future<void> _openAddChild(List<Child> children) async {
    if (!PremiumManager.canAddChild(children.length)) {
      await _openPaywall();
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const AddChildView(),
      ),
    );
  }

  Future<void> _openEditChild(int childId) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditChildView(childId: childId)),
    );
  }

  Future<void> _openPaywall() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PaywallView()));
  }

  Future<void> _signInWithApple() async {
    final authService = ref.read(firebaseAuthServiceProvider);
    final success = await authService.signInWithApple();
    if (!mounted) {
      return;
    }

    if (success) {
      final syncService = ref.read(syncServiceProvider);
      syncService.start();
      await ref
          .read(firestoreRepositoryProvider)
          .syncUserPreferencesToFirestore();
      await ref.read(firestoreRepositoryProvider).uploadAllLocalData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in with Apple.')));
      return;
    }

    final message = authService.authError;
    if (message == null || message.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) {
      return;
    }

    setState(() => _isRestoring = true);
    await ref.read(storeManagerProvider).restorePurchases();
    if (mounted) {
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _joinSharedProfile() async {
    final controller = TextEditingController();

    final shareCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Shared Profile'),
        content: TextField(
          controller: controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(hintText: 'Paste share code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    final trimmed = shareCode?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }

    try {
      await ref.read(firestoreRepositoryProvider).acceptShare(trimmed);
      final syncService = ref.read(syncServiceProvider);
      await syncService.stop();
      syncService.start();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Joined!'),
          content: const Text('The shared profile will appear shortly.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Join Failed'),
          content: Text('Could not join: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _exportPortfolio(Child child) async {
    if (_isExporting) {
      return;
    }

    if (!ref.read(isPremiumProvider)) {
      await _openPaywall();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final artworks = await ref
          .read(databaseProvider)
          .artworkDao
          .watchArtworksByChild(child.id)
          .first;
      final pdfData = await PDFExportService.generatePortfolio(
        child.name,
        artworks,
      );
      await Share.shareXFiles([
        XFile.fromData(
          pdfData,
          mimeType: 'application/pdf',
          name: '${child.name}_Portfolio.pdf',
        ),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _replayOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', false);
    await _syncPreferences();
    if (mounted) {
      context.go('/onboarding');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'You can sign in again any time with Sign in with Apple.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await ref.read(syncServiceProvider).stop();
    await ref.read(databaseProvider).clearAllData();
    await prefs.setBool('hasCompletedOnboarding', false);
    await ref.read(firebaseAuthServiceProvider).signOut();

    if (!mounted) {
      return;
    }

    final authError = ref.read(firebaseAuthServiceProvider).authError;
    if (authError != null && authError.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authError)));
      return;
    }

    context.go('/onboarding');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and data from this device and cloud storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Brand.dustyRose),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final authService = ref.read(firebaseAuthServiceProvider);
    final userId = authService.userId;
    if (!mounted) {
      return;
    }
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signed-in account to delete.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await ref.read(syncServiceProvider).stop();
    await ref.read(databaseProvider).clearAllData();
    await prefs.setBool('hasCompletedOnboarding', false);
    await ref.read(firestoreRepositoryProvider).deleteAllUserData(userId);
    await authService.deleteAccount();

    if (!mounted) {
      return;
    }

    final authError = authService.authError;
    if (authError != null && authError.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authError)));
      return;
    }

    context.go('/onboarding');
  }

  Future<void> _forceSyncNow() async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.stop();
    syncService.start();
    await ref.read(firestoreRepositoryProvider).uploadAllLocalData();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync restarted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final artworksAsync = ref.watch(allArtworksProvider);
    final isLinkedWithApple = ref.watch(isLinkedWithAppleProvider);
    final store = ref.watch(storeManagerProvider);
    final syncService = ref.read(syncServiceProvider);

    final children = childrenAsync.valueOrNull ?? const <Child>[];
    final artworks = artworksAsync.valueOrNull ?? const <Artwork>[];
    final artworkCounts = <int, int>{};
    var storageBytes = 0;
    for (final artwork in artworks) {
      if (artwork.childId != null) {
        artworkCounts[artwork.childId!] =
            (artworkCounts[artwork.childId!] ?? 0) + 1;
      }
      storageBytes += artwork.imageData?.length ?? 0;
    }

    final usageSummary = _usageTracker.usageSummary;
    final exceededLimit = _usageTracker.exceededLimit;
    final exceededResetDate = _usageTracker.exceededLimitResetDate;
    final diagnostics = syncService.diagnosticSnapshot();

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Brand.cream,
        title: Text(
          'Settings',
          style: Brand.title2Font.copyWith(color: Brand.charcoal),
        ),
      ),
      body: Stack(
        children: [
          const _SettingsBackground(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SectionHeader(title: 'Children'),
              _SettingsCard(
                children: [
                  if (childrenAsync.isLoading && children.isEmpty)
                    const _InfoRow(title: 'Loading...')
                  else if (children.isEmpty)
                    const _InfoRow(title: 'No child profiles yet')
                  else
                    for (var i = 0; i < children.length; i++) ...[
                      _ChildRow(
                        child: children[i],
                        artworkCount: artworkCounts[children[i].id] ?? 0,
                        onTap: () => _openEditChild(children[i].id),
                      ),
                      if (i < children.length - 1) const _InsetDivider(),
                    ],
                  if (children.isNotEmpty) const _InsetDivider(),
                  _ActionRow(
                    icon: Icons.add,
                    iconColor: Colors.white,
                    iconBackground: Brand.primary,
                    title: 'Add Child',
                    titleColor: Brand.primary,
                    onTap: () => _openAddChild(children),
                  ),
                ],
              ),
              _SectionHeader(title: 'Preferences'),
              _SettingsCard(
                children: [
                  if (store.isPremium)
                    _SwitchRow(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Captions',
                      value: _aiCaptionsEnabled,
                      onChanged: _setAiCaptions,
                    )
                  else
                    _PremiumLockedRow(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Captions',
                      onTap: _openPaywall,
                    ),
                  const _InsetDivider(),
                  _SegmentedPreferenceRow(
                    title: 'Default Camera',
                    value: _defaultCameraBack,
                    onChanged: (value) {
                      if (value != null) {
                        _setDefaultCameraBack(value);
                      }
                    },
                  ),
                  if (!store.isPremium) ...[
                    const _InsetDivider(),
                    _PremiumLockedRow(
                      icon: Icons.mic_rounded,
                      title: 'Voice Memos',
                      onTap: _openPaywall,
                    ),
                  ],
                  const _InsetDivider(),
                  _SwitchRow(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        _setNotificationsEnabled(value, artworks),
                  ),
                ],
              ),
              if (store.isPremium && _aiCaptionsEnabled) ...[
                _SectionHeader(title: 'AI Usage'),
                _SettingsCard(
                  children: [
                    _UsageRow(label: 'Today', usage: usageSummary.daily),
                    const _InsetDivider(),
                    _UsageRow(label: 'This Week', usage: usageSummary.weekly),
                    const _InsetDivider(),
                    _UsageRow(label: 'This Month', usage: usageSummary.monthly),
                    if (exceededLimit != null && exceededResetDate != null) ...[
                      const _InsetDivider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Brand.dustyRose,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                exceededLimit.message(exceededResetDate),
                                style: Brand.captionFont.copyWith(
                                  color: Brand.dustyRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Limits help manage cloud AI costs. Counters reset automatically.',
                    style: Brand.captionFont.copyWith(color: Brand.warmGray),
                  ),
                ),
              ],
              _SectionHeader(title: 'Subscription'),
              _SettingsCard(
                children: [
                  _PlanRow(isPremium: store.isPremium),
                  if (!store.isPremium) ...[
                    const _InsetDivider(),
                    _ActionRow(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Upgrade to Premium',
                      titleColor: Brand.primary,
                      iconColor: Brand.primary,
                      onTap: _openPaywall,
                    ),
                  ],
                  const _InsetDivider(),
                  _ActionRow(
                    icon: Icons.refresh_rounded,
                    title: 'Restore Purchases',
                    isLoading: _isRestoring,
                    onTap: _restorePurchases,
                  ),
                ],
              ),
              _SectionHeader(title: 'Data'),
              _SettingsCard(
                children: [
                  const _KeyValueRow(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Cloud Sync',
                    value: 'Always On',
                    valueColor: Brand.sage,
                  ),
                  const _InsetDivider(),
                  _ActionRow(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Join Shared Profile',
                    onTap: _joinSharedProfile,
                  ),
                  const _InsetDivider(),
                  _KeyValueRow(
                    icon: Icons.storage_rounded,
                    title: 'Storage',
                    value: _formatBytes(storageBytes),
                  ),
                  for (final child in children) ...[
                    const _InsetDivider(),
                    _ActionRow(
                      icon: Icons.picture_as_pdf_rounded,
                      title: "Export ${child.name}'s Portfolio",
                      titleColor: store.isPremium
                          ? Brand.primary
                          : Brand.disabled,
                      isLoading: _isExporting,
                      onTap: () => _exportPortfolio(child),
                    ),
                  ],
                ],
              ),
              _SectionHeader(title: 'Account'),
              _SettingsCard(
                children: [
                  _ActionRow(
                    icon: Icons.apple_rounded,
                    title: isLinkedWithApple
                        ? 'Signed in'
                        : 'Sign in with Apple',
                    trailing: isLinkedWithApple
                        ? const Icon(
                            Icons.check_circle,
                            color: Brand.sage,
                            size: 20,
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Brand.warmGray,
                            size: 20,
                          ),
                    onTap: isLinkedWithApple ? null : _signInWithApple,
                  ),
                  const _InsetDivider(),
                  _DestructiveRow(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    onTap: _signOut,
                  ),
                  const _InsetDivider(),
                  _DestructiveRow(
                    icon: Icons.person_remove_rounded,
                    title: 'Delete Account',
                    onTap: _deleteAccount,
                  ),
                ],
              ),
              if (syncService.isListening ||
                  syncService.diagnosticLog.isNotEmpty) ...[
                _SectionHeader(title: 'Sync Diagnostics'),
                _SettingsCard(
                  children: [
                    for (final entry in diagnostics.entries) ...[
                      _DiagnosticRow(label: entry.key, value: entry.value),
                      if (entry.key != diagnostics.keys.last)
                        const _InsetDivider(),
                    ],
                    if (syncService.diagnosticLog.isNotEmpty) ...[
                      const _InsetDivider(),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          title: Text(
                            'Event Log (${syncService.diagnosticLog.length})',
                            style: Brand.bodyFont.copyWith(
                              color: Brand.charcoal,
                            ),
                          ),
                          children: [
                            for (final entry
                                in syncService.diagnosticLog.reversed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entry,
                                    style: Brand.captionFont.copyWith(
                                      color: Brand.warmGray,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const _InsetDivider(),
                    _ActionRow(
                      icon: Icons.sync_rounded,
                      title: 'Force Sync Now',
                      titleColor: Brand.primary,
                      onTap: _forceSyncNow,
                    ),
                  ],
                ),
              ],
              _SectionHeader(title: 'About'),
              _SettingsCard(
                children: [
                  _KeyValueRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    value: _appVersion,
                  ),
                  const _InsetDivider(),
                  _ActionRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyView(),
                        ),
                      );
                    },
                  ),
                  const _InsetDivider(),
                  _ActionRow(
                    icon: Icons.replay_rounded,
                    title: 'Replay Onboarding',
                    onTap: _replayOnboarding,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    final precision = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

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
              left: -width * 0.25,
              top: -height * 0.15,
              child: Container(
                width: width * 1.1,
                height: width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.sky.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: -width * 0.2,
              bottom: -height * 0.05,
              child: Container(
                width: width * 1.2,
                height: width * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title,
        style: Brand.captionFont.copyWith(
          color: Brand.warmGray,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Brand.radiusCard),
        boxShadow: Brand.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: Brand.softTan),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Brand.bodyFont.copyWith(color: Brand.warmGray),
        ),
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.artworkCount,
    required this.onTap,
  });

  final Child child;
  final int artworkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarColor = Color(int.parse('FF${child.avatarColor}', radix: 16));
    final initial = child.name.isEmpty ? '?' : child.name[0].toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor,
              backgroundImage: child.avatarImageData != null
                  ? MemoryImage(child.avatarImageData!)
                  : null,
              child: child.avatarImageData == null
                  ? Text(
                      initial,
                      style: Brand.subheadlineFont.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      child.name,
                      style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (child.isShared || child.firestoreId != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.groups_2_rounded,
                      size: 15,
                      color: Brand.sky,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$artworkCount artworks',
              style: Brand.captionFont.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Brand.warmGray),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    this.titleColor = Brand.charcoal,
    this.iconColor = Brand.charcoal,
    this.iconBackground,
    this.trailing,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color titleColor;
  final Color iconColor;
  final Color? iconBackground;
  final Widget? trailing;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = isLoading ? null : onTap;

    return InkWell(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (iconBackground != null)
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBackground,
                child: Icon(icon, color: iconColor, size: 20),
              )
            else
              Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Brand.bodyFont.copyWith(color: titleColor),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (trailing != null)
              trailing!
            else
              const Icon(Icons.chevron_right, size: 20, color: Brand.warmGray),
          ],
        ),
      ),
    );
  }
}

class _PremiumLockedRow extends StatelessWidget {
  const _PremiumLockedRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Brand.disabled, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Brand.bodyFont.copyWith(color: Brand.disabled),
              ),
            ),
            Text(
              'Premium',
              style: Brand.captionFont.copyWith(color: Brand.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Brand.charcoal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Brand.primary,
            activeTrackColor: Brand.primary.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedPreferenceRow extends StatelessWidget {
  const _SegmentedPreferenceRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_rounded, color: Brand.charcoal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: value,
            onValueChanged: onChanged,
            children: {
              true: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  'Back',
                  style: Brand.captionFont.copyWith(color: Brand.charcoal),
                ),
              ),
              false: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  'Front',
                  style: Brand.captionFont.copyWith(color: Brand.charcoal),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Brand.charcoal,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Plan',
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: Brand.bodyFont.copyWith(
              color: isPremium ? Brand.primary : Brand.warmGray,
              fontWeight: isPremium ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor = Brand.warmGray,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Brand.charcoal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),
          Text(value, style: Brand.captionFont.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _DestructiveRow extends StatelessWidget {
  const _DestructiveRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Brand.dustyRose, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Brand.bodyFont.copyWith(color: Brand.dustyRose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.usage});

  final String label;
  final PeriodUsage usage;

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    if (usage.fraction >= 1) {
      progressColor = Brand.dustyRose;
    } else if (usage.fraction >= 0.8) {
      progressColor = Brand.primary;
    } else {
      progressColor = Brand.sage;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Brand.captionFont.copyWith(color: Brand.charcoal),
              ),
              const Spacer(),
              Text(
                '${usage.used}/${usage.limit}',
                style: Brand.captionFont.copyWith(
                  color: usage.isExceeded ? Brand.dustyRose : Brand.warmGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: usage.fraction.clamp(0, 1),
              minHeight: 8,
              color: progressColor,
              backgroundColor: Brand.softTan,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        value.contains('none') ||
            value.contains('None') ||
            value.contains('false') ||
            value.contains('No')
        ? Brand.dustyRose
        : Brand.sage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Brand.captionFont.copyWith(color: Brand.charcoal),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Brand.captionFont.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
