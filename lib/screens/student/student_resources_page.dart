import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentResourcesPage extends StatefulWidget {
  const StudentResourcesPage({super.key});

  @override
  State<StudentResourcesPage> createState() => _StudentResourcesPageState();
}

class _StudentResourcesPageState extends State<StudentResourcesPage> {
  static const _resources = [
    ['GRADE 6 INDEPENDENCE DAY COMPETITION 2022', '22-Aug-22'],
    ['ACKNOWLEDGEMENT FORM', '11-Mar-23'],
    ['CBSE - CLASS GROUP PHOTO', '24-Mar-23'],
    ['ANNUAL DAY - INDIVIDUAL PHOTO', '08-Mar-23'],
    ['CHOICE FORM 2023-24', '25-Mar-23'],
    ['SCHOOL APP USERNAME AND PASSWORD', '24-Apr-23'],
    ["Mathbuddy username and password - 2023 - 24", '10-May-23'],
    ['CS - UOLO CREDENTIALS (2023-24)', '20-May-23'],
    ['SCHOOL SUPPLIES CHECK LIST (2023-24)', '07-Jun-23'],
    ['SCHOOL APP ACKNOWLEDGEMENT FORM (2023-24)', '09-Jun-23'],
    ['ID COMPETITION - DOODLE MY FACE (2023-24)', '12-Aug-23'],
  ];

  void _openInsert() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StudentResourceInsertPage()),
    );
  }

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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 31,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'Resource List',
                    style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                  ),
                ),
                TextButton(
                  onPressed: _openInsert,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 9, color: Color(0xff1d3557)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffd8d8d8)),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _resources.length,
              itemBuilder: (_, index) => _ResourceRow(resource: _resources[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.resource});

  final List<String> resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource[0],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff173c70),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            resource[1],
            style: const TextStyle(fontSize: 7, color: Color(0xff555555)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ResourceAction(icon: Icons.visibility_outlined),
              _ResourceAction(icon: Icons.info_outline),
              _ResourceAction(icon: Icons.delete_outline),
              _ResourceAction(icon: Icons.edit_outlined),
              _ResourceAction(icon: Icons.download_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Icon(icon, size: 12, color: const Color(0xff777777)),
    );
  }
}

class StudentResourceInsertPage extends StatefulWidget {
  const StudentResourceInsertPage({super.key});

  @override
  State<StudentResourceInsertPage> createState() => _StudentResourceInsertPageState();
}

class _StudentResourceInsertPageState extends State<StudentResourceInsertPage> {
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
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resource Insert (Student)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1d3557),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Short Description',
              style: TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _shortDescription,
              style: const TextStyle(fontSize: 10),
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Detailed Description',
              style: TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 5),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xfff9f9f9),
                border: Border.all(color: const Color(0xffd8d8d8)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '',
                  style: TextStyle(fontSize: 10, color: Color(0xff555555)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can paste a link or load a resource',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste a Link',
              style: TextStyle(fontSize: 9, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: _link,
              style: const TextStyle(fontSize: 10),
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Attachment',
              style: TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 5),
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xffe9ecef),
                border: Border.all(color: const Color(0xffd8d8d8)),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 8),
              child: const Text(
                'Click to upload',
                style: TextStyle(fontSize: 10, color: Color(0xff555555)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  InputDecoration _fieldDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xffd8d8d8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xffd8d8d8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xff4aa3ff)),
        ),
      );
}
