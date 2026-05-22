import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic> partnerData;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.partnerData,
  });

  List<String> _parseRegistrationTypes(dynamic rawType) {
    if (rawType == null) return [];
    if (rawType is List) {
      return rawType.map((e) => e.toString().trim()).toList();
    }
    final str = rawType.toString().trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).toList();
        }
      } catch (_) {}
      final clean = str
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('\\', '');
      return clean
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [str];
  }

  @override
  Widget build(BuildContext context) {
    final rawRegType = partnerData['registration_type'];
    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');
    final hasDoctor = types.contains('Doctor');

    final navItems = <_BottomNavItem>[
      _BottomNavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        index: 0,
      ),
    ];

    if (hasDoctor) {
      navItems.add(_BottomNavItem(
        icon: Icons.assignment_ind_rounded,
        label: 'List Myself',
        index: 11,
      ));
    }
    if (hasOPD) {
      navItems.add(_BottomNavItem(
        icon: Icons.person_add_rounded,
        label: 'Add Doctors',
        index: 5,
      ));
    }
    if (hasPathology) {
      navItems.add(_BottomNavItem(
        icon: Icons.science_rounded,
        label: 'Add Tests',
        index: 6,
      ));
    }

    navItems.addAll([
      _BottomNavItem(
        icon: Icons.today_rounded,
        label: "Today's Bookings",
        index: 15,
      ),
      _BottomNavItem(
        icon: Icons.assignment_rounded,
        label: 'Patient Lists',
        index: 8,
      ),
      _BottomNavItem(
        icon: Icons.menu_rounded,
        label: 'More',
        index: -1, // Special index to open drawer
      ),
    ]);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navItems.map((item) {
                  return _buildNavItem(
                    icon: item.icon,
                    label: item.label,
                    index: item.index,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.teal.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.teal : AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.teal : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final int index;

  _BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
