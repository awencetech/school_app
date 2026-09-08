import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/student_campaign.dart';
import '../../routes/app_routes.dart';
import '../../services/student_campaign_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';

class StaffCampaignsPage extends StatefulWidget {
  const StaffCampaignsPage({
    super.key,
    this.headerTitle = 'SAMUNI',
    this.quickAccessTitle,
  });

  final String headerTitle;
  final String? quickAccessTitle;

  @override
  State<StaffCampaignsPage> createState() => _StaffCampaignsPageState();
}

class _StaffCampaignsPageState extends State<StaffCampaignsPage> {
  final _service = StudentCampaignService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _classController = TextEditingController();
  final _instructionsController = TextEditingController();
  List<StudentCampaign> _campaigns = [];
  String? _selectedCampaignId;
  String _type = 'Campaign';
  DateTime? _startDate;
  DateTime? _endDate;
  PlatformFile? _poster;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  bool get _staffMode => widget.quickAccessTitle == null;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _classController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    try {
      final campaigns = await _service.getCampaigns();
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load campaigns.';
      });
    }
  }

  Future<void> _pickPoster() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result != null && mounted) {
      setState(() => _poster = result);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _saveCampaign() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final className = _classController.text.trim();
    if (title.isEmpty || description.isEmpty || className.isEmpty || _startDate == null || _endDate == null) {
      setState(() => _error = 'Complete all required campaign fields.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date must be on or after start date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await _service.createCampaign(
        title: title,
        description: description,
        type: _type,
        className: className,
        startDate: _startDate!,
        endDate: _endDate!,
        instructions: _instructionsController.text.trim(),
        poster: _poster,
      );
      if (!mounted) return;
      _titleController.clear();
      _descriptionController.clear();
      _classController.clear();
      _instructionsController.clear();
      setState(() {
        _saving = false;
        _poster = null;
        _startDate = null;
        _endDate = null;
        _success = 'Campaign uploaded successfully.';
      });
      await _loadCampaigns();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to upload campaign. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.quickAccessTitle != null
          ? QuickAccessAppBar(title: widget.quickAccessTitle!)
          : AppBar(
              backgroundColor: const Color(0xff34395f),
              elevation: 0,
              toolbarHeight: 39,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => navigateBack(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              centerTitle: true,
              title: Text(widget.headerTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
      body: _staffMode ? _staffForm() : _studentList(),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _staffForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Campaign / Survey Form', style: TextStyle(fontSize: 12, color: Color(0xff1d3557))),
          const SizedBox(height: 8),
          _field(_titleController, 'Campaign / Survey Title'),
          _field(_descriptionController, 'Description', maxLines: 3),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Campaign / Survey Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Campaign', child: Text('Campaign')),
              DropdownMenuItem(value: 'Survey', child: Text('Survey')),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'Campaign'),
          ),
          _field(_classController, 'Class / Section'),
          _dateButton('Start Date', _startDate, () => _pickDate(start: true)),
          _dateButton('End Date', _endDate, () => _pickDate(start: false)),
          _field(_instructionsController, 'Instructions / Additional Information', maxLines: 3),
          OutlinedButton.icon(onPressed: _pickPoster, icon: const Icon(Icons.image_outlined), label: Text(_poster?.name ?? 'Choose Image')),
          if (_error != null) Text(_error!, style: const TextStyle(fontSize: 10, color: Colors.red)),
          if (_success != null) Text(_success!, style: const TextStyle(fontSize: 10, color: Colors.green)),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _saving ? null : _saveCampaign, icon: const Icon(Icons.upload), label: Text(_saving ? 'Uploading...' : 'Upload Campaign')),
          const SizedBox(height: 14),
          const Text('Uploaded Campaigns', style: TextStyle(fontSize: 11, color: Color(0xff1d3557))),
          if (_loading) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          ..._campaigns.map(_campaignCard),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_today, size: 16), label: Text('$label: ${value == null ? 'Select Date' : _date(value)}')),
  );

  Widget _studentList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_campaigns.isEmpty) return const Center(child: Text('No campaigns available.'));
    return ListView(padding: const EdgeInsets.all(6), children: _campaigns.map(_campaignCard).toList());
  }

  Widget _campaignCard(StudentCampaign campaign) {
    final selected = _selectedCampaignId == campaign.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          ListTile(
            leading: _image(campaign.imageUrl, width: 48, height: 48),
            title: Text(campaign.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            subtitle: Text('${campaign.description}\n${campaign.type} | ${campaign.className}\n${_date(campaign.startDate)} - ${_date(campaign.endDate)}', style: const TextStyle(fontSize: 8)),
            trailing: TextButton(
              onPressed: () {
                if (!_staffMode) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _StudentCampaignDetailPage(campaign: campaign),
                    ),
                  );
                  return;
                }
                setState(() => _selectedCampaignId = selected ? null : campaign.id);
              },
              child: Text(selected ? 'Hide' : 'Select', style: const TextStyle(fontSize: 9)),
            ),
          ),
          if (selected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(campaign.imageUrl, width: 72, height: 72),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${campaign.description}\n\nType: ${campaign.type}\nClass: ${campaign.className}\n${_date(campaign.startDate)} - ${_date(campaign.endDate)}\n\n${campaign.instructions}',
                      style: const TextStyle(fontSize: 9, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _image(String source, {required double width, required double height}) {
    if (source.isEmpty) return SizedBox(width: width, height: height, child: const Icon(Icons.image_outlined));
    final ImageProvider<Object> provider = source.startsWith('data:image')
      ? MemoryImage(base64Decode(source.split(',').last))
      : NetworkImage(source);
    return Image(image: provider, width: width, height: height, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined));
  }

  String _date(DateTime? value) => value == null ? 'Not set' : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  Widget _bottomNavigation(BuildContext context) => ReusableBottomNavigationBar(
    currentIndex: 2,
    onItemSelected: (index) {
      if (index == 4) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
      BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
      BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
      BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
    ],
  );
}

class _StudentCampaignDetailPage extends StatelessWidget {
  const _StudentCampaignDetailPage({required this.campaign});

  final StudentCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Respond to Campaigns, Surveys',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            const SizedBox(height: 5),
            Text(
              'Description: ${campaign.title}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              'Type: ${campaign.type}\nClass: ${campaign.className}\nStart: ${_formatDate(campaign.startDate)}\nEnd: ${_formatDate(campaign.endDate)}',
              style: const TextStyle(fontSize: 9),
            ),
            const SizedBox(height: 10),
            _largeImage(campaign.imageUrl),
            const SizedBox(height: 12),
            Text(
              campaign.description,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            if (campaign.instructions.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Instructions:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffd71919),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                campaign.instructions,
                style: const TextStyle(fontSize: 11, height: 1.35),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.main,
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
        ],
      ),
    );
  }

  Widget _largeImage(String source) {
    if (source.isEmpty) {
      return Container(
        height: 190,
        color: const Color(0xffeeeeee),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 48, color: Color(0xff999999)),
      );
    }
    final ImageProvider<Object> provider = source.startsWith('data:image')
        ? MemoryImage(base64Decode(source.split(',').last))
        : NetworkImage(source);
    return Image(
      image: provider,
      width: double.infinity,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        height: 190,
        child: Icon(Icons.image_not_supported_outlined, size: 48),
      ),
    );
  }

  String _formatDate(DateTime? value) => value == null
      ? 'Not set'
      : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
}
