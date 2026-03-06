import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../utils/brand_tokens.dart';

/// App settings view with children management, preferences, account, data,
/// and about sections.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _aiCaptionsEnabled = true;
  bool _defaultCameraBack = false;
  final String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _aiCaptionsEnabled = prefs.getBool('aiCaptionsEnabled') ?? true;
        _defaultCameraBack = prefs.getBool('defaultCameraBack') ?? false;
      });
    }
  }

  Future<void> _setAiCaptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiCaptionsEnabled', value);
    if (mounted) setState(() => _aiCaptionsEnabled = value);
  }

  Future<void> _setDefaultCameraBack(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('defaultCameraBack', value);
    if (mounted) setState(() => _defaultCameraBack = value);
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(allChildrenProvider);
    final isLinkedWithApple = ref.watch(isLinkedWithAppleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Brand.title2Font),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Brand.screenPadding,
        ),
        children: [
          // -----------------------------------------------------------------
          // MARK: - Children Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Children'),
          _buildCard(
            children: [
              ...childrenAsync.when(
                loading: () => [
                  const ListTile(
                    title: Text('Loading...'),
                  ),
                ],
                error: (_, _) => <Widget>[],
                data: (children) => children.asMap().entries.map((entry) {
                  final index = entry.key;
                  final child = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(
                            int.parse('FF${child.avatarColor}', radix: 16),
                          ),
                          child: Text(
                            child.name.isNotEmpty
                                ? child.name[0].toUpperCase()
                                : '?',
                            style: Brand.subheadlineFont
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          child.name,
                          style:
                              Brand.bodyFont.copyWith(color: Brand.charcoal),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Brand.warmGray,
                        ),
                        onTap: () {
                          // Navigate to edit child
                        },
                      ),
                      if (index < children.length - 1)
                        const Divider(
                          height: 1,
                          indent: 56,
                          color: Brand.softTan,
                        ),
                    ],
                  );
                }),
              ),
              childrenAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (children) {
                  if (children.isNotEmpty) {
                    return const Divider(
                      height: 1,
                      indent: 16,
                      color: Brand.softTan,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Brand.primary,
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
                title: Text(
                  'Add Child',
                  style: Brand.bodyFont.copyWith(color: Brand.primary),
                ),
                onTap: () {
                  // Navigate to add child
                },
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // MARK: - Preferences Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Preferences'),
          _buildCard(
            children: [
              SwitchListTile(
                title: Text(
                  'AI Captions',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                subtitle: Text(
                  'Automatically generate artwork captions',
                  style: Brand.captionFont.copyWith(color: Brand.warmGray),
                ),
                value: _aiCaptionsEnabled,
                onChanged: _setAiCaptions,
                activeThumbColor: Brand.primary,
              ),
              const Divider(height: 1, indent: 16, color: Brand.softTan),
              SwitchListTile(
                title: Text(
                  'Use Back Camera',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                subtitle: Text(
                  'Default to rear camera when capturing',
                  style: Brand.captionFont.copyWith(color: Brand.warmGray),
                ),
                value: _defaultCameraBack,
                onChanged: _setDefaultCameraBack,
                activeThumbColor: Brand.primary,
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // MARK: - Account Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Account'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.apple, color: Brand.charcoal),
                title: Text(
                  isLinkedWithApple ? 'Signed in' : 'Sign in with Apple',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                trailing: isLinkedWithApple
                    ? const Icon(
                        Icons.check_circle,
                        color: Brand.sage,
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: Brand.warmGray,
                      ),
                onTap: isLinkedWithApple
                    ? null
                    : () {
                        // Sign in with Apple
                      },
              ),
              const Divider(height: 1, indent: 56, color: Brand.softTan),
              ListTile(
                leading: const Icon(Icons.star, color: Brand.primary),
                title: Text(
                  'Upgrade to Premium',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Brand.warmGray,
                ),
                onTap: () {
                  // Navigate to paywall
                },
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // MARK: - Data Section
          // -----------------------------------------------------------------
          _buildSectionHeader('Data'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Brand.charcoal,
                ),
                title: Text(
                  'Export as PDF',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Brand.warmGray,
                ),
                onTap: () {
                  // Export PDF
                },
              ),
              const Divider(height: 1, indent: 56, color: Brand.softTan),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Brand.dustyRose),
                title: Text(
                  'Delete Account',
                  style: Brand.bodyFont.copyWith(color: Brand.dustyRose),
                ),
                onTap: () {
                  // Confirm & delete account
                },
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // MARK: - About Section
          // -----------------------------------------------------------------
          _buildSectionHeader('About'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: Brand.charcoal),
                title: Text(
                  'Privacy Policy',
                  style: Brand.bodyFont.copyWith(color: Brand.charcoal),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Brand.warmGray,
                ),
                onTap: () {
                  // Open privacy policy
                },
              ),
              const Divider(height: 1, indent: 56, color: Brand.softTan),
              ListTile(
                leading:
                    const Icon(Icons.info_outline, color: Brand.charcoal),
                title: Text(
                  'Version $_appVersion',
                  style: Brand.bodyFont.copyWith(color: Brand.warmGray),
                ),
              ),
            ],
          ),

          const SizedBox(height: Brand.sectionSpacing),
        ],
      ),
    );
  }

  // MARK: - Helpers

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        top: Brand.sectionSpacing,
        bottom: 12,
      ),
      child: Text(
        title,
        style: Brand.title3Font.copyWith(color: Brand.charcoal),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Brand.radiusCard),
        boxShadow: Brand.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
