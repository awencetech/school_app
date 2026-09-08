import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/student_ptm.dart';
import '../../routes/app_routes.dart';
import '../../services/preferences_service.dart';
import '../../services/student_ptm_service.dart';
import '../../services/student_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentPtmPage extends StatefulWidget {
  const StudentPtmPage({
    super.key,
    this.headerTitle = 'SAMUNI',
    this.quickAccessTitle,
    this.staffMode = false,
  });

  final String headerTitle;
  final String? quickAccessTitle;
  final bool staffMode;

  @override
  State<StudentPtmPage> createState() => _StudentPtmPageState();
}

class _StudentPtmPageState extends State<StudentPtmPage> {
  final _service = StudentPtmService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _venueController = TextEditingController();
  final _instructionsController = TextEditingController();
  List<StudentPtm> _ptms = [];
  List<_ClassOption> _classOptions = [];
  _ClassOption? _selectedClass;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  PlatformFile? _selectedImage;
  bool _loading = true;
  bool _publishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _venueController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await PreferencesService.getString('auth_user_token');
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required.');
      }
      if (widget.staffMode) {
        final students = await StudentService().getStudents();
        _classOptions = _optionsFromStudents(students);
      }
      _ptms = await _service.getPtms();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_ClassOption> _optionsFromStudents(List<StudentRecord> students) {
    final options = <_ClassOption>[];
    for (final student in students) {
      final className = student.className.trim();
      final section = student.section.trim();
      if (className.isEmpty || section.isEmpty) continue;
      final option = _ClassOption(className, section);
      if (!options.any((item) => item.value == option.value)) options.add(option);
    }
    options.sort((a, b) => a.value.compareTo(b.value));
    return options;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _selectedDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result != null) {
      setState(() => _selectedImage = result);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final venue = _venueController.text.trim();
    if (title.isEmpty || message.isEmpty || _selectedClass == null ||
        _selectedDate == null || _selectedTime == null || venue.isEmpty) {
      setState(() => _error = 'Title, message, class, date, time, and venue are required.');
      return;
    }
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final date = _selectedDate!;
      final time = _selectedTime!;
      await _service.createPtm(
        title: title,
        message: message,
        className: _selectedClass!.className,
        section: _selectedClass!.section,
        date: '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        time: time.format(context),
        venue: venue,
        instructions: _instructionsController.text.trim(),
        image: _selectedImage,
      );
      _titleController.clear();
      _messageController.clear();
      _venueController.clear();
      _instructionsController.clear();
      setState(() {
        _selectedClass = null;
        _selectedDate = null;
        _selectedTime = null;
        _selectedImage = null;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PTM published successfully')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _publishing = false);
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
              toolbarHeight: 44,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => navigateBack(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              centerTitle: true,
              title: Text(widget.headerTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
      body: _loading
          ? const Center(child: Text('Loading PTM...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Text(widget.staffMode ? 'PTM' : 'PTM List', style: const TextStyle(fontSize: 16, color: Color(0xff1d3557), fontWeight: FontWeight.w600)),
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (widget.staffMode) ...[
                    _buildForm(),
                    const SizedBox(height: 12),
                    const Text('Published PTMs', style: TextStyle(fontSize: 13, color: Color(0xff1d3557), fontWeight: FontWeight.w600)),
                  ],
                  if (_ptms.isEmpty && _error == null)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No PTM available', style: TextStyle(color: Colors.grey)))),
                  ..._ptms.map((ptm) => _PtmCard(ptm: ptm)),
                ],
              ),
            ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _field(_titleController, 'PTM Title'),
        _field(_messageController, 'Message', maxLines: 3),
        DropdownButtonFormField<_ClassOption>(
          initialValue: _selectedClass,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Class / Section', border: OutlineInputBorder()),
          items: _classOptions.map((item) => DropdownMenuItem(value: item, child: Text(item.value))).toList(),
          onChanged: (value) => setState(() => _selectedClass = value),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today, size: 16), label: Text(_selectedDate == null ? 'Select Date' : _formatDate(_selectedDate!)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule, size: 16), label: Text(_selectedTime?.format(context) ?? 'Select Time'))),
        ]),
        const SizedBox(height: 8),
        _field(_venueController, 'Venue'),
        _field(_instructionsController, 'Additional Instructions', maxLines: 2),
        Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.upload_file, size: 16), label: Text(_selectedImage?.name ?? 'Upload Image / Notice'))),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _publishing ? null : _publish, child: Text(_publishing ? 'Publishing...' : 'Publish PTM'))),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
      );

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ClassOption {
  const _ClassOption(this.className, this.section);
  final String className;
  final String section;
  String get value => '$className-$section';
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        color: const Color(0xffffeeee),
        child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 12)),
      );
}

class _PtmCard extends StatelessWidget {
  const _PtmCard({required this.ptm});
  final StudentPtm ptm;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _PtmDetails(ptm: ptm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ptm.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 5),
              Text('Class: ${ptm.classSection}\nDate: ${ptm.date}\nTime: ${ptm.time}\nVenue: ${ptm.venue}', style: const TextStyle(fontSize: 12, height: 1.4)),
              const SizedBox(height: 5),
              Text(ptm.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              const Align(alignment: Alignment.centerRight, child: Text('View Details', style: TextStyle(color: Color(0xff34395f), fontWeight: FontWeight.w600, fontSize: 12))),
            ]),
          ),
        ),
      );
}

class _PtmDetails extends StatelessWidget {
  const _PtmDetails({required this.ptm});
  final StudentPtm ptm;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ptm.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(ptm.message),
            const SizedBox(height: 10),
            Text('Class: ${ptm.classSection}\nDate: ${ptm.date}\nTime: ${ptm.time}\nVenue: ${ptm.venue}'),
            if (ptm.instructions.isNotEmpty) ...[const SizedBox(height: 10), Text('Instructions: ${ptm.instructions}')],
            if (ptm.imageUrl.isNotEmpty) ...[const SizedBox(height: 12), Image.network(ptm.imageUrl, errorBuilder: (_, _, _) => const SizedBox.shrink())],
          ]),
        ),
      );
}
