import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class HappinessReportPage extends StatefulWidget {
  const HappinessReportPage({super.key, required this.group});

  final Group group;

  @override
  State<HappinessReportPage> createState() => _HappinessReportPageState();
}

class _HappinessReportPageState extends State<HappinessReportPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text(
          'Today in Class',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 3, 6),
              child: Text(
                '${widget.group.name}${widget.group.year} Happiness Report',
                style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  _tab('Report', 0),
                  _tab('Comments', 1),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: _selectedTab == 0
                  ? const _HappinessTrend()
                  : const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No comments available.',
                        style: TextStyle(fontSize: 10, color: Color(0xff444444)),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(left: 3, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xfffafafa),
          border: Border.all(color: const Color(0xffeeeeee)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: selected ? const Color(0xff555555) : const Color(0xff0066cc),
          ),
        ),
      ),
    );
  }
}

class _HappinessTrend extends StatelessWidget {
  const _HappinessTrend();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SizedBox(
          height: 205,
          width: constraints.maxWidth,
          child: CustomPaint(
            painter: _HappinessChartPainter(),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 7),
                child: Text(
                  'Class Happiness State Trend',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HappinessChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const left = 16.0;
    const right = 15.0;
    const top = 19.0;
    const bottom = 25.0;
    final chartHeight = size.height - top - bottom;
    final axisPaint = Paint()
      ..color = const Color(0xff222222)
      ..strokeWidth = 0.8;
    final tickPaint = Paint()
      ..color = const Color(0xff777777)
      ..strokeWidth = 0.5;

    canvas.drawLine(const Offset(left, top), Offset(left, top + chartHeight), axisPaint);
    canvas.drawLine(Offset(left, top + chartHeight), Offset(size.width - right, top + chartHeight), axisPaint);
    canvas.drawLine(Offset(size.width - right, top), Offset(size.width - right, top + chartHeight), axisPaint);

    const labels = ['1', '0.9', '0.8', '0.7', '0.6', '0.5', '0.4', '0.3', '0.2', '0.1', '0'];
    for (var index = 0; index < labels.length; index++) {
      final y = top + chartHeight * index / (labels.length - 1);
      canvas.drawLine(Offset(left - 3, y), Offset(left, y), tickPaint);
      canvas.drawLine(Offset(size.width - right, y), Offset(size.width - right + 3, y), tickPaint);
      _drawText(canvas, labels[index], Offset(1, y - 4));
      _drawText(canvas, labels[index], Offset(size.width - 12, y - 4));
    }
  }

  void _drawText(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(fontSize: 7, color: Color(0xff222222)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}