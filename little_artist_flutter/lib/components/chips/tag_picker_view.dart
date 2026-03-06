import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';
import 'tag_chip_view.dart';

/// Tag selection and creation widget.
///
/// Displays currently [selectedTags] as removable chips in a wrap layout,
/// with a text field for adding new tags. Suggested tags from
/// [availableTags] that are not yet selected appear below the input.
class TagPickerView extends StatefulWidget {
  const TagPickerView({
    super.key,
    required this.selectedTags,
    required this.availableTags,
    required this.onTagsChanged,
  });

  final List<String> selectedTags;
  final List<String> availableTags;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  State<TagPickerView> createState() => _TagPickerViewState();
}

class _TagPickerViewState extends State<TagPickerView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (widget.selectedTags.contains(trimmed)) return;

    widget.onTagsChanged([...widget.selectedTags, trimmed]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final updated = widget.selectedTags.where((t) => t != tag).toList();
    widget.onTagsChanged(updated);
  }

  List<String> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    return widget.availableTags
        .where((t) => !widget.selectedTags.contains(t))
        .where((t) => query.isEmpty || t.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Brand.fieldPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected tags + input field
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...widget.selectedTags.map(
                (tag) => TagChipView(
                  name: tag,
                  showRemove: true,
                  onRemove: () => _removeTag(tag),
                ),
              ),
              _buildInput(),
            ],
          ),

          // Suggestions
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((tag) {
                return TagChipView(
                  name: tag,
                  onTap: () => _addTag(tag),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput() {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: Brand.captionFont.copyWith(color: Brand.charcoal),
          decoration: InputDecoration(
            hintText: 'Add tag...',
            hintStyle: Brand.captionFont.copyWith(color: Brand.warmGray),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            _addTag(value);
            _focusNode.requestFocus();
          },
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }
}
