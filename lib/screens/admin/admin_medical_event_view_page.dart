import 'package:flutter/material.dart';

import '../../models/medical_event.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminMedicalEventViewPage extends StatelessWidget {
  const AdminMedicalEventViewPage({super.key, required this.event});

  final MedicalEvent? event;

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(
        appBar: _appBar(context),
        body: const Center(child: Text('Medical event details unavailable.')),
        bottomNavigationBar: _bottomNavigationBar(context),
      );
    }

    final item = event!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _InfoSection(
            title: 'Medical Event Display - Details of a Medical Event',
            children: [
              _detail('Student', '${item.studentName} (${item.studentId})'),
              _detail('Class', item.className),
              _detail('Last modified by', item.lastModifiedByLabel),
            ],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Description',
            children: [_bodyText(item.description)],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'First Observations',
            children: [
              _detail('Symptom Reported', item.symptomReported),
              _detail('Special Needs Known', item.specialNeedsKnown.isEmpty ? 'None recorded' : item.specialNeedsKnown),
            ],
          ),
          if (item.reportImage.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoSection(
              title: 'Medical Report',
              children: [
                GestureDetector(
                  onTap: () => _showImage(context, item.reportImage),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.reportImage,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Unable to load medical report image.'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Report Information',
            children: [
              _detail('Reported by', item.reportedByLabel),
              _detail('Reported Date', _formatDate(item.createdAt)),
              _detail('Last Modified', _formatDate(item.lastModifiedAt ?? item.updatedAt)),
              _detail('Released to Parent', 'Not recorded'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavigationBar(context),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Medical Event Details'),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      );

  Widget _bottomNavigationBar(BuildContext context) => AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      );

  void _showImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '$label:\n${value.isEmpty ? 'Not available' : value}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
        ),
      );

  Widget _bodyText(String value) => Text(
        value.isEmpty ? 'Not available' : value,
        style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF374151)),
      );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDFE7F1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ...children,
          ],
        ),
      );
}

String _formatDate(DateTime? date) => date == null ? 'Not available' : '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
