import 'package:flutter/material.dart';

import '../../widgets/staff_footer.dart';

class StaffHandbookPage extends StatelessWidget {
  const StaffHandbookPage({super.key});

  static const _items = [
    ('Staff Handbook', 'Important information and policies for staff.'),
    ('Employee Bulletin Board', 'Notices and updates for every employee.'),
    ('Teaching Standards', 'Guidance for classroom planning and conduct.'),
    ('School Procedures', 'Standard operating procedures and forms.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _HandbookScaffold(
      title: 'Staff/Employee Handbook & Information',
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(2, 5, 2, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: .78,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) => _HandbookCard(
          title: _items[index].$1,
          summary: _items[index].$2,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HandbookDetailPage(item: _items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class HandbookDetailPage extends StatelessWidget {
  const HandbookDetailPage({super.key, required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) {
    return _HandbookScaffold(
      title: item.$1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HandbookIllustration(height: 185),
            const SizedBox(height: 12),
            Text(
              item.$1,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(item.$2, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HandbookReadingPage(item: item),
                  ),
                ),
                child: const Text(
                  'Read more...',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HandbookReadingPage extends StatelessWidget {
  const HandbookReadingPage({super.key, required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) {
    return _HandbookScaffold(
      title: item.$1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
        children: [
          Text(
            item.$1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text(
            'Staff Information',
            style: TextStyle(fontSize: 11, color: Color(0xff555555)),
          ),
          const Divider(height: 24),
          Text(item.$2, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          const Text(
            'Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          const Text(
            'This handbook contains the information, expectations, and procedures that support staff in their day-to-day work. Please read each section carefully and contact the school office when clarification is needed.',
            style: TextStyle(fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HandbookDocumentPage(item: item),
              ),
            ),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Open document', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class HandbookDocumentPage extends StatelessWidget {
  const HandbookDocumentPage({super.key, required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) {
    return _HandbookScaffold(
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
                  child: Text(item.$1, style: const TextStyle(fontSize: 12)),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Download',
                  icon: const Icon(Icons.download_outlined, size: 17),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              color: const Color(0xfff7f7f7),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'SAMUNI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      item.$2,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final section in [
                      'Introduction',
                      'Responsibilities',
                      'School procedures',
                      'Useful contacts',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• $section',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandbookCard extends StatelessWidget {
  const _HandbookCard({
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
