import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class DashboardExtraQuickAccess extends StatelessWidget {
  const DashboardExtraQuickAccess({
    super.key,
    this.crossAxisCount = 4,
    this.leadingItems = const [],
    this.onGroupClassBusTap,
    this.onCheckApproveTap,
    this.onUniRouteZ2Tap,
    this.onSp7Tap,
    this.onTrackTap,
  });

  final int crossAxisCount;
  final List<Widget> leadingItems;
  final VoidCallback? onGroupClassBusTap;
  final VoidCallback? onCheckApproveTap;
  final VoidCallback? onUniRouteZ2Tap;
  final VoidCallback? onSp7Tap;
  final VoidCallback? onTrackTap;

  static const _items = [
    _ExtraAction('Groups/class Bus', Icons.directions_bus, Color(0xffe85d4a)),
    _ExtraAction('Check Approve', Icons.fact_check, Color(0xffd9c900)),
    _ExtraAction(
      'Track UNI Route - Z2',
      Icons.directions_bus,
      Color(0xff2376a9),
    ),
    _ExtraAction('Track SP7', Icons.directions_bus, Color(0xff2376a9)),
    _ExtraAction('Track', Icons.directions_bus, Color(0xff2376a9)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: leadingItems.length + _items.length,
      itemBuilder: (context, index) {
        if (index < leadingItems.length) {
          return leadingItems[index];
        }

        final extraIndex = index - leadingItems.length;
        final item = _items[extraIndex];
        return InkWell(
          onTap: extraIndex == 0 && onGroupClassBusTap != null
              ? onGroupClassBusTap
              : extraIndex == 1 && onCheckApproveTap != null
              ? onCheckApproveTap
              : extraIndex == 2 && onUniRouteZ2Tap != null
              ? onUniRouteZ2Tap
              : extraIndex == 3 && onSp7Tap != null
              ? onSp7Tap
              : extraIndex == 4 && onTrackTap != null
              ? onTrackTap
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ExtraQuickAccessDetailsPage(item: item),
                  ),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 16, color: AppColors.white),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 3,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff222222),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExtraAction {
  const _ExtraAction(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _ExtraQuickAccessDetailsPage extends StatelessWidget {
  const _ExtraQuickAccessDetailsPage({required this.item});

  final _ExtraAction item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  item.label.replaceAll('\n', ' '),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _description(item.label),
              style: GoogleFonts.poppins(fontSize: 12, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  String _description(String label) {
    switch (label) {
      case 'Groups/class Bus':
        return 'View the assigned group or class bus information.';
      case 'Check Approve':
        return 'Review items waiting for approval and check their status.';
      case 'Campaign\nSurvey':
        return 'View available campaigns and surveys.';
      case 'Track UNI Route - Z2':
        return 'Track the UNI-Route Z2 bus.';
      case 'Track SP7':
        return 'Track the SP7 bus.';
      default:
        return 'Track the assigned bus.';
    }
  }
}
