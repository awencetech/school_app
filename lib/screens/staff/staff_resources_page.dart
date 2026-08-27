import 'package:flutter/material.dart';

import '../../widgets/staff_footer.dart';

class StaffResourcesPage extends StatefulWidget {
  const StaffResourcesPage({super.key});

  @override
  State<StaffResourcesPage> createState() => _StaffResourcesPageState();
}

class _StaffResourcesPageState extends State<StaffResourcesPage> {
  static const _resources = [
    ['Sep\'24', '01-Oct-24'],
    ['Salary Jun-2024', '03-Jul-24'],
    ['may\'24', '01-Jun-24'],
    ['Salary Slip April-24', '02-May-24'],
    ['Salary Slip Mar-24', '31-Mar-24'],
    ['Salary Slip Feb-24', '01-Mar-24'],
    ['Salary Slip Dec\'23', '30-Dec-23'],
    ['Salary Slip Oct\'23', '01-Nov-23'],
    ['Salary Slip Sep\'23', '30-Sep-23'],
    ['Salary Slip Aug\'23', '31-Aug-23'],
    ['Salary Slip July - 23', '01-Aug-23'],
    ['Salary Slip Jun\'23', '30-Jun-23'],
  ];

  void _openInsert() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ResourceInsertPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _ResourcesAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 31,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Resource List', style: TextStyle(fontSize: 11)),
                ),
                TextButton(
                  onPressed: _openInsert,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _resources.length,
              itemBuilder: (_, index) =>
                  _ResourceRow(resource: _resources[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(currentIndex: 0),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.resource});

  final List<String> resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.fromLTRB(2, 5, 4, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resource[0],
            style: const TextStyle(fontSize: 10, color: Color(0xff173c70)),
          ),
          Text(
            resource[1],
            style: const TextStyle(fontSize: 6, color: Color(0xff555555)),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ResourceIcon(Icons.visibility_outlined),
              _ResourceIcon(Icons.info_outline),
              _ResourceIcon(Icons.delete_outline),
              _ResourceIcon(Icons.edit_outlined),
              _ResourceIcon(Icons.download_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceIcon extends StatelessWidget {
  const _ResourceIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 13),
    child: Icon(icon, size: 12, color: const Color(0xff777777)),
  );
}

class ResourceInsertPage extends StatefulWidget {
  const ResourceInsertPage({super.key});

  @override
  State<ResourceInsertPage> createState() => _ResourceInsertPageState();
}

class _ResourceInsertPageState extends State<ResourceInsertPage> {
  final _shortDescription = TextEditingController();
  final _link = TextEditingController();

  @override
  void dispose() {
    _shortDescription.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _ResourcesAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 5, 23, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Resource Insert (Staff)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text('Short Description', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            TextField(
              controller: _shortDescription,
              style: const TextStyle(fontSize: 10),
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 13),
            const Text('Detailed Description', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            _EditorBox(),
            const SizedBox(height: 12),
            const Text(
              'You can paste a link or load a resource',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const Text('Paste a Link', style: TextStyle(fontSize: 9)),
            const SizedBox(height: 5),
            TextField(
              controller: _link,
              style: const TextStyle(fontSize: 10),
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 13),
            const Text('Attachment', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 26,
                    color: const Color(0xffe9ecef),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 7),
                    child: const Text(
                      'Click to upload',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.upload, size: 15),
                const SizedBox(width: 4),
                const Text('Upload', style: TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff087ff5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(35, 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text('Update', style: TextStyle(fontSize: 8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration() => const InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
  border: OutlineInputBorder(),
);

class _EditorBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const buttons = ['B', 'I', 'U', 'S', 'X', 'X₂', '14-'];
    return Container(
      height: 365,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffcfcfcf)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            children: buttons
                .map(
                  (button) => Container(
                    width: button == '14-' ? 38 : 28,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xffdddddd)),
                        bottom: BorderSide(color: Color(0xffdddddd)),
                      ),
                    ),
                    child: Text(
                      button,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _ResourcesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ResourcesAppBar();

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 39,
    elevation: 0,
    leading: IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back, size: 20),
    ),
    title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
  );

  @override
  Size get preferredSize => const Size.fromHeight(39);
}
