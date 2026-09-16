import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'dashboard_icon_grid.dart';

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
    this.showCheckApprove = true,
    this.appBarTitle = 'Quick Access',
  });

  final int crossAxisCount;
  final List<Widget> leadingItems;
  final VoidCallback? onGroupClassBusTap;
  final VoidCallback? onCheckApproveTap;
  final VoidCallback? onUniRouteZ2Tap;
  final VoidCallback? onSp7Tap;
  final VoidCallback? onTrackTap;
  final bool showCheckApprove;
  final String appBarTitle;

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
    final l10n = AppLocalizations.of(context);
    final localizedAppBarTitle = appBarTitle == 'Quick Access'
        ? l10n.quickAccess
        : appBarTitle;
    final extraIndexes = [
      0,
      if (showCheckApprove) 1,
      2,
      3,
      4,
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DashboardIconGrid.columnCount,
        crossAxisSpacing: DashboardIconGrid.crossAxisSpacing,
        mainAxisSpacing: DashboardIconGrid.mainAxisSpacing,
        childAspectRatio: DashboardIconGrid.childAspectRatio,
      ),
      itemCount: leadingItems.length + extraIndexes.length,
      itemBuilder: (context, index) {
        if (index < leadingItems.length) {
          return leadingItems[index];
        }

        final extraIndex = index - leadingItems.length;
        final itemIndex = extraIndexes[extraIndex];
        final item = _localizedItem(l10n, _items[itemIndex]);
        return InkWell(
          onTap: itemIndex == 0 && onGroupClassBusTap != null
              ? onGroupClassBusTap
              : itemIndex == 1 && onCheckApproveTap != null
              ? onCheckApproveTap
              : itemIndex == 2 && onUniRouteZ2Tap != null
              ? onUniRouteZ2Tap
              : itemIndex == 3 && onSp7Tap != null
              ? onSp7Tap
              : itemIndex == 4 && onTrackTap != null
              ? onTrackTap
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ExtraQuickAccessDetailsPage(
                      item: item,
                      appBarTitle: localizedAppBarTitle,
                    ),
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
              Expanded(
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff222222),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _ExtraAction _localizedItem(AppLocalizations l10n, _ExtraAction item) {
    switch (item.label) {
      case 'Groups/class Bus':
        return item.copyWith(label: l10n.groupsClassBus);
      case 'Check Approve':
        return item.copyWith(label: l10n.checkApprove);
      case 'Track UNI Route - Z2':
        return item.copyWith(label: l10n.trackUniRoute);
      case 'Track SP7':
        return item.copyWith(label: l10n.track57);
      case 'Track':
        return item.copyWith(label: l10n.track);
      default:
        return item;
    }
  }
}

class _ExtraAction {
  const _ExtraAction(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  _ExtraAction copyWith({String? label}) =>
      _ExtraAction(label ?? this.label, icon, color);
}

class _ExtraQuickAccessDetailsPage extends StatelessWidget {
  const _ExtraQuickAccessDetailsPage({
    required this.item,
    required this.appBarTitle,
  });

  final _ExtraAction item;
  final String appBarTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(appBarTitle, style: const TextStyle(fontSize: 14)),
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
