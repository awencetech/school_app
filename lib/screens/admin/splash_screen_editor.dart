import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/splash_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/founder_splash_image.dart';
import '../../widgets/admin_bottom_nav.dart';

class SplashScreenEditor extends StatefulWidget {
  const SplashScreenEditor({super.key});

  @override
  State<SplashScreenEditor> createState() => _SplashScreenEditorState();
}



class _SplashScreenEditorState extends State<SplashScreenEditor> {
  final TextEditingController _titleController = TextEditingController(text: 'Splash Screen');
  final TextEditingController _subtitleController = TextEditingController(text: '');
  final TextEditingController _quoteController = TextEditingController(text: '');
  final TextEditingController _sinceController = TextEditingController(text: '1987');
  String? _imageBase64;
  double _imageScale = 1.0;
  double _imageOffsetX = 0.0;
  double _imageOffsetY = 0.0;
  bool _isSaving = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _quoteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<SplashConfigService>();
      setState(() {
        _titleController.text = svc.title;
        _subtitleController.text = svc.subtitle;
        _quoteController.text = svc.quote;
        _sinceController.text = svc.since;
        _imageBase64 = svc.imageBase64;
        _imageScale = svc.imageScale;
        _imageOffsetX = svc.imageOffsetX;
        _imageOffsetY = svc.imageOffsetY;
      });
    });
  }

  Future<void> _save() async {
    // Basic validation
    final title = _titleController.text.trim();
    final since = _sinceController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }
    if (since.isEmpty || int.tryParse(since) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Since must be a valid year')));
      return;
    }

    setState(() => _isSaving = true);
    final svc = context.read<SplashConfigService>();
    final ok = await svc.save(
      imageBase64: _imageBase64,
      title: title,
      subtitle: _subtitleController.text,
      quote: _quoteController.text,
      since: since,
      imageScale: _imageScale,
      imageOffsetX: _imageOffsetX,
      imageOffsetY: _imageOffsetY,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Splash screen updated successfully.')));
      // Keep UI in sync with saved values
      setState(() {
        _titleController.text = svc.title;
        _subtitleController.text = svc.subtitle;
        _quoteController.text = svc.quote;
        _sinceController.text = svc.since;
        _imageBase64 = svc.imageBase64;
        _imageScale = svc.imageScale;
        _imageOffsetX = svc.imageOffsetX;
        _imageOffsetY = svc.imageOffsetY;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save splash screen. Please try again.')));
    }
  }

  void _preview() {
    // Scroll to the inline preview section instead of opening a full-screen modal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final ctx = _previewKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
        }
      } catch (_) {}
    });
  }

  void _reset() {
    final svc = context.read<SplashConfigService>();
    setState(() {
      _titleController.text = svc.title;
      _subtitleController.text = svc.subtitle;
      _quoteController.text = svc.quote;
      _sinceController.text = svc.since;
      _imageBase64 = svc.imageBase64;
      _imageScale = svc.imageScale;
      _imageOffsetX = svc.imageOffsetX;
      _imageOffsetY = svc.imageOffsetY;
    });
  }

  @override
  Widget build(BuildContext context) {
    // No local sizing here; `FounderSplashImage` handles responsive sizing.
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Splash Screen')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Splash Screen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quoteController,
              decoration: const InputDecoration(
                labelText: 'Quote',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.multiline,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sinceController,
              decoration: const InputDecoration(
                labelText: 'Since (year)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('Image', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _imageBase64 != null
                          ? Center(
                              child: _imageBase64!.trim().startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: _imageBase64!,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const SizedBox.shrink(),
                                      errorWidget: (context, url, error) => const Icon(Icons.image, size: 36),
                                    )
                                  : Image.memory(
                                      base64Decode(_imageBase64!),
                                      fit: BoxFit.contain,
                                    ),
                            )
                          : const Icon(Icons.image, size: 36),
                    ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose Image'),
                ),
                ElevatedButton.icon(
                  onPressed: _preview,
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text('Preview'),
                ),
              ],
            ),
            // Image Editor removed per admin UX requirements. Only thumbnail and preview are shown.
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              key: _previewKey,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_imageBase64 != null)
                    Center(
                      child: FounderSplashImage(imageBase64: _imageBase64),
                    ),
                  const SizedBox(height: 16),
                  Text('Since ${_sinceController.text}', style: AppTextStyles.subtitle.copyWith(color: AppColors.white)),
                  const SizedBox(height: 10),
                  Text(_titleController.text, style: AppTextStyles.appTitle.copyWith(color: AppColors.white)),
                  const SizedBox(height: 6),
                  Text(_subtitleController.text, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                  if (_quoteController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"${_quoteController.text}"', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.95), fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
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

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final file = result.first;
    // Use the selected file bytes without performing any cropping.
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
      _imageScale = 1.0;
      _imageOffsetX = 0.0;
      _imageOffsetY = 0.0;
    });
  }
}
