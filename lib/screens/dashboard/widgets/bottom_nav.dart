import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic> partnerData;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.partnerData,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _notchController;
  late Animation<double> _notchAnim;
  int _lastActiveNavPos = 0;

  @override
  void initState() {
    super.initState();
    final navItems = _getNavItems();
    final initialPos = _findNavPos(widget.currentIndex, navItems);
    _lastActiveNavPos = initialPos != -1 ? initialPos : 0;

    _notchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _notchAnim = Tween<double>(
      begin: _lastActiveNavPos.toDouble(),
      end: _lastActiveNavPos.toDouble(),
    ).animate(
      CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final navItems = _getNavItems();
      final newPos = _findNavPos(widget.currentIndex, navItems);
      if (newPos != -1 && newPos != _lastActiveNavPos) {
        _notchAnim = Tween<double>(
          begin: _notchAnim.value,
          end: newPos.toDouble(),
        ).animate(
          CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
        );
        _notchController.forward(from: 0.0);
        _lastActiveNavPos = newPos;
      }
    }
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  int _findNavPos(int targetIndex, List<_BottomNavItem> items) {
    // 1. Direct match with items in bottom nav
    final direct = items.indexWhere((item) => item.index == targetIndex);
    if (direct != -1) return direct;

    // 2. Map all sub-pages / shortcuts to their parent bottom nav tab:
    int mappedIndex = targetIndex;

    // Appointments/Bookings family:
    // 1: Upcoming Appointments
    // 9: Completed Appointments
    // 14: Cancelled Appointments
    // 15: Today's Bookings
    if (targetIndex == 1 || targetIndex == 9 || targetIndex == 14 || targetIndex == 15) {
      mappedIndex = 15;
    }
    // Patients / Medical Card family:
    // 7: Medical Card Access
    // 8: Patient Lists
    else if (targetIndex == 7 || targetIndex == 8) {
      mappedIndex = 8;
    }
    // Account / Settings / Help family:
    // 2: Account Settings
    // 10: Help & Support
    else if (targetIndex == 2 || targetIndex == 10) {
      mappedIndex = 2;
    }
    // Doctor / Chamber / Pathology / Services family:
    // 3: Doctor Chamber
    // 4: Pathology Clinic
    // 5: Show/Add Doctors
    // 6: Show/Add Tests
    // 11: List Myself / Doctor Profile
    else if (targetIndex == 3 || targetIndex == 4 || targetIndex == 5 || targetIndex == 6 || targetIndex == 11) {
      if (items.any((item) => item.index == 11)) {
        mappedIndex = 11;
      } else if (items.any((item) => item.index == 5)) {
        mappedIndex = 5;
      } else if (items.any((item) => item.index == 6)) {
        mappedIndex = 6;
      }
    }

    final mappedPos = items.indexWhere((item) => item.index == mappedIndex);
    if (mappedPos != -1) return mappedPos;

    // Fallback to Home (pos 0) if no mapping found, so the notch is never empty
    return 0;
  }

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

  List<_BottomNavItem> _getNavItems() {
    final rawRegType = widget.partnerData['registration_type'];
    final types = _parseRegistrationTypes(rawRegType);
    final hasOPD = types.contains('OPD');
    final hasPathology = types.contains('Pathology');
    final hasDoctor = types.contains('Doctor');

    final items = <_BottomNavItem>[
      _BottomNavItem(
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        label: 'Home',
        index: 0,
        color: const Color(0xFF1565C0), // Royal Blue
      ),
    ];

    if (hasDoctor) {
      items.add(_BottomNavItem(
        activeIcon: Icons.medical_information_rounded,
        inactiveIcon: Icons.medical_information_outlined,
        label: 'List Myself',
        index: 11,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    } else if (hasOPD) {
      items.add(_BottomNavItem(
        activeIcon: Icons.medical_services_rounded,
        inactiveIcon: Icons.medical_services_outlined,
        label: 'Doctors',
        index: 5,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    } else if (hasPathology) {
      items.add(_BottomNavItem(
        activeIcon: Icons.biotech_rounded,
        inactiveIcon: Icons.biotech_outlined,
        label: 'Tests',
        index: 6,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    }

    items.addAll([
      _BottomNavItem(
        activeIcon: Icons.event_available_rounded,
        inactiveIcon: Icons.event_available_outlined,
        label: 'Bookings',
        index: 15,
        color: const Color(0xFF00897B), // Teal
      ),
      _BottomNavItem(
        activeIcon: Icons.people_alt_rounded,
        inactiveIcon: Icons.people_alt_outlined,
        label: 'Patients',
        index: 8,
        color: const Color(0xFFEA580C), // Sunset Orange
      ),
      _BottomNavItem(
        activeIcon: Icons.account_circle_rounded,
        inactiveIcon: Icons.account_circle_outlined,
        label: 'Account',
        index: 2, // Account Settings
        color: const Color(0xFF7C3AED), // Purple
      ),
    ]);

    return items;
  }

  void _onTabSelected(int targetIndex, int navPos) {
    if (widget.currentIndex != targetIndex) {
      _notchAnim = Tween<double>(
        begin: _notchAnim.value,
        end: navPos.toDouble(),
      ).animate(
        CurvedAnimation(parent: _notchController, curve: Curves.easeInOutCubic),
      );
      _notchController.forward(from: 0.0);
      _lastActiveNavPos = navPos;
      widget.onTap(targetIndex);
    } else {
      widget.onTap(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    final itemCount = navItems.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final scale = (w / 375.0).clamp(0.90, 1.25);

        final itemWidth = w / itemCount;
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        final barHeight = (60.0 * scale).clamp(58.0, 68.0);
        final totalHeight = barHeight + bottomPadding;

        // Responsive dimensions for active button and notch
        final activeBtnSize = (50.0 * scale).clamp(48.0, 56.0);
        final activeInnerSize = activeBtnSize - 8.0;
        final activeIconSize = (23.5 * scale).clamp(22.0, 27.0);

        final notchRadius = (activeBtnSize / 2) + 5.5;
        final shoulderRadius = (13.0 * scale).clamp(11.0, 16.0);
        final depth = (21.0 * scale).clamp(19.0, 25.0);
        final topRadius = (22.0 * scale).clamp(20.0, 26.0);

        final inactiveIconSize = (22.0 * scale).clamp(20.0, 25.0);
        final fontSize = (10.0 * scale).clamp(9.5, 12.0);

        final activePos = _findNavPos(widget.currentIndex, navItems);
        final effectivePos = activePos.clamp(0, itemCount - 1);
        final activeItem = navItems[effectivePos];

        return AnimatedBuilder(
          animation: _notchController,
          builder: (context, child) {
            final cx = (_notchAnim.value + 0.5) * itemWidth;

            return SizedBox(
              width: w,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Smooth Custom Curved Notched Background
                  CustomPaint(
                    size: Size(w, totalHeight),
                    painter: CurvedNotchPainter(
                      centerX: cx,
                      color: Colors.white,
                      canvasBackgroundColor: AppColors.background,
                      notchRadius: notchRadius,
                      shoulderRadius: shoulderRadius,
                      depth: depth,
                      topRadius: topRadius,
                    ),
                    child: SizedBox(
                      width: w,
                      height: totalHeight,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
                        child: Row(
                          children: List.generate(itemCount, (i) {
                            final item = navItems[i];
                            final isSelected = effectivePos == i;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _onTabSelected(item.index, i),
                                behavior: HitTestBehavior.opaque,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 180),
                                        opacity: isSelected ? 0.0 : 1.0,
                                        child: Icon(
                                          item.inactiveIcon,
                                          color: const Color(0xFF94A3B8),
                                          size: inactiveIconSize,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: isSelected
                                              ? item.color
                                              : const Color(0xFF64748B),
                                          fontSize: fontSize,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  // Raised Active Circular Floating Button
                  Positioned(
                    left: cx - (activeBtnSize / 2),
                    top: -(activeBtnSize * 0.3),
                    child: GestureDetector(
                      onTap: () => _onTabSelected(activeItem.index, effectivePos),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: activeBtnSize,
                          height: activeBtnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: activeItem.color.withAlpha(55),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: activeInnerSize,
                              height: activeInnerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeItem.color.withAlpha(24),
                              ),
                              child: Icon(
                                activeItem.activeIcon,
                                color: activeItem.color,
                                size: activeIconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BottomNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final int index;
  final Color color;

  _BottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.index,
    required this.color,
  });
}

class CurvedNotchPainter extends CustomPainter {
  final double centerX;
  final Color color;
  final Color canvasBackgroundColor;
  final double notchRadius;
  final double shoulderRadius;
  final double depth;
  final double topRadius;

  CurvedNotchPainter({
    required this.centerX,
    this.color = Colors.white,
    this.canvasBackgroundColor = const Color(0xFFF9FBFF),
    this.notchRadius = 31.0,
    this.shoulderRadius = 14.0,
    this.depth = 22.0,
    this.topRadius = 22.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = centerX;

    // Fill the background of the notch area with the exact screen background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = canvasBackgroundColor,
    );

    final path = Path();
    path.moveTo(0, topRadius);
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: Radius.circular(topRadius),
    );

    // Left flat edge up to notch entry
    final entryX = (cx - notchRadius - shoulderRadius).clamp(topRadius, w - topRadius);
    path.lineTo(entryX, 0);

    // Smooth concave dip into notch
    path.cubicTo(
      cx - notchRadius, 0,
      cx - notchRadius * 0.72, depth,
      cx, depth,
    );

    // Smooth exit from notch
    final exitX = (cx + notchRadius + shoulderRadius).clamp(topRadius, w - topRadius);
    path.cubicTo(
      cx + notchRadius * 0.72, depth,
      cx + notchRadius, 0,
      exitX, 0,
    );

    // Right flat edge
    path.lineTo(w - topRadius, 0);
    path.arcToPoint(
      Offset(w, topRadius),
      radius: Radius.circular(topRadius),
    );

    // Right, bottom, and left
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Pure neutral soft shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(const Offset(0, -1.5)), shadowPaint);

    // Paint white bar
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.color != color ||
      oldDelegate.canvasBackgroundColor != canvasBackgroundColor ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.depth != depth ||
      oldDelegate.topRadius != topRadius;
}
