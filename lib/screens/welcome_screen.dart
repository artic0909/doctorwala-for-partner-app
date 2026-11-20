import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenWidth < 360;
    final heroHeight = (screenHeight * 0.28).clamp(175.0, 270.0);
    final horizontalPad = isCompact ? 18.0 : 26.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. MATCHING COLOR BACKGROUND FOR THE BOTTOM WAVE AREA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color: AppColors.waveBlue.withValues(alpha: 0.4),
            ),
          ),

          // 2. BOTTOM WAVY IMAGE
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.splashBottom,
              width: screenWidth,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // FLOATING LOGO
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: isCompact ? 16 : 24,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * _floatController.value),
                  child: child,
                );
              },
              child: FadeInRight(
                child: Image.asset(
                  AppAssets.logo,
                  height: isCompact ? 46 : 54,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // CONTENT SECTION
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 5),

                  // HERO IMAGE
                  FadeInDown(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Image.asset(
                        AppAssets.splash,
                        height: heroHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Marketing Content
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME TO',
                                style: GoogleFonts.manrope(
                                  fontSize: isCompact ? 11 : 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Doctorwala',
                                style: GoogleFonts.manrope(
                                  fontSize: (screenWidth * 0.105).clamp(30.0, 42.0),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Medical Ecosystem Partner Portal',
                                style: GoogleFonts.manrope(
                                  fontSize: isCompact ? 12.5 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // DOCTORWALA FOR AUDIENCE SECTION (Unboxed clean redesign)
                        FadeInLeft(
                          delay: const Duration(milliseconds: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.teal,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Doctorwala for',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildAudienceItem(
                                icon: Icons.medical_services_rounded,
                                title: 'Specialized Doctors',
                                color: AppColors.teal,
                              ),
                              _buildAudienceItem(
                                icon: Icons.accessibility_new_rounded,
                                title: 'Physiotherapist & Allied Care',
                                color: const Color(0xFF2563EB),
                              ),
                              _buildAudienceItem(
                                icon: Icons.apartment_rounded,
                                title: 'OPD Chambers',
                                color: AppColors.navy,
                              ),
                              _buildAudienceItem(
                                icon: Icons.biotech_rounded,
                                title: 'Lab Tests Provider',
                                color: const Color(0xFF0D9488),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TAGLINE
                        FadeInLeft(
                          delay: const Duration(milliseconds: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage your practice. Serve better.',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Grow together with us.',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // GET STARTED BUTTON
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.getStartedGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.teal,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}
