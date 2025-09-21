import 'package:flutter/material.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/widgets/screenshots/screenshot_card.dart';
import 'package:uuid/uuid.dart';
import 'package:shots_studio/utils/responsive_utils.dart';

class CreateCollectionScreen extends StatefulWidget {
  final List<Screenshot> availableScreenshots;
  final Set<String>? initialSelectedIds;
  final Collection? existingCollection;

  const CreateCollectionScreen({
    super.key,
    required this.availableScreenshots,
    this.initialSelectedIds,
    this.existingCollection,
  });

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Set<String> _selectedScreenshotIds;
  final Uuid _uuid = const Uuid();
  bool _isAutoAddEnabled = false;

  @override
  void initState() {
    super.initState();

    // Track screen access
    if (widget.existingCollection != null) {
      AnalyticsService().logScreenView('edit_collection_screen');
    } else {
      AnalyticsService().logScreenView('create_collection_screen');
    }

    // If editing an existing collection, populate the fields
    if (widget.existingCollection != null) {
      _titleController.text = widget.existingCollection!.name ?? '';
      _descriptionController.text =
          widget.existingCollection!.description ?? '';
      _isAutoAddEnabled = widget.existingCollection!.isAutoAddEnabled;
    }

    _selectedScreenshotIds =
        widget.initialSelectedIds != null
            ? Set.from(widget.initialSelectedIds!)
            : {};

    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(() {
      setState(() {});
    });
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleScreenshotSelection(String screenshotId) {
    setState(() {
      if (_selectedScreenshotIds.contains(screenshotId)) {
        _selectedScreenshotIds.remove(screenshotId);
        AnalyticsService().logFeatureUsed(
          'screenshot_deselected_in_collection',
        );
      } else {
        _selectedScreenshotIds.add(screenshotId);
        AnalyticsService().logFeatureUsed('screenshot_selected_in_collection');
      }
    });
  }

  void _save() {
    String title = _titleController.text.trim();

    // If title is empty, generate a default name
    if (title.isEmpty) {
      title =
          'Collection ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    final Collection collection;
    if (widget.existingCollection != null) {
      // Update existing collection
      AnalyticsService().logFeatureUsed('collection_edited');
      collection = widget.existingCollection!.copyWith(
        name: title,
        description: _descriptionController.text.trim(),
        screenshotIds: _selectedScreenshotIds.toList(),
        lastModified: DateTime.now(),
        screenshotCount: _selectedScreenshotIds.length,
        isAutoAddEnabled: _isAutoAddEnabled,
      );
    } else {
      // Create new collection
      AnalyticsService().logFeatureUsed('collection_created');
      collection = Collection(
        id: _uuid.v4(),
        name: title,
        description: _descriptionController.text.trim(),
        screenshotIds: _selectedScreenshotIds.toList(),
        lastModified: DateTime.now(),
        screenshotCount: _selectedScreenshotIds.length,
        isAutoAddEnabled: _isAutoAddEnabled,
        displayOrder:
            DateTime.now()
                .millisecondsSinceEpoch, // Use timestamp for new collections
      );
    }
    Navigator.of(context).pop(collection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingCollection != null
              ? 'Edit Collection'
              : 'Create Collection',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter collection title...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message:
                              'When enabled, AI will automatically add relevant screenshots to this collection',
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Smart Categorization',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Switch(
                        value: _isAutoAddEnabled,
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        onChanged: (bool value) {
                          setState(() {
                            _isAutoAddEnabled = value;
                          });

                          // Track auto-add toggle interactions
                          if (value) {
                            AnalyticsService().logFeatureUsed(
                              'auto_add_enabled',
                            );
                          } else {
                            AnalyticsService().logFeatureUsed(
                              'auto_add_disabled',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isAutoAddEnabled)
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gemini AI will automatically categorize new screenshots into this collection based on content analysis.',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Select Screenshots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Screenshots grid container with fixed height
                  SizedBox(
                    height: 400, // Fixed height for the grid
                    child:
                        widget.availableScreenshots.isEmpty
                            ? Center(
                              child: Text(
                                'No screenshots available',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                            : GridView.builder(
                              gridDelegate:
                                  ResponsiveUtils.getResponsiveGridDelegate(
                                    context,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: widget.availableScreenshots.length,
                              cacheExtent: 1200,
                              itemBuilder: (context, index) {
                                final screenshot =
                                    widget.availableScreenshots[index];
                                final isSelected = _selectedScreenshotIds
                                    .contains(screenshot.id);

                                return GestureDetector(
                                  onTap:
                                      () => _toggleScreenshotSelection(
                                        screenshot.id,
                                      ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ScreenshotCard(
                                        screenshot: screenshot,
                                        onCorruptionDetected: () {
                                          setState(() {});
                                        },
                                        onTap:
                                            () => _toggleScreenshotSelection(
                                              screenshot.id,
                                            ),
                                      ),

                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.7),
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.check_circle,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
