import 'dart:convert';
import 'package:flutter/material.dart';
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
    return items.indexWhere((item) => item.index == targetIndex);
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
        activeIcon: Icons.assignment_ind_rounded,
        inactiveIcon: Icons.assignment_ind_outlined,
        label: 'List Myself',
        index: 11,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    } else if (hasOPD) {
      items.add(_BottomNavItem(
        activeIcon: Icons.person_add_rounded,
        inactiveIcon: Icons.person_add_outlined,
        label: 'Doctors',
        index: 5,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    } else if (hasPathology) {
      items.add(_BottomNavItem(
        activeIcon: Icons.science_rounded,
        inactiveIcon: Icons.science_outlined,
        label: 'Tests',
        index: 6,
        color: const Color(0xFF4F46E5), // Indigo
      ));
    }

    items.addAll([
      _BottomNavItem(
        activeIcon: Icons.calendar_month_rounded,
        inactiveIcon: Icons.calendar_today_outlined,
        label: 'Bookings',
        index: 15,
        color: const Color(0xFF00897B), // Teal
      ),
      _BottomNavItem(
        activeIcon: Icons.people_rounded,
        inactiveIcon: Icons.people_outline_rounded,
        label: 'Patients',
        index: 8,
        color: const Color(0xFFEA580C), // Sunset Orange
      ),
      _BottomNavItem(
        activeIcon: Icons.menu_rounded,
        inactiveIcon: Icons.menu_rounded,
        label: 'More',
        index: -1, // Drawer
        color: const Color(0xFF7C3AED), // Purple
      ),
    ]);

    return items;
  }

  void _onTabSelected(int targetIndex, int navPos) {
    if (targetIndex == -1) {
      widget.onTap(-1); // Open drawer without animating notch
      return;
    }

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
        final hasActiveNotch = activePos != -1;
        final effectivePos = hasActiveNotch ? activePos : _lastActiveNavPos;
        final activeItem = navItems[effectivePos.clamp(0, itemCount - 1)];

        return AnimatedBuilder(
          animation: _notchController,
          builder: (context, child) {
            final currentPos = hasActiveNotch ? _notchAnim.value : _lastActiveNavPos.toDouble();
            final cx = (currentPos + 0.5) * itemWidth;

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
                            final isSelected = widget.currentIndex == item.index;

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
                                        style: TextStyle(
                                          color: isSelected
                                              ? item.color
                                              : const Color(0xFF64748B),
                                          fontSize: fontSize,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          letterSpacing: 0.1,
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
                  if (hasActiveNotch)
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
