import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';
import '../../services/online_assignment_service.dart';
import '../../widgets/admin_bottom_nav.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class StudentSubmission {
  final String id;
  final String studentName;
  final DateTime submittedDate;
  final String status; // Submitted, Pending, Late, Not Submitted
  double? marks;
  final String? feedback;

  StudentSubmission({
    required this.id,
    required this.studentName,
    required this.submittedDate,
    required this.status,
    this.marks,
    this.feedback,
  });

  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    return StudentSubmission(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      submittedDate:
          DateTime.tryParse((json['submittedDate'] ?? '').toString()) ??
          DateTime.now(),
      status: (json['status'] ?? 'Pending').toString(),
      marks: json['marks'] is num
          ? (json['marks'] as num).toDouble()
          : double.tryParse((json['marks'] ?? '').toString()),
      feedback: json['feedback']?.toString(),
    );
  }

  StudentSubmission copyWith({
    String? id,
    String? studentName,
    DateTime? submittedDate,
    String? status,
    double? marks,
    String? feedback,
  }) {
    return StudentSubmission(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      submittedDate: submittedDate ?? this.submittedDate,
      status: status ?? this.status,
      marks: marks ?? this.marks,
      feedback: feedback ?? this.feedback,
    );
  }
}

class Assignment {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String instructions;
  final DateTime assignedDate;
  final DateTime dueDate;
  final int maxMarks;
  final String status; // Draft, Active, Pending, Submitted, Overdue, Closed
  final String folder;
  final List<String> attachments;
  final List<StudentSubmission> submissions;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.instructions,
    required this.assignedDate,
    required this.dueDate,
    required this.maxMarks,
    required this.status,
    required this.folder,
    this.attachments = const [],
    this.submissions = const [],
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    DateTime readDate(dynamic value) =>
        DateTime.tryParse((value ?? '').toString()) ?? DateTime.now();

    return Assignment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      assignedDate: readDate(json['assignedDate']),
      dueDate: readDate(json['dueDate']),
      maxMarks: json['maxMarks'] is num
          ? (json['maxMarks'] as num).toInt()
          : int.tryParse((json['maxMarks'] ?? '').toString()) ?? 0,
      status: (json['status'] ?? 'Active').toString(),
      folder: (json['folder'] ?? 'Assignments').toString(),
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      submissions: (json['submissions'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              StudentSubmission.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'description': description,
    'instructions': instructions,
    'assignedDate': assignedDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'maxMarks': maxMarks,
    'status': status,
    'folder': folder,
    'attachments': attachments,
  };

  Assignment copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    String? instructions,
    DateTime? assignedDate,
    DateTime? dueDate,
    int? maxMarks,
    String? status,
    String? folder,
    List<String>? attachments,
    List<StudentSubmission>? submissions,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      maxMarks: maxMarks ?? this.maxMarks,
      status: status ?? this.status,
      folder: folder ?? this.folder,
      attachments: attachments ?? this.attachments,
      submissions: submissions ?? this.submissions,
    );
  }
}

// ============================================================================
// ONLINE ASSIGNMENT PAGE
// ============================================================================

class OnlineAssignmentPage extends StatefulWidget {
  const OnlineAssignmentPage({
    super.key,
    required this.group,
    this.isViewOnly = false,
    this.assignmentService,
  });

  final Group group;
  final bool isViewOnly;
  final OnlineAssignmentService? assignmentService;

  @override
  State<OnlineAssignmentPage> createState() => _OnlineAssignmentPageState();
}

class _OnlineAssignmentPageState extends State<OnlineAssignmentPage> {
  late final OnlineAssignmentService _service =
      widget.assignmentService ?? OnlineAssignmentService();
  List<Assignment> _allAssignments = [];
  bool _isLoading = true;
  String? _loadError;
  String _viewMode = 'list'; // list, grid, folders, analyse
  String _filterStatus = 'All'; // All, Active, Pending, Submitted, Overdue
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final groupReferences = [
        widget.group.databaseId,
        widget.group.name,
        widget.group.code,
      ].where((value) => value.trim().isNotEmpty).toList();
      final records = await _service.getAssignments(
        groupId: widget.group.id,
        groupReferences: groupReferences,
      );
      if (!mounted) return;
      setState(() {
        _allAssignments = records.map(Assignment.fromJson).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================================
  // FILTERS AND SEARCH
  // ============================================================================

  List<Assignment> _getFilteredAssignments() {
    List<Assignment> assignments = _allAssignments;

    if (_filterStatus != 'All') {
      assignments = assignments.where((a) => a.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      assignments = assignments.where((a) => a.title.toLowerCase().contains(query) || a.subject.toLowerCase().contains(query)).toList();
    }

    return assignments;
  }

  int _getTotalCount() => _allAssignments.length;
  int _getActiveCount() => _allAssignments.where((a) => a.status == 'Active').length;
  int _getPendingCount() => _allAssignments.fold(0, (sum, a) => sum + a.submissions.where((s) => s.status == 'Pending').length);
  int _getSubmittedCount() => _allAssignments.fold(0, (sum, a) => sum + a.submissions.where((s) => s.status == 'Submitted').length);
  int _getOverdueCount() => _allAssignments.where((a) => a.status == 'Overdue').length;

  String _getDueDateLabel(Assignment assignment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(assignment.dueDate.year, assignment.dueDate.month, assignment.dueDate.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (dueDay.isBefore(today)) {
      final daysOverdue = today.difference(dueDay).inDays;
      return '⚠ Overdue • $daysOverdue days ago';
    } else if (dueDay == today) {
      return 'Due Today';
    } else if (dueDay == tomorrow) {
      return 'Due Tomorrow';
    } else {
      final daysLeft = dueDay.difference(today).inDays;
      return 'Due in $daysLeft days';
    }
  }

  // ============================================================================
  // DIALOGS & NAVIGATION
  // ============================================================================

  void _openAddDialog() async {
    final result = await showDialog<Assignment>(
      context: context,
      builder: (context) => _CreateAssignmentDialog(),
    );
    if (result != null) {
      try {
        await _service.createAssignment(
          groupId: widget.group.id,
          assignment: result.toJson(),
        );
        await _loadAssignments();
      } catch (error) {
        _showRequestError(error);
      }
    }
  }

  void _openDetails(Assignment assignment) async {
    final result = await showDialog<Assignment?>(
      context: context,
      builder: (context) => _AssignmentDetailsDialog(assignment: assignment),
    );
    if (result != null) {
      setState(() {
        final index = _allAssignments.indexWhere((a) => a.id == assignment.id);
        if (index >= 0) _allAssignments[index] = result;
      });
    }
  }

  void _openEdit(Assignment assignment) async {
    final result = await showDialog<Assignment>(
      context: context,
      builder: (context) => _EditAssignmentDialog(assignment: assignment),
    );
    if (result != null) {
      try {
        await _service.updateAssignment(
          groupId: widget.group.id,
          assignmentId: assignment.id,
          assignment: result.toJson(),
        );
        await _loadAssignments();
      } catch (error) {
        _showRequestError(error);
      }
    }
  }

  void _deleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: const Text('Are you sure you want to delete this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAssignment(assignment.id);
      await _loadAssignments();
    } catch (error) {
      _showRequestError(error);
    }
  }

  void _duplicateAssignment(Assignment assignment) async {
    final copy = assignment.copyWith(
      id: '',
      title: '${assignment.title} (Copy)',
      submissions: const [],
    );
    try {
      await _service.createAssignment(
        groupId: widget.group.id,
        assignment: copy.toJson(),
      );
      await _loadAssignments();
    } catch (error) {
      _showRequestError(error);
    }
  }

  void _showRequestError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to save assignment: $error')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Color(0xffc5cad1),
            ),
            const SizedBox(height: 12),
            const Text(
              'No assignments available.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff363b60),
              ),
              textAlign: TextAlign.center,
            ),
            if (!widget.isViewOnly) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openAddDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2baac8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Assignment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final filteredAssignments = _getFilteredAssignments();
    final folders = {'Mathematics': 0, 'Science': 0, 'English': 0, 'Homework': 0, 'Projects': 0, 'Exams': 0};
    for (var a in _allAssignments) {
      if (folders.containsKey(a.folder)) folders[a.folder] = (folders[a.folder] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff4f5f8),
      appBar: AppBar(
        backgroundColor: const Color(0xff363b60),
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Online Assignments', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(widget.group.name, style: const TextStyle(color: Color(0xffb8bcc8), fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 22, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load assignments.'),
                        const SizedBox(height: 8),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAssignments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _allAssignments.isEmpty
                  ? _buildEmptyState()
                  : _viewMode == 'analyse'
          ? _buildAnalyticsView()
          : _viewMode == 'folders'
              ? _buildFoldersView(folders)
              : SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Summary
                          _buildSummary(),
                          const SizedBox(height: 16),

                          // Search
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: '🔍 Search assignments...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xff7a7a7a)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // View Tabs
                          _buildViewTabs(),
                          const SizedBox(height: 12),

                          // Filters
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['All', 'Active', 'Pending', 'Submitted', 'Overdue'].map((filter) {
                                final isSelected = _filterStatus == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) => setState(() => _filterStatus = filter),
                                    backgroundColor: Colors.white,
                                    selectedColor: const Color(0xff2baac8),
                                    labelStyle: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xff363b60), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                                    side: BorderSide(color: isSelected ? const Color(0xff2baac8) : const Color(0xffe4e6eb)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Assignments
                          if (filteredAssignments.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    const Icon(Icons.assignment_outlined, size: 48, color: Color(0xffc5cad1)),
                                    const SizedBox(height: 12),
                                    const Text('No assignments available.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
                                    const SizedBox(height: 6),
                                    const Text('Create an assignment to give students homework and class activities.', style: TextStyle(fontSize: 12, color: Color(0xff7a7a7a))),
                                    const SizedBox(height: 16),
                                    if (!widget.isViewOnly) ElevatedButton.icon(onPressed: _openAddDialog, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), icon: const Icon(Icons.add, size: 16), label: const Text('Create Assignment')),
                                  ],
                                ),
                              ),
                            )
                          else if (_viewMode == 'grid')
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.95,
                              children: filteredAssignments.map((a) => _buildAssignmentGridCard(a)).toList(),
                            )
                          else
                            Column(
                              children: filteredAssignments.map((a) => _buildAssignmentCard(a)).toList(),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: widget.isViewOnly ? null : FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: const Color(0xff2baac8),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Create Assignment'),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assignments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Total', value: '${_getTotalCount()}')),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(label: 'Active', value: '${_getActiveCount()}')),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(label: 'Pending', value: '${_getPendingCount()}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Submitted', value: '${_getSubmittedCount()}')),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(label: 'Overdue', value: '${_getOverdueCount()}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabs() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          _buildViewTab('list', '📋 List'),
          _buildViewTab('grid', '▦ Grid'),
          _buildViewTab('folders', '📁 Folders'),
          _buildViewTab('analyse', '📊 Analyse'),
        ],
      ),
    );
  }

  Widget _buildViewTab(String mode, String label) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff2baac8) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xff7a7a7a))),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final statusColor = assignment.status == 'Active'
        ? const Color(0xff10b981)
        : assignment.status == 'Overdue'
            ? const Color(0xffef4444)
            : assignment.status == 'Closed'
                ? const Color(0xff6b7280)
                : const Color(0xff3b82f6);

    return GestureDetector(
      onTap: () => _openDetails(assignment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignment.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff222222))),
                      const SizedBox(height: 2),
                      Text(assignment.subject, style: const TextStyle(fontSize: 11, color: Color(0xff7a7a7a))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(assignment.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(assignment.description, style: const TextStyle(fontSize: 11, color: Color(0xff4a4a4a)), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xff7a7a7a)),
                const SizedBox(width: 4),
                Expanded(child: Text(DateFormat('MMM d, yyyy').format(assignment.assignedDate), style: const TextStyle(fontSize: 10, color: Color(0xff7a7a7a)))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 14, color: Color(0xff7a7a7a)),
                const SizedBox(width: 4),
                Expanded(child: Text(_getDueDateLabel(assignment), style: TextStyle(fontSize: 10, color: assignment.status == 'Overdue' ? Colors.red : const Color(0xff7a7a7a), fontWeight: assignment.status == 'Overdue' ? FontWeight.w600 : FontWeight.normal))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('${assignment.submissions.where((s) => s.status == 'Submitted').length} / 30 Submitted', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff363b60)))),
                IconButton(icon: const Icon(Icons.more_vert, size: 18), onPressed: () => _showAssignmentMenu(assignment)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentGridCard(Assignment assignment) {
    final statusColor = assignment.status == 'Active' ? const Color(0xff10b981) : assignment.status == 'Overdue' ? const Color(0xffef4444) : const Color(0xff3b82f6);

    return GestureDetector(
      onTap: () => _openDetails(assignment),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
              child: Text(assignment.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
            ),
            const SizedBox(height: 8),
            Text(assignment.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff222222)), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(assignment.subject, style: const TextStyle(fontSize: 10, color: Color(0xff7a7a7a))),
            const SizedBox(height: 6),
            Text(_getDueDateLabel(assignment), style: const TextStyle(fontSize: 9, color: Color(0xff7a7a7a))),
            const Spacer(),
            Text('${assignment.submissions.where((s) => s.status == 'Submitted').length}/30', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersView(Map<String, int> folders) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...folders.entries.map((e) {
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = 'All'), // Could filter by folder
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 28, color: Color(0xfff59e0b)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff222222))),
                              Text('${e.value} Assignments', style: const TextStyle(fontSize: 11, color: Color(0xff7a7a7a))),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: Color(0xff7a7a7a)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    final totalStudents = 30;
    final submitted = _allAssignments.fold(0, (sum, a) => sum + a.submissions.where((s) => s.status == 'Submitted').length);
    final pending = _allAssignments.fold(0, (sum, a) => sum + a.submissions.where((s) => s.status == 'Pending').length);
    final late = _allAssignments.fold(0, (sum, a) => sum + a.submissions.where((s) => s.status == 'Late').length);
    final submissionRate = ((submitted / (submitted + pending)) * 100).toStringAsFixed(1);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Analytics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
                    const SizedBox(height: 16),
                    _AnalyticsItem(label: 'Total Students', value: '$totalStudents'),
                    const SizedBox(height: 12),
                    _AnalyticsItem(label: 'Submissions', value: '$submitted'),
                    const SizedBox(height: 12),
                    _AnalyticsItem(label: 'Pending', value: '$pending'),
                    const SizedBox(height: 12),
                    _AnalyticsItem(label: 'Late Submissions', value: '$late'),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submission Rate: $submissionRate%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
                        const SizedBox(height: 8),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: double.parse(submissionRate) / 100, minHeight: 8, backgroundColor: const Color(0xffe4e6eb), valueColor: const AlwaysStoppedAnimation(Color(0xff10b981)))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignmentMenu(Assignment assignment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('View Details'), onTap: () {
              Navigator.pop(context);
              _openDetails(assignment);
            }),
            if (!widget.isViewOnly) ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit'), onTap: () {
              Navigator.pop(context);
              _openEdit(assignment);
            }),
            ListTile(leading: const Icon(Icons.people_outline), title: const Text('View Submissions'), onTap: () {
              Navigator.pop(context);
              _showSubmissions(assignment);
            }),
            if (!widget.isViewOnly) ListTile(leading: const Icon(Icons.content_copy_outlined), title: const Text('Duplicate'), onTap: () {
              Navigator.pop(context);
              _duplicateAssignment(assignment);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment duplicated')));
            }),
            if (!widget.isViewOnly) ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () {
              Navigator.pop(context);
              _deleteAssignment(assignment);
            }),
          ],
        ),
      ),
    );
  }

  void _showSubmissions(Assignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${assignment.title} - Submissions', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${assignment.submissions.length} Students', style: const TextStyle(fontSize: 12, color: Color(0xff7a7a7a))),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: assignment.submissions.length,
                itemBuilder: (context, index) {
                  final sub = assignment.submissions[index];
                  return ListTile(
                    title: Text(sub.studentName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    subtitle: Text(sub.status, style: const TextStyle(fontSize: 11)),
                    trailing: sub.marks != null ? Text('${sub.marks}/${assignment.maxMarks}', style: const TextStyle(fontWeight: FontWeight.w600)) : null,
                    onTap: () {
                      Navigator.pop(context);
                      _showGradingDialog(assignment, sub);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradingDialog(Assignment assignment, StudentSubmission submission) {
    final marksController = TextEditingController(text: submission.marks?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade: ${submission.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: marksController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Marks / ${assignment.maxMarks}', border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: feedbackController, maxLines: 3, decoration: const InputDecoration(labelText: 'Feedback', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final parsedMarks = double.tryParse(marksController.text);
              if (parsedMarks != null) {
                submission.marks = parsedMarks;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade saved')));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)),
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xfff4f5f8), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff7a7a7a), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xff363b60))),
        ],
      ),
    );
  }
}

class _AnalyticsItem extends StatelessWidget {
  final String label;
  final String value;
  const _AnalyticsItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff7a7a7a))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
      ],
    );
  }
}

// ============================================================================
// DIALOGS
// ============================================================================

class _CreateAssignmentDialog extends StatefulWidget {
  const _CreateAssignmentDialog();

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _instrController = TextEditingController();
  final _marksController = TextEditingController();
  final DateTime _assignDate = DateTime.now();
  final DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _folder = 'Mathematics';
  String _status = 'Draft';

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _instrController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter assignment title')));
      return;
    }
    final maxMarks = int.tryParse(_marksController.text.trim());
    if (maxMarks == null || maxMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the maximum marks for this assignment.')),
      );
      return;
    }

    final assignment = Assignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descController.text,
      instructions: _instrController.text,
      assignedDate: _assignDate,
      dueDate: _dueDate,
      maxMarks: maxMarks,
      status: _status,
      folder: _folder,
      submissions: [],
    );

    Navigator.pop(context, assignment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Assignment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Assignment Title *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _instrController, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _marksController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Marks', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _folder,
              onChanged: (value) => setState(() => _folder = value ?? 'Mathematics'),
              decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
              items: ['Mathematics', 'Science', 'English', 'Homework', 'Projects', 'Exams'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Draft'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Draft', 'Active', 'Closed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), child: const Text('Save Assignment')),
      ],
    );
  }
}

class _EditAssignmentDialog extends StatefulWidget {
  final Assignment assignment;
  const _EditAssignmentDialog({required this.assignment});

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _descController;
  late TextEditingController _instrController;
  late TextEditingController _marksController;
  late String _folder;
  late String _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _subjectController = TextEditingController(text: widget.assignment.subject);
    _descController = TextEditingController(text: widget.assignment.description);
    _instrController = TextEditingController(text: widget.assignment.instructions);
    _marksController = TextEditingController(text: widget.assignment.maxMarks.toString());
    _folder = widget.assignment.folder;
    _status = widget.assignment.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _instrController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.assignment.copyWith(
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descController.text,
      instructions: _instrController.text,
      maxMarks:
          int.tryParse(_marksController.text) ?? widget.assignment.maxMarks,
      folder: _folder,
      status: _status,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Assignment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Assignment Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _instrController, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _marksController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Marks', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _folder,
              onChanged: (value) => setState(() => _folder = value ?? 'Mathematics'),
              decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
              items: ['Mathematics', 'Science', 'English', 'Homework', 'Projects', 'Exams'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Draft'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Draft', 'Active', 'Pending', 'Submitted', 'Overdue', 'Closed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), child: const Text('Save Changes')),
      ],
    );
  }
}

class _AssignmentDetailsDialog extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentDetailsDialog({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final submitted = assignment.submissions.where((s) => s.status == 'Submitted').length;
    final pending = assignment.submissions.where((s) => s.status == 'Pending').length;

    return AlertDialog(
      title: const Text('Assignment Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Title', value: assignment.title),
            _DetailRow(label: 'Subject', value: assignment.subject),
            _DetailRow(label: 'Assigned', value: DateFormat('MMM d, yyyy').format(assignment.assignedDate)),
            _DetailRow(label: 'Due', value: DateFormat('MMM d, yyyy').format(assignment.dueDate)),
            _DetailRow(label: 'Max Marks', value: '${assignment.maxMarks}'),
            _DetailRow(label: 'Status', value: assignment.status),
            _DetailRow(label: 'Submissions', value: '$submitted Submitted, $pending Pending'),
            if (assignment.description.isNotEmpty) _DetailRow(label: 'Description', value: assignment.description),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(onPressed: () => Navigator.pop(context, assignment), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), child: const Text('Edit')),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xff7a7a7a)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, color: Color(0xff222222)))),
        ],
      ),
    );
  }
}
