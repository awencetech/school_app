import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../../services/school_config_service.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class SchoolSettingsEditor extends StatefulWidget {
  const SchoolSettingsEditor({super.key});

  @override
  State<SchoolSettingsEditor> createState() => _SchoolSettingsEditorState();
}

class _SchoolSettingsEditorState extends State<SchoolSettingsEditor> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _welcomeController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _runningController = TextEditingController();
  String? _posterUrl;
  bool _hasUserEdited = false;
  bool _isSyncing = false;
  late final SchoolConfigService _config;

  @override
  void initState() {
    super.initState();
    _config = context.read<SchoolConfigService>();
    _syncControllersFromConfig();
    _config.addListener(_syncControllersFromConfig);
    _addUserEditListeners();
  }

  @override
  void dispose() {
    _config.removeListener(_syncControllersFromConfig);
    _nameController.dispose();
    _quoteController.dispose();
    _welcomeController.dispose();
    _websiteController.dispose();
    _runningController.dispose();
    super.dispose();
  }

  void _addUserEditListeners() {
    for (final controller in [
      _nameController,
      _quoteController,
      _welcomeController,
      _websiteController,
      _runningController,
    ]) {
      controller.addListener(() {
        if (!_isSyncing) {
          _hasUserEdited = true;
        }
      });
    }
  }

  void _syncControllersFromConfig() {
    if (!mounted || _hasUserEdited) return;
    _isSyncing = true;
    _nameController.text = _config.schoolName;
    _quoteController.text = _config.quote;
    _welcomeController.text = _config.welcome;
    _websiteController.text = _config.websiteUrl;
    _runningController.text = _config.runningItems.join('\n');
    _posterUrl = _config.posterUrl;
    _isSyncing = false;
    setState(() {});
  }

  Future<void> _pickPoster() async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.image);
    if (result.isEmpty) return;
    final file = result.first;
    final bytes = await file.readAsBytes();

    try {
      final uploadedUrl = await context.read<SchoolConfigService>().repository.uploadPoster(
        fileName: file.name,
        bytes: bytes,
      );
      setState(() {
        _posterUrl = uploadedUrl;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to upload poster: $error')),
      );
    }
  }

  Future<void> _save() async {
    final config = context.read<SchoolConfigService>();
    final runningItems = _runningController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    await config.save(
      schoolName: _nameController.text.trim(),
      quote: _quoteController.text.trim(),
      welcome: _welcomeController.text.trim(),
      website: _websiteController.text.trim(),
      runningItems: runningItems,
      posterUrl: _posterUrl,
      clearPoster: _posterUrl == null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School poster saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Edit School Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('School Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'School Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quoteController,
              decoration: const InputDecoration(labelText: 'School Quote', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _welcomeController,
              decoration: const InputDecoration(labelText: 'Welcome Text', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'School Website', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _runningController,
              decoration: const InputDecoration(
                labelText: 'Running Content (one item per line)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Text('Poster', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickPoster,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose Poster'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _posterUrl = null);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Poster'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_posterUrl != null && _posterUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _posterUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) {
                      debugPrint('School poster preview error: $error');
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Text('Unable to load poster')),
                      );
                    },
                  ),
                )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                    color: Colors.grey.shade200,
                  child: const Center(child: Text('No poster selected')),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
