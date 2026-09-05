import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

import '../../services/social_url_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class YoutubeEditPage extends StatefulWidget {
  const YoutubeEditPage({super.key});

  @override
  State<YoutubeEditPage> createState() => _YoutubeEditPageState();
}

class _YoutubeEditPageState extends State<YoutubeEditPage> {
  final _service = SocialUrlService();
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadUrl(); }

  Future<void> _loadUrl() async {
    try {
      final url = await _service.getYoutubeUrl();
      if (!mounted) return;
      setState(() { _controller.text = url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to load YouTube link.'; });
    }
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    final uri = Uri.tryParse(value);
    if (uri == null || !['http', 'https'].contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) {
      setState(() => _error = 'Enter a valid YouTube URL.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _service.saveYoutubeUrl(value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube URL saved successfully.')));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('YouTube Edit'),
        leading: IconButton(onPressed: () => navigateBack(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 90), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.ondemand_video, color: Color(0xFFD32F2F)), SizedBox(width: 8), Text('YouTube', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 20),
                TextField(controller: _controller, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'YouTube URL *', hintText: 'https://www.youtube.com/your-channel', border: OutlineInputBorder())),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'))),
              ]))),
            ]),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (index) {
        if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
      }),
    );
  }
}
