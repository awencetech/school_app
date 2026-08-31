import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/social_url_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class InstagramEditPage extends StatefulWidget {
  const InstagramEditPage({super.key});

  @override
  State<InstagramEditPage> createState() => _InstagramEditPageState();
}

class _InstagramEditPageState extends State<InstagramEditPage> {
  final _service = SocialUrlService();
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadUrl(); }

  Future<void> _loadUrl() async {
    try {
      final url = await _service.getInstagramUrl();
      if (!mounted) return;
      setState(() { _controller.text = url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to load Instagram link.'; });
    }
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    final uri = Uri.tryParse(value);
    if (uri == null || !['http', 'https'].contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) {
      setState(() => _error = 'Enter a valid Instagram URL.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _service.saveInstagramUrl(value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instagram URL saved successfully.')));
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
        title: const Text('Instagram Edit'),
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 90), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.camera_alt, color: Color(0xFFE1306C)), SizedBox(width: 8), Text('Instagram', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 20),
                TextField(controller: _controller, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Instagram URL *', hintText: 'https://www.instagram.com/your-account', border: OutlineInputBorder())),
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
