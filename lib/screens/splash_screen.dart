import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import '../core/session_manager.dart';
import 'welcome_screen.dart';
import 'coupon_screen.dart';
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
        final String status = partnerData['status']?.toString() ?? 'Pending';

        if (status.toLowerCase() == 'pending') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CouponScreen(
                partnerData: partnerData,
                token: token,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(partnerData: partnerData),
            ),
          );
        }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. WHITE MODE GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF6F9FC),
                  Color(0xFFEDF3F8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. FINE LIGHT GREY MEDICAL GRID
          Opacity(
            opacity: 0.15,
            child: GridPaper(
              color: Colors.blueGrey.shade200,
              divisions: 1,
              interval: 20,
              subdivisions: 1,
              child: Container(),
            ),
          ),

          // 3. SERVICE PILLARS ON TOP (Doctor Chambers, Pathology Labs, Individual Doctors)
          Positioned(
            top: screenHeight * 0.08,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pillar 1: Doctor Chambers
                _buildAnimatedServiceBadge(
                  index: 0,
                  icon: Icons.medical_services_rounded,
                  label: 'Doctor Chambers',
                  glowColor: AppColors.teal,
                ),

                // Pillar 2: Pathology Labs
                _buildAnimatedServiceBadge(
                  index: 1,
                  icon: Icons.biotech_rounded,
                  label: 'Pathology Labs',
                  glowColor: const Color(0xFF0EA5E9),
                ),

                // Pillar 3: Individual Doctors
                _buildAnimatedServiceBadge(
                  index: 2,
                  icon: Icons.badge_rounded,
                  label: 'Individual Doctors',
                  glowColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // 4. CENTRAL SQUARE LOGO & BRAND TYPOGRAPHY
          Positioned(
            top: screenHeight * 0.32,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO: SQUARE WITH BORDER RADIUS, NO rigid outline border, pulsing glowing shadow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 135,
                        height: 135,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.18),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
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

                const SizedBox(height: 30),

                // BRAND SUITE TYPOGRAPHY
                Text(
                  'DOCTORWALA',
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: 4.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                // PARTNERS NETWORK TAGLINE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MEDICAL ECOSYSTEM PARTNER HUB',
                        style: GoogleFonts.manrope(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy.withValues(alpha: 0.75),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. ANIMATED ECG HEART RATE LINE (Positioned strictly at bottom, no overlays!)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            height: 70, // Sleek, thin, completely clear of text elements!
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

          // 6. BOTTOM SCANNING INDICATION & PROGRESS
          Positioned(
            bottom: 45,
            left: 30,
            right: 30,
            child: Column(
              children: [
                SizedBox(
                  width: screenWidth * 0.45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                      minHeight: 3.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Connecting to medical systems network...',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
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
  }) {
    final bool isActive = _isHighlighted[index];

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Subtle floating offset offsetted by index
        final floatOffset = 5 * math.sin((_floatController.value + (index * 0.3)) * math.pi);
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: AnimatedScale(
            scale: isActive ? 1.12 : 0.95,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 105,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                        ? glowColor.withValues(alpha: 0.15) 
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: isActive ? 15 : 6,
                    spreadRadius: isActive ? 2 : 0,
                    offset: Offset(0, isActive ? 6 : 2),
                  )
                ],
                border: Border.all(
                  color: isActive ? glowColor : Colors.grey.shade100,
                  width: isActive ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? glowColor.withValues(alpha: 0.1) 
                          : Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? glowColor : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.navy : Colors.grey.shade500,
                      height: 1.2,
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
