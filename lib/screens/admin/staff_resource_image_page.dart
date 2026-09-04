import 'package:flutter/material.dart';

import '../../models/staff_resource.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class StaffResourceImagePage extends StatelessWidget {
  const StaffResourceImagePage({super.key, required this.resource});
  final StaffResource? resource;

  @override
  Widget build(BuildContext context) {
    final item = resource;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Resource Image'),
      ),
      body: item == null
          ? const Center(child: Text('Resource is unavailable.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(item.description, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.staffName.isEmpty ? 'Staff ID: ${item.staffId}' : '${item.staffName}  |  ${item.staffId}'),
                const SizedBox(height: 18),
                if (item.slipReportImageUrl.isEmpty)
                  const Center(child: Text('No image available for this resource.'))
                else
                  Image.network(
                    item.slipReportImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
                    errorBuilder: (_, error, stack) => const Center(child: Text('Unable to load the resource image.')),
                  ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.description),
              ],
            ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          if (index == 3) Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          if (index == 4) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        },
      ),
    );
  }
}
