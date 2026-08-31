import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class NewsLetterPage extends StatelessWidget {
  const NewsLetterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Newsletter'),
      ),
      body: const Center(
        child: Text(
          'No newsletter content yet.',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
    );
  }
}
