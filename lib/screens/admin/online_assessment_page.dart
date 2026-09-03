import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

enum AssessmentView { list, grid, folders, analyse }

enum QuestionType { multipleChoice, multipleSelect, trueFalse, shortAnswer, longAnswer }

class AssessmentQuestion {
  AssessmentQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.marks,
  });

  final String id;
  final String question;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final int marks;
}

class Assessment {
  Assessment({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.description,
    required this.instructions,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
    required this.folder,
    required this.totalQuestions,
    required this.totalMarks,
    required this.passingMarks,
    required this.numberOfStudents,
    required this.completedCount,
    required this.attempts,
    required this.questions,
  });

  final String id;
  final String title;
  final String subject;
  final String topic;
  final String description;
  final String instructions;
  final String date;
  final String startTime;
  final String endTime;
  final String duration;
  final String status;
  final String folder;
  final int totalQuestions;
  final int totalMarks;
  final int passingMarks;
  final int numberOfStudents;
  final int completedCount;
  final int attempts;
  final List<AssessmentQuestion> questions;

  Assessment copyWith({
    String? id,
    String? title,
    String? subject,
    String? topic,
    String? description,
    String? instructions,
    String? date,
    String? startTime,
    String? endTime,
    String? duration,
    String? status,
    String? folder,
    int? totalQuestions,
    int? totalMarks,
    int? passingMarks,
    int? numberOfStudents,
    int? completedCount,
    int? attempts,
    List<AssessmentQuestion>? questions,
  }) {
    return Assessment(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      folder: folder ?? this.folder,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      numberOfStudents: numberOfStudents ?? this.numberOfStudents,
      completedCount: completedCount ?? this.completedCount,
      attempts: attempts ?? this.attempts,
      questions: questions ?? this.questions,
    );
  }
}

class StudentResult {
  const StudentResult({
    required this.name,
    required this.status,
    required this.score,
    required this.percentage,
    required this.submittedDate,
  });

  final String name;
  final String status;
  final int score;
  final int percentage;
  final String submittedDate;
}

class OnlineAssessmentPage extends StatefulWidget {
  const OnlineAssessmentPage({super.key, required this.group, this.isViewOnly = false});

  final Group group;
  final bool isViewOnly;

  @override
  State<OnlineAssessmentPage> createState() => _OnlineAssessmentPageState();
}

class _OnlineAssessmentPageState extends State<OnlineAssessmentPage> {
  AssessmentView _selectedView = AssessmentView.list;
  String _searchText = '';
  String _statusFilter = 'All';
  String _subjectFilter = 'All';
  String _dateFilter = 'Any';
  final String _sortBy = 'Newest';
  final List<Assessment> _assessments = _initialAssessments();

  void _duplicateAssessmentLocally(Assessment assessment) {
    final duplicate = assessment.copyWith(
      id: '${assessment.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
      title: '${assessment.title} (Copy)',
      status: 'Draft',
      completedCount: 0,
    );
    _assessments.insert(0, duplicate);
    setState(() {});
  }

  void _deleteAssessmentLocally(Assessment assessment) {
    _assessments.removeWhere((item) => item.id == assessment.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssessments = _getFilteredAssessments();
    final summary = _buildSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 92,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Online Assessments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.group.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              color: AppColors.topBar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessments & Quizzes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Assessments',
                          value: '${summary['total']}',
                          subtitle: 'Total',
                          accent: const Color(0xFFBEE3FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusPill(label: 'Draft', value: '${summary['draft']}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusPill(label: 'Active', value: '${summary['active']}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusPill(label: 'Completed', value: '${summary['completed']}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusPill(label: 'Upcoming', value: '${summary['upcoming']}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewTabs(),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.topBar, width: 1.2),
                        ),
                        hintText: 'Search assessments...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (value) => setState(() => _searchText = value.trim()),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterRow(),
                    const SizedBox(height: 12),
                    if (_selectedView == AssessmentView.list)
                      _buildListView(filteredAssessments)
                    else if (_selectedView == AssessmentView.grid)
                      _buildGridView(filteredAssessments)
                    else if (_selectedView == AssessmentView.folders)
                      _buildFolderView()
                    else
                      _buildAnalysisView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isViewOnly ? null : FloatingActionButton.extended(
        onPressed: _showCreateAssessmentDialog,
        backgroundColor: AppColors.topBar,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Assessment', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _buildViewTabs() {
    final tabs = [
      (_viewLabel(Icons.format_list_bulleted_rounded, 'List'), AssessmentView.list),
      (_viewLabel(Icons.grid_view_rounded, 'Grid'), AssessmentView.grid),
      (_viewLabel(Icons.folder_rounded, 'Folders'), AssessmentView.folders),
      (_viewLabel(Icons.pie_chart_rounded, 'Analyse'), AssessmentView.analyse),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final selected = _selectedView == item.$2;
          return GestureDetector(
            onTap: () => setState(() => _selectedView = item.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 102,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.topBar : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.topBar : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1.$1,
                    size: 15,
                    color: selected ? Colors.white : AppColors.primaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$1.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  (IconData, String) _viewLabel(IconData icon, String label) => (icon, label);

  Widget _buildFilterRow() {
    final statusChips = ['All', 'Draft', 'Upcoming', 'Active', 'Completed'];

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: statusChips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final label = statusChips[index];
              final selected = _statusFilter == label;
              return GestureDetector(
                onTap: () => setState(() => _statusFilter = label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFECF3FF) : Colors.white,
                    border: Border.all(
                      color: selected ? const Color(0xFFB6D6FF) : const Color(0xFFDFE6EE),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.topBar : AppColors.secondaryText,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'Subject',
                value: _subjectFilter,
                items: ['All', 'Mathematics', 'Science', 'English', 'History'],
                onChanged: (value) => setState(() => _subjectFilter = value ?? 'All'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown(
                label: 'Date',
                value: _dateFilter,
                items: ['Any', 'This Week', 'This Month', 'Upcoming'],
                onChanged: (value) => setState(() => _dateFilter = value ?? 'Any'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown(
                label: 'Status',
                value: _statusFilter,
                items: ['All', 'Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled'],
                onChanged: (value) => setState(() => _statusFilter = value ?? 'All'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Assessment> _getFilteredAssessments() {
    final query = _searchText.toLowerCase();
    final filtered = _assessments.where((assessment) {
      final matchesQuery = query.isEmpty ||
          assessment.title.toLowerCase().contains(query) ||
          assessment.subject.toLowerCase().contains(query) ||
          assessment.topic.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'All' || assessment.status == _statusFilter;
      final matchesSubject = _subjectFilter == 'All' || assessment.subject == _subjectFilter;

      final matchesDate = _dateFilter == 'Any' ||
          (_dateFilter == 'This Week' && _isThisWeek(assessment.date)) ||
          (_dateFilter == 'This Month' && _isThisMonth(assessment.date)) ||
          (_dateFilter == 'Upcoming' && assessment.status == 'Upcoming');

      return matchesQuery && matchesStatus && matchesSubject && matchesDate;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Title':
          return a.title.compareTo(b.title);
        case 'Marks':
          return b.totalMarks.compareTo(a.totalMarks);
        case 'Newest':
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  Widget _buildListView(List<Assessment> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assessment = items[index];
        return _AssessmentCard(assessment: assessment, onTap: () => _showAssessmentDetails(assessment));
      },
    );
  }

  Widget _buildGridView(List<Assessment> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final assessment = items[index];
        return _AssessmentCard(assessment: assessment, onTap: () => _showAssessmentDetails(assessment));
      },
    );
  }

  Widget _buildFolderView() {
    final folders = <String, int>{
      'Mathematics': 6,
      'Science': 5,
      'English': 4,
      'Unit Tests': 3,
      'Monthly Tests': 2,
      'Final Exams': 1,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final entry = folders.entries.toList()[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFE6EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.folder_rounded, size: 32, color: Color(0xFF7AA8FF)),
              const SizedBox(height: 14),
              Text(
                entry.key,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 6),
              Text(
                '${entry.value} Assessments',
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisView() {
    final totalAssessments = _assessments.length;
    final completionRate = _assessments.isEmpty
        ? 0
        : ((_assessments.fold<int>(0, (sum, item) => sum + item.completedCount) / _assessments.fold<int>(0, (sum, item) => sum + item.numberOfStudents)) * 100).round();
    final pending = _assessments.fold<int>(0, (sum, item) => sum + (item.numberOfStudents - item.completedCount));
    final allScores = <int>[];
    for (final assessment in _assessments) {
      allScores.add((assessment.completedCount / assessment.numberOfStudents * 100).round());
    }
    final averageScore = allScores.isEmpty ? 0 : allScores.reduce((a, b) => a + b) ~/ allScores.length;
    final highest = allScores.isEmpty ? 0 : allScores.reduce((a, b) => a > b ? a : b);
    final lowest = allScores.isEmpty ? 0 : allScores.reduce((a, b) => a < b ? a : b);

    final metrics = [
      _MetricTile(label: 'Total Assessments', value: '$totalAssessments'),
      _MetricTile(label: 'Average Score', value: '$averageScore%'),
      _MetricTile(label: 'Average Completion Rate', value: '$completionRate%'),
      _MetricTile(label: 'Pending Students', value: '$pending'),
      _MetricTile(label: 'Highest Score', value: '$highest%'),
      _MetricTile(label: 'Lowest Score', value: '$lowest%'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(metric.label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                  const SizedBox(height: 6),
                  Text(metric.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Score Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final value in [42, 58, 67, 83, 96])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: double.infinity,
                                height: (value / 100) * 112,
                                decoration: BoxDecoration(
                                  color: value >= 80
                                      ? const Color(0xFF5AB2FF)
                                      : value >= 60
                                          ? const Color(0xFF7CCB9E)
                                          : const Color(0xFFF7B267),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('$value%', style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.edit_note_rounded, size: 42, color: AppColors.topBar),
          const SizedBox(height: 12),
          const Text(
            'No Assessments Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an online assessment or quiz for this class.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _showCreateAssessmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.topBar,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _buildSummary() {
    final summary = {'total': 0, 'draft': 0, 'active': 0, 'completed': 0, 'upcoming': 0};
    for (final assessment in _assessments) {
      summary['total'] = summary['total']! + 1;
      switch (assessment.status) {
        case 'Draft':
          summary['draft'] = summary['draft']! + 1;
          break;
        case 'Active':
          summary['active'] = summary['active']! + 1;
          break;
        case 'Completed':
          summary['completed'] = summary['completed']! + 1;
          break;
        case 'Upcoming':
          summary['upcoming'] = summary['upcoming']! + 1;
          break;
      }
    }
    return summary;
  }

  bool _isThisWeek(String date) => date.contains('2026-09');

  bool _isThisMonth(String date) => date.contains('2026-09');

  Future<void> _showCreateAssessmentDialog() async {
    final result = await showDialog<Assessment>(
      context: context,
      builder: (_) => _CreateAssessmentDialog(initialAssessment: null),
    );

    if (result != null && mounted) {
      setState(() {
        _assessments.insert(0, result);
      });
    }
  }

  Future<void> _showAssessmentDetails(Assessment assessment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssessmentDetailSheet(
        assessment: assessment,
        onRefresh: () => setState(() {}),
        isViewOnly: widget.isViewOnly,
      ),
    );
  }

  static List<Assessment> _initialAssessments() {
    return [
      Assessment(
        id: 'a1',
        title: 'Mathematics Quiz',
        subject: 'Mathematics',
        topic: 'Quadratic Equations',
        description: 'Solve quadratic equations and interpret roots in real-life scenarios.',
        instructions: 'Attempt all questions. Show steps for long answers.',
        date: '2026-09-05',
        startTime: '09:00',
        endTime: '09:30',
        duration: '30 Minutes',
        status: 'Active',
        folder: 'Mathematics',
        totalQuestions: 20,
        totalMarks: 50,
        passingMarks: 25,
        numberOfStudents: 30,
        completedCount: 22,
        attempts: 2,
        questions: [
          AssessmentQuestion(
            id: 'q1',
            question: 'What is the value of x in x^2 - 9 = 0?',
            type: 'Multiple Choice',
            options: ['x=3', 'x=-3', 'x=±3', 'x=9'],
            correctAnswer: 'x=±3',
            marks: 2,
          ),
          AssessmentQuestion(
            id: 'q2',
            question: 'Solve 2x + 5 = 17.',
            type: 'Short Answer',
            options: [],
            correctAnswer: '6',
            marks: 2,
          ),
        ],
      ),
      Assessment(
        id: 'a2',
        title: 'Science Assessment',
        subject: 'Science',
        topic: 'Motion and Force',
        description: 'Assessment on motion, acceleration, and force.',
        instructions: 'Read each question carefully and answer in full sentences.',
        date: '2026-09-09',
        startTime: '11:00',
        endTime: '11:40',
        duration: '40 Minutes',
        status: 'Upcoming',
        folder: 'Science',
        totalQuestions: 25,
        totalMarks: 50,
        passingMarks: 20,
        numberOfStudents: 28,
        completedCount: 8,
        attempts: 1,
        questions: [
          AssessmentQuestion(
            id: 'q3',
            question: 'Which force opposes motion?',
            type: 'Multiple Choice',
            options: ['Gravity', 'Friction', 'Momentum', 'Acceleration'],
            correctAnswer: 'Friction',
            marks: 2,
          ),
        ],
      ),
      Assessment(
        id: 'a3',
        title: 'English Grammar Quiz',
        subject: 'English',
        topic: 'Parts of Speech',
        description: 'Grammar and sentence structure revision test.',
        instructions: 'Choose the best answer for each question.',
        date: '2026-08-28',
        startTime: '10:00',
        endTime: '10:20',
        duration: '20 Minutes',
        status: 'Completed',
        folder: 'English',
        totalQuestions: 15,
        totalMarks: 30,
        passingMarks: 15,
        numberOfStudents: 25,
        completedCount: 25,
        attempts: 1,
        questions: [
          AssessmentQuestion(
            id: 'q4',
            question: 'Identify the noun in the sentence: The cat sat on the mat.',
            type: 'Multiple Choice',
            options: ['sat', 'mat', 'cat', 'on'],
            correctAnswer: 'cat',
            marks: 2,
          ),
        ],
      ),
      Assessment(
        id: 'a4',
        title: 'History Revision Test',
        subject: 'History',
        topic: 'World War II',
        description: 'Revision test on key events and causes.',
        instructions: 'Use your study notes and answer all questions.',
        date: '2026-09-12',
        startTime: '14:00',
        endTime: '14:35',
        duration: '35 Minutes',
        status: 'Draft',
        folder: 'Unit Tests',
        totalQuestions: 18,
        totalMarks: 40,
        passingMarks: 20,
        numberOfStudents: 26,
        completedCount: 4,
        attempts: 1,
        questions: [],
      ),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.hintText)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(label),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Draft':
        return const Color(0xFFB7A6FF);
      case 'Active':
        return const Color(0xFF42B883);
      case 'Completed':
        return const Color(0xFF3B82F6);
      case 'Upcoming':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.topBar;
    }
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment, required this.onTap});

  final Assessment assessment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assessment.topic,
                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCardAction(context, value, assessment),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'view', child: Text('View Details')),
                    const PopupMenuItem(value: 'questions', child: Text('Manage Questions')),
                    const PopupMenuItem(value: 'results', child: Text('View Results')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  child: const Icon(Icons.more_vert_rounded, color: AppColors.secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${assessment.totalQuestions} Questions • ${assessment.totalMarks} Marks',
              style: const TextStyle(fontSize: 12, color: AppColors.primaryText),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 6),
                Text(assessment.duration, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.secondaryText),
                const SizedBox(width: 6),
                Text(_formatDate(assessment.date), style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${assessment.completedCount} / ${assessment.numberOfStudents} Completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(assessment.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(assessment.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assessment.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(assessment.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return const Color(0xFF8B5CF6);
      case 'Upcoming':
        return const Color(0xFFF59E0B);
      case 'Active':
        return const Color(0xFF22C55E);
      case 'Completed':
        return const Color(0xFF2563EB);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColors.topBar;
    }
  }

  void _handleCardAction(BuildContext context, String action, Assessment assessment) {
    final state = context.findAncestorStateOfType<_OnlineAssessmentPageState>();
    switch (action) {
      case 'view':
        state?._showAssessmentDetails(assessment);
        break;
      case 'questions':
        _openQuestionManager(context, assessment);
        break;
      case 'results':
        _showResultsSheet(context, assessment);
        break;
      case 'duplicate':
        state?._duplicateAssessmentLocally(assessment);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duplicated "${assessment.title}" locally.')),
          );
        }
        break;
      case 'delete':
        _confirmDelete(context, assessment);
        break;
    }
  }

  Future<void> _openQuestionManager(BuildContext context, Assessment assessment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionManagerSheet(assessment: assessment),
    );
  }

  Future<void> _showResultsSheet(BuildContext context, Assessment assessment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultsSheet(assessment: assessment),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Assessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: const Text('Are you sure you want to delete this assessment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final state = context.findAncestorStateOfType<_OnlineAssessmentPageState>();
      if (state != null) {
        state._deleteAssessmentLocally(assessment);
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment deleted locally.')),
        );
      }
    }
  }
}

class _AssessmentDetailSheet extends StatefulWidget {
  const _AssessmentDetailSheet({required this.assessment, required this.onRefresh, this.isViewOnly = false});

  final Assessment assessment;
  final VoidCallback onRefresh;
  final bool isViewOnly;

  @override
  State<_AssessmentDetailSheet> createState() => _AssessmentDetailSheetState();
}

class _AssessmentDetailSheetState extends State<_AssessmentDetailSheet> {
  bool _showQuestionManager = false;

  @override
  Widget build(BuildContext context) {
    final assessment = widget.assessment;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assessment.subject,
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_showQuestionManager) ...[
                Row(
                  children: [
                    if (!widget.isViewOnly) _ActionChip(label: 'Edit', icon: Icons.edit_rounded, onTap: () => _editAssessment(context, assessment)),
                    const SizedBox(width: 8),
                    _ActionChip(label: 'View Questions', icon: Icons.quiz_rounded, onTap: () => setState(() => _showQuestionManager = true)),
                    const SizedBox(width: 8),
                    _ActionChip(label: 'View Results', icon: Icons.bar_chart_rounded, onTap: () => _openResultsSheet(context, assessment)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!widget.isViewOnly) _ActionChip(label: 'Duplicate', icon: Icons.copy_rounded, onTap: () => _duplicateAssessment(context, assessment)),
                    if (!widget.isViewOnly) _ActionChip(label: 'Delete', icon: Icons.delete_outline_rounded, onTap: () => _deleteAssessment(context, assessment)),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailBlock(title: 'Description', value: assessment.description),
                _DetailBlock(title: 'Instructions', value: assessment.instructions),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    _InfoTile(label: 'Date', value: _formatDate(assessment.date)),
                    _InfoTile(label: 'Start', value: assessment.startTime),
                    _InfoTile(label: 'End', value: assessment.endTime),
                    _InfoTile(label: 'Duration', value: assessment.duration),
                    _InfoTile(label: 'Questions', value: '${assessment.totalQuestions}'),
                    _InfoTile(label: 'Marks', value: '${assessment.totalMarks}'),
                    _InfoTile(label: 'Passing', value: '${assessment.passingMarks}'),
                    _InfoTile(label: 'Students', value: '${assessment.numberOfStudents}'),
                    _InfoTile(label: 'Completion', value: '${assessment.completedCount}'),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Attached Resources', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _ResourceChip(label: 'Worksheet.pdf'),
                    _ResourceChip(label: 'Formula Sheet'),
                    _ResourceChip(label: 'Answer Key'),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Manage Questions',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addQuestion(context, assessment),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (assessment.questions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No questions yet. Add your first question to this assessment.'),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = assessment.questions.removeAt(oldIndex);
                        assessment.questions.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int index = 0; index < assessment.questions.length; index++)
                        _QuestionEntryCard(
                          key: ValueKey(assessment.questions[index].id),
                          number: index + 1,
                          question: assessment.questions[index],
                          onEdit: () => _editQuestion(context, assessment, assessment.questions[index]),
                          onDelete: () => _deleteQuestion(context, assessment, assessment.questions[index]),
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: () => setState(() => _showQuestionManager = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Details'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openResultsSheet(BuildContext context, Assessment assessment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultsSheet(assessment: assessment),
    );
  }

  void _editAssessment(BuildContext context, Assessment assessment) {
    showDialog<Assessment>(
      context: context,
      builder: (_) => _CreateAssessmentDialog(initialAssessment: assessment),
    ).then((value) {
      if (value != null) {
        // ignore: use_build_context_synchronously
        final state = context.findAncestorStateOfType<_OnlineAssessmentPageState>();
        if (state != null) {
          final index = state._assessments.indexWhere((item) => item.id == assessment.id);
          if (index >= 0) {
            state._assessments[index] = value;
            state.setState(() {});
          }
        }
      }
    });
  }

  void _duplicateAssessment(BuildContext context, Assessment assessment) {
    // ignore: use_build_context_synchronously
    final state = context.findAncestorStateOfType<_OnlineAssessmentPageState>();
    if (state != null) {
      state._duplicateAssessmentLocally(assessment);
    }
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${assessment.title} (Copy)"')),
      );
    }
  }

  void _deleteAssessment(BuildContext context, Assessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: const Text('Are you sure you want to delete this assessment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final state = context.findAncestorStateOfType<_OnlineAssessmentPageState>();
      if (state != null) {
        state._deleteAssessmentLocally(assessment);
      }
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      }
    }
  }

  void _addQuestion(BuildContext context, Assessment assessment) {
    showDialog<void>(
      context: context,
      builder: (_) => _QuestionFormDialog(assessment: assessment),
    ).then((_) {
      if (context.mounted) {
        setState(() {});
      }
      widget.onRefresh();
    });
  }

  void _editQuestion(BuildContext context, Assessment assessment, AssessmentQuestion question) {
    showDialog<void>(
      context: context,
      builder: (_) => _QuestionFormDialog(assessment: assessment, editingQuestion: question),
    ).then((_) {
      setState(() {});
      widget.onRefresh();
    });
  }

  void _deleteQuestion(BuildContext context, Assessment assessment, AssessmentQuestion question) {
    final index = assessment.questions.indexWhere((item) => item.id == question.id);
    if (index >= 0) {
      assessment.questions.removeAt(index);
      setState(() {});
      widget.onRefresh();
    }
  }
}

class _QuestionEntryCard extends StatelessWidget {
  const _QuestionEntryCard({
    super.key,
    required this.number,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final int number;
  final AssessmentQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.topBar,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Question $number', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              const Icon(Icons.drag_indicator_rounded, color: AppColors.secondaryText),
            ],
          ),
          const SizedBox(height: 14),
          Text(question.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Type: ${question.type}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              const SizedBox(width: 16),
              Text('Marks: ${question.marks}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Edit')),
              const SizedBox(width: 8),
              TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 16), label: const Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.assessment, this.editingQuestion});

  final Assessment assessment;
  final AssessmentQuestion? editingQuestion;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _optionAController;
  late final TextEditingController _optionBController;
  late final TextEditingController _optionCController;
  late final TextEditingController _optionDController;
  late final TextEditingController _correctAnswerController;
  late final TextEditingController _marksController;
  String _type = 'Multiple Choice';

  @override
  void initState() {
    super.initState();
    final question = widget.editingQuestion;
    _questionController = TextEditingController(text: question?.question ?? '');
    _optionAController = TextEditingController(text: question?.options.elementAtOrNull(0) ?? '');
    _optionBController = TextEditingController(text: question?.options.elementAtOrNull(1) ?? '');
    _optionCController = TextEditingController(text: question?.options.elementAtOrNull(2) ?? '');
    _optionDController = TextEditingController(text: question?.options.elementAtOrNull(3) ?? '');
    _correctAnswerController = TextEditingController(text: question?.correctAnswer ?? '');
    _marksController = TextEditingController(text: question?.marks.toString() ?? '2');
    _type = question?.type ?? 'Multiple Choice';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _correctAnswerController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionTypes = ['Multiple Choice', 'Multiple Select', 'True / False', 'Short Answer', 'Long Answer'];
    final isChoiceType = _type == 'Multiple Choice' || _type == 'Multiple Select' || _type == 'True / False';

    return AlertDialog(
      title: Text(widget.editingQuestion == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: questionTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _type = value ?? 'Multiple Choice'),
                decoration: const InputDecoration(labelText: 'Question Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _questionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              if (isChoiceType) ...[
                const SizedBox(height: 12),
                TextFormField(controller: _optionAController, decoration: const InputDecoration(labelText: 'Option A')),
                const SizedBox(height: 8),
                TextFormField(controller: _optionBController, decoration: const InputDecoration(labelText: 'Option B')),
                const SizedBox(height: 8),
                TextFormField(controller: _optionCController, decoration: const InputDecoration(labelText: 'Option C')),
                const SizedBox(height: 8),
                TextFormField(controller: _optionDController, decoration: const InputDecoration(labelText: 'Option D')),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _correctAnswerController,
                decoration: const InputDecoration(labelText: 'Correct Answer'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _marksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Marks'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final questionText = _questionController.text.trim();
            final marks = int.tryParse(_marksController.text.trim()) ?? 1;
            if (questionText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question text is required.')),
              );
              return;
            }

            final options = [
              _optionAController.text.trim(),
              _optionBController.text.trim(),
              _optionCController.text.trim(),
              _optionDController.text.trim(),
            ].where((value) => value.isNotEmpty).toList();

            final item = AssessmentQuestion(
              id: widget.editingQuestion?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: questionText,
              type: _type,
              options: options,
              correctAnswer: _correctAnswerController.text.trim(),
              marks: marks,
            );

            final index = widget.assessment.questions.indexWhere((entry) => entry.id == widget.editingQuestion?.id);
            if (widget.editingQuestion != null && index >= 0) {
              widget.assessment.questions[index] = item;
            } else {
              widget.assessment.questions.add(item);
            }
            widget.assessment.copyWith(questions: widget.assessment.questions);
            Navigator.pop(context);
          },
          child: const Text('Save Question'),
        ),
      ],
    );
  }
}

class _CreateAssessmentDialog extends StatefulWidget {
  const _CreateAssessmentDialog({required this.initialAssessment});

  final Assessment? initialAssessment;

  @override
  State<_CreateAssessmentDialog> createState() => _CreateAssessmentDialogState();
}

class _CreateAssessmentDialogState extends State<_CreateAssessmentDialog> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _attemptsController = TextEditingController();
  String _status = 'Draft';

  @override
  void initState() {
    super.initState();
    final assessment = widget.initialAssessment;
    if (assessment != null) {
      _titleController.text = assessment.title;
      _subjectController.text = assessment.subject;
      _topicController.text = assessment.topic;
      _descriptionController.text = assessment.description;
      _instructionsController.text = assessment.instructions;
      _dateController.text = assessment.date;
      _startTimeController.text = assessment.startTime;
      _endTimeController.text = assessment.endTime;
      _durationController.text = assessment.duration;
      _marksController.text = assessment.totalMarks.toString();
      _passingMarksController.text = assessment.passingMarks.toString();
      _attemptsController.text = assessment.attempts.toString();
      _status = assessment.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    _passingMarksController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SizedBox(
          height: 740,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                color: AppColors.topBar,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initialAssessment == null ? 'Create Assessment' : 'Edit Assessment',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _TextField(label: 'Assessment title', controller: _titleController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TextField(label: 'Subject', controller: _subjectController)),
                          const SizedBox(width: 12),
                          Expanded(child: _TextField(label: 'Topic', controller: _topicController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TextField(label: 'Description', controller: _descriptionController, minLines: 2),
                      const SizedBox(height: 12),
                      _TextField(label: 'Instructions', controller: _instructionsController, minLines: 2),
                      const SizedBox(height: 18),
                      const Text('Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TextField(label: 'Date', controller: _dateController)),
                          const SizedBox(width: 12),
                          Expanded(child: _TextField(label: 'Start time', controller: _startTimeController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TextField(label: 'End time', controller: _endTimeController)),
                          const SizedBox(width: 12),
                          Expanded(child: _TextField(label: 'Duration', controller: _durationController)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Assessment Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TextField(label: 'Total marks', controller: _marksController, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _TextField(label: 'Passing marks', controller: _passingMarksController, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _TextField(label: 'Number of attempts', controller: _attemptsController, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: ['Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled']
                                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                                  .toList(),
                              onChanged: (value) => setState(() => _status = value ?? 'Draft'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveAssessment,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.topBar),
                        child: const Text('Save Assessment'),
                      ),
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

  void _saveAssessment() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment title is required.')));
      return;
    }

    final totalMarks = int.tryParse(_marksController.text.trim()) ?? 0;
    final passingMarks = int.tryParse(_passingMarksController.text.trim()) ?? 0;
    final attempts = int.tryParse(_attemptsController.text.trim()) ?? 1;
    final baseAssessment = widget.initialAssessment ?? Assessment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subject: _subjectController.text.trim().isEmpty ? 'General' : _subjectController.text.trim(),
      topic: _topicController.text.trim().isEmpty ? 'General Topic' : _topicController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? 'Assessment description' : _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty ? 'Follow all instructions carefully.' : _instructionsController.text.trim(),
      date: _dateController.text.trim().isEmpty ? '2026-09-15' : _dateController.text.trim(),
      startTime: _startTimeController.text.trim().isEmpty ? '09:00' : _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim().isEmpty ? '09:30' : _endTimeController.text.trim(),
      duration: _durationController.text.trim().isEmpty ? '30 Minutes' : _durationController.text.trim(),
      status: _status,
      folder: 'Mathematics',
      totalQuestions: 10,
      totalMarks: totalMarks,
      passingMarks: passingMarks,
      numberOfStudents: 30,
      completedCount: 0,
      attempts: attempts,
      questions: [],
    );

    final assessment = baseAssessment.copyWith(
      title: title,
      subject: _subjectController.text.trim().isEmpty ? baseAssessment.subject : _subjectController.text.trim(),
      topic: _topicController.text.trim().isEmpty ? baseAssessment.topic : _topicController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? baseAssessment.description : _descriptionController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty ? baseAssessment.instructions : _instructionsController.text.trim(),
      date: _dateController.text.trim().isEmpty ? baseAssessment.date : _dateController.text.trim(),
      startTime: _startTimeController.text.trim().isEmpty ? baseAssessment.startTime : _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim().isEmpty ? baseAssessment.endTime : _endTimeController.text.trim(),
      duration: _durationController.text.trim().isEmpty ? baseAssessment.duration : _durationController.text.trim(),
      totalMarks: totalMarks == 0 ? baseAssessment.totalMarks : totalMarks,
      passingMarks: passingMarks == 0 ? baseAssessment.passingMarks : passingMarks,
      attempts: attempts == 0 ? baseAssessment.attempts : attempts,
      status: _status,
    );

    Navigator.pop(context, assessment);
  }
}

class _ResultsSheet extends StatelessWidget {
  const _ResultsSheet({required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final students = [
      const StudentResult(name: 'Ava Patel', status: 'Completed', score: 92, percentage: 92, submittedDate: '2026-09-05'),
      const StudentResult(name: 'Noah Johnson', status: 'Completed', score: 84, percentage: 84, submittedDate: '2026-09-05'),
      const StudentResult(name: 'Mila Chen', status: 'Pending', score: 0, percentage: 0, submittedDate: 'Pending'),
      const StudentResult(name: 'Isaac Lee', status: 'Not Started', score: 0, percentage: 0, submittedDate: 'Not Started'),
      const StudentResult(name: 'Emma White', status: 'Late', score: 76, percentage: 76, submittedDate: '2026-09-06'),
    ];

    final average = students.where((student) => student.status == 'Completed' || student.status == 'Late').fold<int>(0, (sum, student) => sum + student.score) /
        (students.where((student) => student.status == 'Completed' || student.status == 'Late').isEmpty ? 1 : students.where((student) => student.status == 'Completed' || student.status == 'Late').length);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'View Results',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 18),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                children: [
                  _MetricTile(label: '30 Students', value: '30'),
                  _MetricTile(label: '24 Completed', value: '24'),
                  _MetricTile(label: '4 Pending', value: '4'),
                  _MetricTile(label: '2 Not Started', value: '2'),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Average Score', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                        Text('${average.round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final value in [42, 58, 72, 88, 96])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                height: (value / 100) * 90,
                                decoration: BoxDecoration(
                                  color: value >= 80 ? const Color(0xFF60A5FA) : const Color(0xFFC7D2FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Student Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              const SizedBox(height: 10),
              ...students.map(
                (student) => ListTile(
                  onTap: () => _showStudentDetail(context, student),
                  title: Text(student.name),
                  subtitle: Text(student.status),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${student.score} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${student.percentage}%', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStudentDetail(BuildContext context, StudentResult student) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${student.status}'),
            const SizedBox(height: 8),
            Text('Score: ${student.score}'),
            const SizedBox(height: 8),
            Text('Percentage: ${student.percentage}%'),
            const SizedBox(height: 8),
            Text('Submitted: ${student.submittedDate}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _QuestionManagerSheet extends StatelessWidget {
  const _QuestionManagerSheet({required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Manage Questions', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              Text(assessment.title, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText)),
              const SizedBox(height: 16),
              Expanded(
                child: assessment.questions.isEmpty
                    ? const Center(
                        child: Text('No questions added yet. Add a question to get started.'),
                      )
                    : ReorderableListView(
                        buildDefaultDragHandles: true,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = assessment.questions.removeAt(oldIndex);
                          assessment.questions.insert(newIndex, item);
                        },
                        children: [
                          for (int index = 0; index < assessment.questions.length; index++)
                            Container(
                              key: ValueKey(assessment.questions[index].id),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Question ${index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                  const SizedBox(height: 6),
                                  Text(assessment.questions[index].question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Type: ${assessment.questions[index].type}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                      const SizedBox(width: 12),
                                      Text('Marks: ${assessment.questions[index].marks}', style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => _QuestionFormDialog(assessment: assessment),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Question'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.topBar),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.topBar),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.topBar)),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.45)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.topBar, fontWeight: FontWeight.w600)),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE6EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          style: const TextStyle(fontSize: 12, color: AppColors.primaryText),
          hint: Text(label),
          items: items
              .map((option) => DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.minLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int minLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines > 1 ? 6 : 1,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD9E2EC)),
        ),
      ),
    );
  }
}

String _formatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${_monthName(date.month)} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

extension on List<String> {
  String elementAtOrNull(int index) => index >= 0 && index < length ? this[index] : '';
}
