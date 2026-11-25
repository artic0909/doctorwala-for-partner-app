import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import '../core/session_manager.dart';
import 'welcome_screen.dart';
import 'dashboard/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ecgController;
  late AnimationController _floatController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Additive highlights list (tracks active state for Chambers, Labs, and Doctors)
  final List<bool> _isHighlighted = [false, false, false];

  @override
  void initState() {
    super.initState();

    // Pulse animation for the central neon medical cross
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 10.0, end: 25.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // ECG heartbeat wave scanning sweep
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Soft floating drift for medical badges
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Start the sequential, cumulative highlight onboarding animation!
    _startIntroSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ecgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _startIntroSequence() async {
    // 1. Initial delay for grid and core animations to initialize
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // 2. Highlight Doctor Chambers (and keep it active!)
    setState(() {
      _isHighlighted[0] = true;
    });

    // 3. Sequential delay (750ms)
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    // 4. Highlight Pathology Labs (and keep it active!)
    setState(() {
      _isHighlighted[1] = true;
    });

    // 5. Sequential delay (750ms)
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    // 6. Highlight Individual Doctors (and keep it active!)
    setState(() {
      _isHighlighted[2] = true;
    });

    // 7. Briefly hold all highlighted items in full visual glory before executing session check!
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    _checkActiveSession();
  }

  void _checkActiveSession() async {
    final bool hasSession = await SessionManager.hasSession();

    if (!mounted) return;

    if (hasSession) {
      final token = await SessionManager.getToken();
      final partnerData = await SessionManager.getPartnerData();

      if (!mounted) return;

      if (token != null && partnerData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(partnerData: partnerData),
          ),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final double horizontalMargin = (screenWidth * 0.045).clamp(12.0, 22.0);
    final double cardPadH = (screenWidth * 0.042).clamp(12.0, 22.0);
    final double cardPadV = (screenHeight * 0.024).clamp(14.0, 24.0);
    final double logoSize = (screenWidth * 0.135).clamp(44.0, 60.0);
    final double titleFontSize = (screenWidth * 0.052).clamp(17.0, 22.0);
    final double gapAfterHeader = (screenHeight * 0.028).clamp(14.0, 28.0);
    final double gapAfterBadges = (screenHeight * 0.024).clamp(12.0, 24.0);
    final double ecgHeight = (screenHeight * 0.045).clamp(26.0, 40.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. SPLASH SCREEN BACKGROUND IMAGE (Shifted right-wise to frame both doctors perfectly)
          Positioned.fill(
            child: Image.asset(
              AppAssets.splashBg,
              fit: BoxFit.cover,
              alignment: const Alignment(0.45, -0.2),
            ),
          ),

          // 2. PREMIUM TRANSLUCENT FADING BACKDROP
          Positioned(
            top: screenHeight * 0.45,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.65),
                    Colors.white.withValues(alpha: 0.94),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. FINE LIGHT GREY MEDICAL GRID
          Opacity(
            opacity: 0.06,
            child: GridPaper(
              color: Colors.blueGrey.shade200,
              divisions: 1,
              interval: 20,
              subdivisions: 1,
              child: Container(),
            ),
          ),

          // 4. RESPONSIVE FLOATING GLASSMEDIC CONTROL CARD DECK
          Positioned(
            bottom: bottomInset + (screenHeight * 0.02).clamp(12.0, 22.0),
            left: horizontalMargin,
            right: horizontalMargin,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  maxHeight: screenHeight * 0.56,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadH,
                    vertical: cardPadV,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.03),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70),
                      width: 1.8,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A. THE BRAND LOGO & NAME
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(logoSize * 0.3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.teal.withValues(alpha: 0.22),
                                          blurRadius: _glowAnimation.value * 0.5,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(logoSize * 0.3),
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Image.asset(
                                          AppAssets.logo,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: (screenWidth * 0.032).clamp(10.0, 14.0)),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DOCTORWALA',
                                      style: GoogleFonts.manrope(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.navy,
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'PARTNER APP',
                                      style: GoogleFonts.manrope(
                                        fontSize: (titleFontSize * 0.48).clamp(9.0, 11.0),
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.teal,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: gapAfterHeader),

                        // B. RESPONSIVE GLASS SERVICES ROW (No overlap on any screen width)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildAnimatedServiceBadge(
                                  index: 0,
                                  icon: Icons.medical_services_rounded,
                                  label: 'Doctor\nChambers',
                                  glowColor: AppColors.teal,
                                  screenWidth: screenWidth,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildAnimatedServiceBadge(
                                  index: 1,
                                  icon: Icons.biotech_rounded,
                                  label: 'Pathology\nLabs',
                                  glowColor: const Color(0xFF0EA5E9),
                                  screenWidth: screenWidth,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildAnimatedServiceBadge(
                                  index: 2,
                                  icon: Icons.badge_rounded,
                                  label: 'Individual\nDoctors',
                                  glowColor: const Color(0xFF10B981),
                                  screenWidth: screenWidth,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: gapAfterBadges),

                        // C. ECG HEART RATE LINE
                        SizedBox(
                          height: ecgHeight,
                          width: double.infinity,
                          child: AnimatedBuilder(
                            animation: _ecgController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: ECGWavePainter(
                                  progress: _ecgController.value,
                                  color: AppColors.teal.withValues(alpha: 0.8),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: gapAfterBadges),

                        // D. BOTTOM SCANNING INDICATION & PROGRESS BAR
                        SizedBox(
                          width: (screenWidth * 0.45).clamp(130.0, 210.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.black.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                              minHeight: 3.5,
                            ),
                          ),
                        ),
                        SizedBox(height: (screenHeight * 0.012).clamp(8.0, 12.0)),
                        Text(
                          'Connecting to medical systems network...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: (screenWidth * 0.025).clamp(8.5, 10.5),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GLASSMORPHIC SERVICES BADGES WITH SEQUENCE HIGHLIGHT & POP ANIMATION
  Widget _buildAnimatedServiceBadge({
    required int index,
    required IconData icon,
    required String label,
    required Color glowColor,
    required double screenWidth,
  }) {
    final bool isActive = _isHighlighted[index];
    final double iconSize = (screenWidth * 0.056).clamp(18.0, 24.0);
    final double iconPad = (screenWidth * 0.02).clamp(6.0, 9.0);
    final double labelSize = (screenWidth * 0.024).clamp(8.0, 10.0);

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset = 4 * math.sin((_floatController.value + (index * 0.3)) * math.pi);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: AnimatedScale(
            scale: isActive ? 1.04 : 0.96,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth * 0.015).clamp(4.0, 8.0),
                vertical: (screenWidth * 0.025).clamp(8.0, 12.0),
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? glowColor.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isActive ? 12 : 6,
                    spreadRadius: isActive ? 1 : 0,
                    offset: Offset(0, isActive ? 5 : 3),
                  )
                ],
                border: Border.all(
                  color: isActive ? glowColor : Colors.white.withValues(alpha: 0.40),
                  width: isActive ? 1.8 : 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(iconPad),
                    decoration: BoxDecoration(
                      color: isActive
                          ? glowColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100.withValues(alpha: 0.50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? glowColor : Colors.grey.shade500,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.manrope(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w900,
                        color: isActive ? AppColors.navy : Colors.grey.shade500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic Custom Painter that draws a highly polished medical ECG heartbeat line
class ECGWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  ECGWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    final List<math.Point<double>> tracePoints = [];
    
    const cycles = 3;
    final cycleWidth = width / cycles;

    for (int i = 0; i <= 360; i++) {
      double x = (i / 360.0) * width;
      double cycleX = x % cycleWidth;
      double cycleProgress = cycleX / cycleWidth;
      
      double y = midY;

      // Map segments of the single heartbeat trace
      if (cycleProgress > 0.15 && cycleProgress < 0.25) {
        // P-Wave (Small positive bump)
        double segmentT = (cycleProgress - 0.15) / 0.10;
        y = midY - (math.sin(segmentT * math.pi) * 8);
      } else if (cycleProgress >= 0.25 && cycleProgress < 0.28) {
        // Q-Dip (Sharp minor downward spike)
        double segmentT = (cycleProgress - 0.25) / 0.03;
        y = midY + (segmentT * 6);
      } else if (cycleProgress >= 0.28 && cycleProgress < 0.32) {
        // R-Spike (Huge, sharp upward peak)
        double segmentT = (cycleProgress - 0.28) / 0.04;
        if (segmentT < 0.5) {
          y = midY + 6 - (segmentT / 0.5 * 38);
        } else {
          y = midY - 32 + ((segmentT - 0.5) / 0.5 * 48);
        }
      } else if (cycleProgress >= 0.32 && cycleProgress < 0.36) {
        // S-Drop (Sharp downward recovery dip)
        double segmentT = (cycleProgress - 0.32) / 0.04;
        y = midY + 16 - (segmentT * 16);
      } else if (cycleProgress >= 0.40 && cycleProgress < 0.55) {
        // T-Wave (Medium smooth positive recovery hump)
        double segmentT = (cycleProgress - 0.40) / 0.15;
        y = midY - (math.sin(segmentT * math.pi) * 12);
      }

      tracePoints.add(math.Point(x, y));
    }

    if (tracePoints.isEmpty) return;

    path.moveTo(tracePoints[0].x, tracePoints[0].y);
    for (int i = 1; i < tracePoints.length; i++) {
      path.lineTo(tracePoints[i].x, tracePoints[i].y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    final activeX = progress * width;
    
    double activeY = midY;
    double minDiff = double.infinity;
    for (var pt in tracePoints) {
      double diff = (pt.x - activeX).abs();
      if (diff < minDiff) {
        minDiff = diff;
        activeY = pt.y;
      }
    }

    final activePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final activeGlowPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(activeX, activeY), 5.0, activeGlowPaint);
    canvas.drawCircle(Offset(activeX, activeY), 3.0, activePaint);
  }

  @override
  bool shouldRepaint(covariant ECGWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
