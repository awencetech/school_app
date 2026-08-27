import 'package:flutter/material.dart';

class DashboardIconGrid extends StatelessWidget {
  const DashboardIconGrid({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  }) : itemBuilder = null,
       itemCount = null;

  const DashboardIconGrid.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  }) : children = null;

  final List<Widget>? children;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;
  final EdgeInsetsGeometry padding;

  int _columnCount(double width) {
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCount(constraints.maxWidth);
        return Center(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: itemCount ?? children!.length,
            itemBuilder: itemBuilder ?? (context, index) => children![index],
          ),
        );
      },
    );
  }
}
