import 'package:flutter/material.dart';

import '../../models/staff_handbook.dart';
import '../../services/staff_handbook_service.dart';
import '../../widgets/staff_footer.dart';

class StaffHandbookPage extends StatefulWidget {
  const StaffHandbookPage({super.key});
  @override
  State<StaffHandbookPage> createState() => _StaffHandbookPageState();
}

class _StaffHandbookPageState extends State<StaffHandbookPage> {
  final _service = StaffHandbookService();
  late Future<StaffHandbook> _future;
  @override
  void initState() {
    super.initState();
    _future = _service.getHandbook();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StaffHandbook>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const _HandbookScaffold(
          title: 'Staff/Employee Handbook & Information',
          child: Center(child: CircularProgressIndicator()),
        );
      if (snapshot.hasError)
        return _HandbookScaffold(
          title: 'Staff/Employee Handbook & Information',
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Unable to load the Staff Handbook.'),
            ),
          ),
        );
      final handbook = snapshot.data!;
      return _HandbookScaffold(
        title: 'Staff/Employee Handbook & Information',
        child: GridView.count(
          padding: const EdgeInsets.fromLTRB(2, 5, 2, 8),
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: .78,
          children: [
            _HandbookCard(
              title: handbook.sections.isEmpty
                  ? 'Staff Handbook'
                  : handbook.sections.first.heading,
              summary: 'Important information and policies for staff.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HandbookDetailPage(handbook: handbook),
                ),
              ),
            ),
            const _HandbookCard(
              title: 'Employee Bulletin Board',
              summary: 'Notices and updates for every employee.',
            ),
            const _HandbookCard(
              title: 'Teaching Standards',
              summary: 'Guidance for classroom planning and conduct.',
            ),
            const _HandbookCard(
              title: 'School Procedures',
              summary: 'Standard operating procedures and forms.',
            ),
          ],
        ),
      );
    },
  );
}

class HandbookDetailPage extends StatelessWidget {
  const HandbookDetailPage({super.key, required this.handbook});
  final StaffHandbook handbook;
  @override
  Widget build(BuildContext context) => _HandbookScaffold(
    title: handbook.sections.isEmpty
        ? 'Staff Handbook'
        : handbook.sections.first.heading,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HandbookIllustration(height: 185),
          if (handbook.sections.isNotEmpty &&
              handbook.sections.first.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Image.network(
                handbook.sections.first.imageUrl,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            handbook.sections.isEmpty ||
                    handbook.sections.first.subSections.isEmpty
                ? 'Staff Handbook'
                : handbook.sections.first.heading,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          const Text(
            'Important information and policies for staff.',
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 14),
          Text(
            handbook.sections.isEmpty ||
                    handbook.sections.first.subSections.isEmpty
                ? 'Create handbook sections from the admin page.'
                : handbook.sections.first.subSections.first.content,
            style: const TextStyle(fontSize: 12, height: 1.45),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HandbookReadingPage(handbook: handbook),
              ),
            ),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('Read handbook'),
          ),
        ],
      ),
    ),
  );
}

class HandbookReadingPage extends StatelessWidget {
  const HandbookReadingPage({super.key, required this.handbook});
  final StaffHandbook handbook;
  @override
  Widget build(BuildContext context) => _HandbookScaffold(
    title: handbook.sections.isEmpty
        ? 'Staff Handbook'
        : handbook.sections.first.heading,
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          handbook.sections.isEmpty
              ? 'Staff Handbook'
              : handbook.sections.first.heading,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        const Text(
          'Important information and policies for staff.',
          style: TextStyle(fontSize: 12),
        ),
        const Divider(height: 24),
        const Text(
          'Overview',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        Text(
          handbook.sections.isEmpty
              ? 'Create handbook sections from the admin page.'
              : handbook.sections.first.subSections.first.content,
          style: const TextStyle(fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 18),
        ...handbook.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.imageUrl.isNotEmpty)
                  Image.network(
                    section.imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                Text(
                  section.heading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  section.subSections
                      .map((sub) => '${sub.subHeading}\n${sub.content}')
                      .join('\n\n'),
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HandbookDocumentPage(handbook: handbook),
            ),
          ),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: const Text('Open document'),
        ),
      ],
    ),
  );
}

class HandbookDocumentPage extends StatelessWidget {
  const HandbookDocumentPage({super.key, required this.handbook});
  final StaffHandbook handbook;
  @override
  Widget build(BuildContext context) => _HandbookScaffold(
    title: 'Document Preview',
    child: Column(
      children: [
        Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffdddddd))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Staff Handbook',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Icon(Icons.download_outlined, size: 17),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            color: const Color(0xfff7f7f7),
            child: ListView(
              children: [
                const Text(
                  'SAMUNI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 22),
                Text(
                  handbook.sections.isEmpty
                      ? 'Staff Handbook'
                      : handbook.sections.first.heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Important information and policies for staff.',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Contents',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...handbook.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${section.heading}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const Divider(height: 24),
                ...handbook.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.subSections
                              .map((sub) => '${sub.subHeading}\n${sub.content}')
                              .join('\n\n'),
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HandbookCard extends StatelessWidget {
  const _HandbookCard({required this.title, required this.summary, this.onTap});
  final String title;
  final String summary;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5d5d5)),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          const Expanded(child: _HandbookIllustration()),
          const SizedBox(height: 6),
          Text(
            summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Read more...', style: TextStyle(fontSize: 9)),
          ),
        ],
      ),
    ),
  );
}

class _HandbookIllustration extends StatelessWidget {
  const _HandbookIllustration({this.height});
  final double? height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: const Color(0xffdbe7ed),
    child: const Center(
      child: Icon(Icons.menu_book_outlined, size: 64, color: Color(0xff315c75)),
    ),
  );
}

class _HandbookScaffold extends StatelessWidget {
  const _HandbookScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      toolbarHeight: 39,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
      title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text(title, style: const TextStyle(fontSize: 11)),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    ),
    bottomNavigationBar: const StaffFooter(),
  );
}
