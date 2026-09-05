import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/staff_footer.dart';

class StaffTodoTasksPage extends StatefulWidget {
  const StaffTodoTasksPage({super.key});

  @override
  State<StaffTodoTasksPage> createState() => _StaffTodoTasksPageState();
}

class _StaffTodoTasksPageState extends State<StaffTodoTasksPage> {
  bool _showTask = false;
  bool _active = true;

  void _openCreate() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TodoCreatePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 39,
        elevation: 0,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Text('To Do list', style: TextStyle(fontSize: 11)),
                ),
                TextButton(
                  onPressed: _openCreate,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 7, 0, 7),
            child: Row(
              children: [
                _SmallButton(label: 'Sort by Date', onTap: () {}),
                const SizedBox(width: 10),
                _SmallButton(label: 'Sort by Priority', onTap: () {}),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 31,
            child: Row(
              children: [
                _Tab(
                  label: 'Active',
                  selected: _active,
                  onTap: () => setState(() {
                    _active = true;
                    _showTask = true;
                  }),
                ),
                _Tab(
                  label: 'Closed',
                  selected: !_active,
                  onTap: () => setState(() => _active = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_showTask && _active)
            const _TaskCard()
          else
            const Expanded(
              child: Center(
                child: Text(
                  'No Data available',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xff008dcc),
      side: const BorderSide(color: Color(0xff00a4d6)),
      minimumSize: const Size(50, 17),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 7)),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: 51,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xfff8f8f8),
        border: Border.all(color: const Color(0xffe0e0e0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: selected ? const Color(0xff0071c8) : Colors.black87,
        ),
      ),
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
    padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffe1e1e1)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Testing  ', style: TextStyle(fontSize: 11)),
              WidgetSpan(
                child: ColoredBox(
                  color: Color(0xffffd56b),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    child: Text(
                      'Medium Priority',
                      style: TextStyle(fontSize: 7),
                    ),
                  ),
                ),
              ),
              TextSpan(
                text: '  to be done by 20-Aug-24',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Responsible: ',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: 'DURAI TAMILAN(SAMNTSMS048)  Team: ',
                style: TextStyle(fontSize: 9),
              ),
              TextSpan(
                text: 'Muthumanikandan(SAMNTSEN243)  Informed: ',
                style: TextStyle(fontSize: 9),
              ),
              TextSpan(
                text: 'Vijay Manikandan(SAMNCTS0562)',
                style: TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        Text(
          'Status: Completed',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
        Text('ⓘ Info', style: TextStyle(fontSize: 9, color: Color(0xff888888))),
      ],
    ),
  );
}

class TodoCreatePage extends StatefulWidget {
  const TodoCreatePage({super.key});

  @override
  State<TodoCreatePage> createState() => _TodoCreatePageState();
}

class _TodoCreatePageState extends State<TodoCreatePage> {
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _responsible = TextEditingController();
  final _team = TextEditingController();
  final _informed = TextEditingController();
  String _priority = 'Medium';

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _responsible.dispose();
    _team.dispose();
    _informed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 39,
        elevation: 0,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(11, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('To Do - Create', style: TextStyle(fontSize: 11)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 20,
                    height: 20,
                  ),
                  icon: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
            const Divider(height: 12),
            const Text('Title', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            TextField(controller: _title, decoration: _todoFieldDecoration()),
            const SizedBox(height: 13),
            const Text('Content', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            const _TodoEditor(),
            const SizedBox(height: 14),
            const Text('Any attachment?', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 26,
                    color: const Color(0xffe9ecef),
                    padding: const EdgeInsets.only(left: 8),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Click to upload',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Icon(Icons.upload, size: 15),
                const SizedBox(width: 4),
                const Text('Upload', style: TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 13),
            const Text('Priority', style: TextStyle(fontSize: 10)),
            RadioGroup<String>(
              groupValue: _priority,
              onChanged: (selected) => setState(() => _priority = selected!),
              child: Row(
                children: ['High', 'Medium', 'Normal']
                    .map(
                      (value) => Expanded(
                        child: RadioListTile<String>(
                          value: value,
                          title: Text(
                            value,
                            style: const TextStyle(fontSize: 10),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            _TodoLabelField(
              label: 'To be done by Date/Time',
              controller: _date,
            ),
            _TodoLabelField(
              label: 'Primary Responsible',
              controller: _responsible,
              dropdown: true,
            ),
            _TodoLabelField(label: 'Team Members', controller: _team),
            _TodoLabelField(label: 'Inform Members', controller: _informed),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff087ff5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 20),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text('Insert', style: TextStyle(fontSize: 8)),
                ),
                TextButton(
                  onPressed: () {
                    for (final controller in [
                      _title,
                      _date,
                      _responsible,
                      _team,
                      _informed,
                    ]) {
                      controller.clear();
                    }
                  },
                  child: const Text('Reset', style: TextStyle(fontSize: 8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _todoFieldDecoration() => const InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
  border: OutlineInputBorder(),
);

class _TodoLabelField extends StatelessWidget {
  const _TodoLabelField({
    required this.label,
    required this.controller,
    this.dropdown = false,
  });
  final String label;
  final TextEditingController controller;
  final bool dropdown;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: _todoFieldDecoration().copyWith(
            suffixIcon: dropdown
                ? const Icon(Icons.arrow_drop_down, size: 18)
                : null,
          ),
        ),
      ],
    ),
  );
}

class _TodoEditor extends StatelessWidget {
  const _TodoEditor();

  @override
  Widget build(BuildContext context) {
    const controls = [
      '✣',
      'B',
      'U',
      '▰',
      'Segoe UI',
      'A',
      '☷',
      '☰',
      '≡',
      '▦',
      '↔',
      '▣',
      '▰',
      'X',
      '</>',
      '?',
    ];
    return Container(
      height: 244,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffcccccc)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            children: controls
                .map(
                  (control) => Container(
                    width: control == 'Segoe UI' ? 57 : 29,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xffdddddd)),
                        bottom: BorderSide(color: Color(0xffdddddd)),
                      ),
                    ),
                    child: Text(
                      control,
                      style: const TextStyle(
                        fontSize: 11,
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
