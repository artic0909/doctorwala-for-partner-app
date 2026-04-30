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

class _SplashScreenState extends State<SplashScreen> {
  int _currentBenefitIndex = 0;
  final List<Map<String, String>> _benefits = [
    {
      'title': 'Expand Your Reach',
      'desc': 'Connect with 10,000+ patients in your locality effortlessly.',
      'icon': '🚀'
    },
    {
      'title': 'Smart Management',
      'desc': 'Digitalize appointments, records, and reports in one click.',
      'icon': '📊'
    },
    {
      'title': 'Trusted Partnership',
      'desc': 'Join India\'s fastest growing healthcare network for partners.',
      'icon': '🤝'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBenefitCycle();
    _navigateToLogin();
  }

  _startBenefitCycle() async {
    for (int i = 0; i < _benefits.length; i++) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() {
          _currentBenefitIndex = (i + 1) % _benefits.length;
        });
      }
    }
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 8)); // Longer splash to show benefits
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with subtle pattern
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),
          
          // Subtle background circles for depth
          Positioned(
            top: -100,
            right: -100,
            child: _buildBackgroundCircle(300, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBackgroundCircle(200, Colors.white.withOpacity(0.05)),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo Section
                ZoomIn(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppAssets.logo,
                      height: 100,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Brand Name
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        'DOCTORWALA',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 100,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent],
                          ),
                        ),
                      ),
                      Text(
                        'P A R T N E R   P A N E L',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Marketing / Benefits Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  height: 180,
                  child: FadeInUp(
                    key: ValueKey(_currentBenefitIndex),
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      children: [
                        Text(
                          _benefits[_currentBenefitIndex]['icon']!,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _benefits[_currentBenefitIndex]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _benefits[_currentBenefitIndex]['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _benefits.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentBenefitIndex == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentBenefitIndex == index ? AppColors.accent : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Bottom loading text
                FadeIn(
                  delay: const Duration(milliseconds: 1500),
                  child: Text(
                    'Initializing Premium Partner Tools...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
