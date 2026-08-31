import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/social_url_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class WhatsappEditPage extends StatefulWidget {
  const WhatsappEditPage({super.key});

  @override
  State<WhatsappEditPage> createState() => _WhatsappEditPageState();
}

class _WhatsappEditPageState extends State<WhatsappEditPage> {
  final _service = SocialUrlService();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadConfig(); }

  Future<void> _loadConfig() async {
    try {
      final config = await _service.getWhatsappConfig();
      if (!mounted) return;
      setState(() {
        _phoneController.text = config['phoneNumber'] ?? '';
        _messageController.text = config['text'] ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Unable to load WhatsApp configuration.'; });
    }
  }

  Future<void> _save() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final message = _messageController.text.trim();
    if (phone.length < 8 || phone.length > 15) {
      setState(() => _error = 'Enter a valid international WhatsApp number.');
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = 'Default message text is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _service.saveWhatsappConfig(phoneNumber: phone, text: message);
      if (!mounted) return;
      _phoneController.text = phone;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp configuration saved successfully.')));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _phoneController.dispose(); _messageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('WhatsApp Edit'),
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 90), children: [
              if (_error != null && _phoneController.text.isEmpty)
                Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Text(_error!, style: const TextStyle(color: Colors.red)), TextButton(onPressed: _loadConfig, child: const Text('Retry'))])))
              else
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.chat, color: Color(0xFF25D366)), SizedBox(width: 8), Text('WhatsApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 20),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Number *', hintText: '919876543210', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _messageController, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Default Message Text *', hintText: 'Hello, I would like to know more about the school.', border: OutlineInputBorder())),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save WhatsApp'))),
                ]))),
            ]),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (index) {
        if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
      }),
    );
  }
}
