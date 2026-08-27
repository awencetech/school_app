import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../services/school_config_service.dart';
import '../../models/management_member.dart';
import '../../routes/app_routes.dart';

class ContentEditScreen extends StatefulWidget {
  const ContentEditScreen({super.key});

  @override
  State<ContentEditScreen> createState() => _ContentEditScreenState();
}

class _ContentEditScreenState extends State<ContentEditScreen> {
  late final SchoolConfigService _config;
  late List<ManagementMember> _items;
  late List<TextEditingController> _titleControllers;
  late List<TextEditingController> _descControllers;
  bool _isSaving = false;
  bool _hasEdits = false;
  final Random _random = Random();

  String _generateContentId() {
    return 'content_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1000000)}';
  }

  ManagementMember _ensureItemHasId(ManagementMember item) {
    if (item.id.isNotEmpty) return item;
    return ManagementMember(
      id: _generateContentId(),
      photoBase64: item.photoBase64,
      name: item.name,
      designation: item.designation,
      title: item.title,
      description: item.description,
    );
  }

  @override
  void initState() {
    super.initState();
    _items = [];
    _titleControllers = [];
    _descControllers = [];

    _config = context.read<SchoolConfigService>();
    _syncItemsFromService(_config.homeContent);
    _config.addListener(_handleServiceUpdate);
  }

  @override
  void dispose() {
    _config.removeListener(_handleServiceUpdate);

    for (final c in _titleControllers) {
      c.dispose();
    }
    for (final c in _descControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureControllers() {
    while (_titleControllers.length < _items.length) {
      _titleControllers.add(TextEditingController(text: ''));
    }
    while (_descControllers.length < _items.length) {
      _descControllers.add(TextEditingController(text: ''));
    }
    while (_titleControllers.length > _items.length) {
      _titleControllers.removeLast().dispose();
    }
    while (_descControllers.length > _items.length) {
      _descControllers.removeLast().dispose();
    }
  }

  void _syncItemsFromService(List<ManagementMember> serviceItems) {
    final loadedItems = serviceItems.map((item) => ManagementMember.fromJson(item.toJson())).toList();
    _items = loadedItems.map(_ensureItemHasId).toList();
    for (var i = 0; i < _items.length; i++) {
      if (i < _titleControllers.length) {
        _titleControllers[i].text = _items[i].title;
      } else {
        _titleControllers.add(TextEditingController(text: _items[i].title));
      }
      if (i < _descControllers.length) {
        _descControllers[i].text = _items[i].description;
      } else {
        _descControllers.add(TextEditingController(text: _items[i].description));
      }
    }
    _ensureControllers();
  }

  void _handleServiceUpdate() {
    if (_hasEdits) {
      return;
    }
    final config = context.read<SchoolConfigService>();
    setState(() {
      _syncItemsFromService(config.homeContent);
    });
  }

  void _addItem() {
    setState(() {
      final newId = _generateContentId();
      _items.add(ManagementMember(id: newId, photoBase64: '', name: '', designation: '', title: '', description: ''));
      _titleControllers.add(TextEditingController(text: ''));
      _descControllers.add(TextEditingController(text: ''));
      _hasEdits = true;
    });
  }

  Future<bool> _saveContent() async {
    setState(() {
      _isSaving = true;
    });

    final config = context.read<SchoolConfigService>();
    // Reconstruct final items from the current controllers to ensure we
    // capture the latest text values even if onChanged hasn't propagated.
    final List<ManagementMember> finalItems = [];
    for (var i = 0; i < _items.length; i++) {
      final title = i < _titleControllers.length ? _titleControllers[i].text : _items[i].title;
      final desc = i < _descControllers.length ? _descControllers[i].text : _items[i].description;
      final photo = _items[i].photoBase64;
      finalItems.add(ManagementMember(
        id: _items[i].id,
        photoBase64: photo,
        name: _items[i].name,
        designation: _items[i].designation,
        title: title,
        description: desc,
      ));
    }

    // Detailed pre-save debug log as requested
    try {
      debugPrint('CONTENT SAVE DEBUG');
      debugPrint('count = ${finalItems.length}');
      for (var i = 0; i < finalItems.length; i++) {
        final it = finalItems[i];
        final id = it.id;
        final image = it.photoBase64.trim();
        String imageInfo;
        if (image.isEmpty) {
          imageInfo = 'empty';
        } else if (image.startsWith('http://') || image.startsWith('https://')) {
          imageInfo = 'url (${image.length} chars)';
        } else if (image.startsWith('data:')) {
          imageInfo = 'dataUri (${image.length} chars)';
        } else {
          imageInfo = 'base64 (${image.length} chars)';
        }
        debugPrint('\n[$i]');
        debugPrint('id = $id');
        debugPrint('title = ${it.title}');
        debugPrint('description = ${it.description}');
        debugPrint('image = $imageInfo');
      }
    } catch (_) {}

    var success = false;
    try {
      success = await config.saveHomeContent(finalItems);
    } catch (error, stack) {
      debugPrint('ContentEditScreen._saveContent error: $error\n$stack');
      success = false;
    }

    if (!mounted) return false;

    setState(() {
      _isSaving = false;
      _hasEdits = !success ? _hasEdits : false;
    });

    return success;
  }

  Future<void> _save() async {
    final success = await _saveContent();
    if (!mounted) return;

    final message = success
        ? 'Content saved successfully.'
        : 'Unable to save content. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectImage(int index) async {
    final repository = context.read<SchoolConfigService>().repository;
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;

    final file = result.first;
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be 10MB or less.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final uploadedUrl = await repository.uploadPoster(
            fileName: file.name,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _items[index] = ManagementMember(
          id: _items[index].id,
          photoBase64: uploadedUrl,
          name: _items[index].name,
          designation: _items[index].designation,
          title: _items[index].title,
          description: _items[index].description,
        );
        _hasEdits = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload image: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearImage(int index) {
    setState(() {
      _items[index] = ManagementMember(
        id: _items[index].id,
        photoBase64: '',
        name: _items[index].name,
        designation: _items[index].designation,
        title: _items[index].title,
        description: _items[index].description,
      );
      _hasEdits = true;
    });
  }

  Future<void> _confirmDelete(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final beforeCount = _items.length;
    final beforeIds = _items.map((item) => item.id).toList();
    final oldItems = List<ManagementMember>.from(_items);
    final oldTitleControllers = List<TextEditingController>.from(_titleControllers);
    final oldDescControllers = List<TextEditingController>.from(_descControllers);
    final removedTitleController = _titleControllers[index];
    final removedDescController = _descControllers[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this content?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _items.removeAt(index);
      _titleControllers.removeAt(index);
      _descControllers.removeAt(index);
      _hasEdits = true;
    });

    debugPrint('CONTENT DELETE DEBUG');
    debugPrint('requestedId = $itemId');
    debugPrint('beforeCount = $beforeCount');
    debugPrint('beforeIds = $beforeIds');
    debugPrint('afterCount = ${_items.length}');
    debugPrint('afterIds = [${_items.map((item) => item.id).join(', ')}]');

    final success = await _saveContent();

    if (!mounted) return;

    debugPrint('CONTENT DELETE RESPONSE');
    debugPrint('status = $success');
    debugPrint('savedCount = ${_items.length}');

    if (!success) {
      setState(() {
        _items = oldItems;
        _titleControllers = oldTitleControllers;
        _descControllers = oldDescControllers;
        _hasEdits = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete content. Please try again.')),
      );
    } else {
      removedTitleController.dispose();
      removedDescController.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content deleted successfully.')),
      );
    }
  }

  Widget _buildImagePreview(String? imageData) {
    final trimmed = (imageData ?? '').trim();
    if (trimmed.isEmpty) {
      return Container(
        color: AppColors.divider,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.hintText),
        ),
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.divider),
        errorWidget: (context, url, error) {
          return Container(
            color: AppColors.divider,
            child: const Center(child: Icon(Icons.broken_image, color: AppColors.hintText)),
          );
        },
      );
    }

    UriData? uriData;
    try {
      uriData = UriData.parse(trimmed);
    } catch (_) {
      uriData = null;
    }

    if (uriData != null && uriData.contentAsBytes().isNotEmpty) {
      return Image.memory(uriData.contentAsBytes(), fit: BoxFit.cover);
    }

    final normalized = trimmed.toLowerCase().startsWith('data:')
        ? trimmed.substring(trimmed.indexOf(',') + 1).replaceAll(RegExp(r'\s+'), '')
        : trimmed.replaceAll(RegExp(r'\s+'), '');

    try {
      final bytes = base64Decode(normalized);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        color: AppColors.divider,
        child: const Center(child: Icon(Icons.broken_image, color: AppColors.hintText)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Content Edit')),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No content items yet. Tap Add Content to create one.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        key: ValueKey('content_${item.id}'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Content ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _confirmDelete(item.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: _buildImagePreview(item.photoBase64),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _selectImage(index),
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Choose Image'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: item.photoBase64.isNotEmpty ? () => _clearImage(index) : null,
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear Image'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image is optional.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.hintText),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _titleControllers[index],
                                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                                onChanged: (value) {
                                  setState(() {
                                    _items[index] = ManagementMember(
                                      id: item.id,
                                      photoBase64: item.photoBase64,
                                      name: item.name,
                                      designation: item.designation,
                                      title: value,
                                      description: item.description,
                                    );
                                    _hasEdits = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descControllers[index],
                                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                                maxLines: 4,
                                onChanged: (value) {
                                  setState(() {
                                    _items[index] = ManagementMember(
                                      id: item.id,
                                      photoBase64: item.photoBase64,
                                      name: item.name,
                                      designation: item.designation,
                                      title: item.title,
                                      description: value,
                                    );
                                    _hasEdits = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Content'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _hasEdits && !_isSaving ? _save : null,
                  icon: const Icon(Icons.save),
                  label: _isSaving ? const Text('Saving...') : const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      ),
    );
  }
}
