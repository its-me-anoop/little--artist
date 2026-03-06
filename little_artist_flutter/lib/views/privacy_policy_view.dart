import 'package:flutter/material.dart';

import '../utils/brand_tokens.dart';

/// Privacy policy display screen.
///
/// Shows a scrollable text view with sections covering data handling
/// for a children's artwork app.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Brand.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Brand.title1Font
                  .copyWith(color: Brand.adaptiveCharcoal(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: March 2026',
              style: Brand.captionFont
                  .copyWith(color: Brand.adaptiveWarmGray(context)),
            ),
            const SizedBox(height: Brand.sectionSpacing),
            _buildSection(
              context,
              title: 'What We Collect',
              body:
                  'Little Artist collects and stores information you provide directly, '
                  'including your child\'s name, date of birth, and photographs of their '
                  'artwork. We also collect optional voice memos, artwork descriptions, '
                  'and tags you assign to organize your collection. If you create an account, '
                  'we store your email address and authentication credentials securely.',
            ),
            _buildSection(
              context,
              title: 'How We Use It',
              body:
                  'Your data is used solely to provide the Little Artist experience: '
                  'organizing, displaying, and preserving your child\'s artwork. '
                  'AI-powered features such as artwork descriptions and milestone '
                  'suggestions use your artwork images to generate personalized insights. '
                  'These AI interactions are processed securely and are not used to train '
                  'third-party models. We never sell your personal data or your child\'s '
                  'information to advertisers or data brokers.',
            ),
            _buildSection(
              context,
              title: 'Data Storage',
              body:
                  'Artwork images and metadata are stored on your device and, if you '
                  'enable sync, in your private iCloud or Firebase cloud storage account. '
                  'Cloud-synced data is encrypted in transit and at rest. Your data remains '
                  'under your control, and you can delete it at any time from within the app. '
                  'Local data is stored using industry-standard encryption provided by '
                  'your device\'s operating system.',
            ),
            _buildSection(
              context,
              title: 'Third Parties',
              body:
                  'We use the following third-party services to operate the app:\n\n'
                  '\u2022 Firebase (Google) for authentication, cloud storage, and sync\n'
                  '\u2022 Google Gemini for AI-powered artwork analysis and suggestions\n'
                  '\u2022 RevenueCat for in-app purchase management\n\n'
                  'These services process only the minimum data necessary to provide their '
                  'functionality. We do not share your data with any other third parties. '
                  'Each service is bound by their own privacy policies and data processing '
                  'agreements.',
            ),
            _buildSection(
              context,
              title: 'Your Rights',
              body:
                  'You have the right to access, correct, or delete any personal data '
                  'stored in Little Artist at any time. You can export your artwork '
                  'collection or delete your account and all associated data from the '
                  'Settings screen. If you are located in the European Economic Area, '
                  'you have additional rights under GDPR including data portability and '
                  'the right to restrict processing. For users in California, CCPA rights '
                  'apply including the right to know what data is collected and the right '
                  'to opt out of data sales (we do not sell data).',
            ),
            _buildSection(
              context,
              title: 'Children\'s Privacy',
              body:
                  'Little Artist is designed to be used by parents and guardians to '
                  'document their children\'s artwork. We comply with COPPA (Children\'s '
                  'Online Privacy Protection Act) and do not knowingly collect personal '
                  'information directly from children under 13. All data entry is performed '
                  'by the parent or guardian who manages the account.',
            ),
            _buildSection(
              context,
              title: 'Contact',
              body:
                  'If you have questions about this privacy policy or your data, please '
                  'contact us at support@littleartist.app. We are committed to protecting '
                  'your family\'s privacy and will respond to inquiries within 30 days.',
            ),
            const SizedBox(height: Brand.sectionSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Brand.gallerySpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Brand.headlineFont
                .copyWith(color: Brand.adaptiveCharcoal(context)),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Brand.bodyFont.copyWith(
              color: Brand.adaptiveCharcoal(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
