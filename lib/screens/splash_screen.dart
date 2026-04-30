import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
              height: 100, // Sufficient height to fill the bottom area
              color: AppColors.waveBlue.withOpacity(0.4), // Light blue matching the asset
            ),
          ),

          // 2. BOTTOM WAVY IMAGE - LOCKED AT ABSOLUTE BOTTOM
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              AppAssets.splashBottom,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          
          // FLOATING LOGO - TOP RIGHT
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 25,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 10 * _floatController.value),
                  child: child,
                );
              },
              child: FadeInRight(
                child: Image.asset(
                  AppAssets.logo,
                  height: 55,
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
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  // Marketing Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInLeft(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Doctorwala',
                                style: GoogleFonts.manrope(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'Medical Ecosystem Partner Portal',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // BLUE PORTAL BOX
                        FadeInLeft(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'OPD & Pathology Clinics',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          'OR',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: AppColors.teal,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Individual Doctors Portal',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
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
                        
                        const SizedBox(height: 30),
                        
                        // GET STARTED BUTTON
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.getStartedGradient,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
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
}
