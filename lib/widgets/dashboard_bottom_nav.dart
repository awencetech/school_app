import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable bottom navigation used inside the dashboard sections only.
class ReusableBottomNavigationBar extends StatelessWidget {
  const ReusableBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF333856),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withValues(alpha: 0.8),
      selectedFontSize: 9,
      unselectedFontSize: 9,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w400,
      ),
      elevation: 0,
      currentIndex: currentIndex,
      onTap: onItemSelected,
      items: items,
    );
  }
}
