import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isClinic;
  const LoginScreen({super.key, this.isClinic = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  int _currentCarouselIndex = 0;
  late AnimationController _floatController;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'title': 'Manage Your\nPractice Smartly',
      'subtitle': 'Appointments, Patients,\nReports & More',
      'image': AppAssets.illustration, 
      'color': const Color(0xFFF0F9F8), 
    },
    {
      'title': 'Grow Your\nPractice With Us',
      'subtitle': 'Reach More Patients,\nBuild Trust',
      'image': AppAssets.growth,
      'color': const Color(0xFFF0F7FF),
    },
    {
      'title': 'Lab Automation\nMade Easy',
      'subtitle': 'Digitalize Pathology &\nLab reports',
      'image': AppAssets.carouselLab,
      'color': const Color(0xFFF9F0FF),
    },
  ];

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BOTTOM FIXED DESIGN
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color: AppColors.waveBlue.withValues(alpha: 0.4),
            ),
          ),
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

          // FLOATING LOGO - TOP RIGHT (Same as Splash)
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
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // HEADER
                    FadeInDown(
                      child: Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                                letterSpacing: -0.8,
                              ),
                              children: [
                                TextSpan(text: widget.isClinic ? 'Clinic ' : 'Doctor '),
                                TextSpan(
                                  text: 'Partner',
                                  style: TextStyle(color: AppColors.teal),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isClinic
                                ? 'DOCTOR CHAMBER & PATHOLOGY CLINICS PORTAL'
                                : 'INDIVIDUAL DOCTORS CONSULTATION PORTAL',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CAROUSEL
                    FadeIn(
                      delay: const Duration(milliseconds: 300),
                      child: CarouselSlider(
                        options: CarouselOptions(
                          height: 155,
                          viewportFraction: 0.88,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                        ),
                        items: _carouselItems.map((item) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  item['color'],
                                  (item['color'] as Color).withValues(alpha: 0.55),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navy,
                                          height: 1.25,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        item['subtitle'],
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Image.asset(item['image'], fit: BoxFit.contain),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // INDICATORS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _carouselItems.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentCarouselIndex == index ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: _currentCarouselIndex == index
                                ? AppColors.teal
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // FORM SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInputField(
                            controller: _emailController,
                            label: 'Mobile Number / Email ID',
                            hint: 'Enter mobile number or email',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 18),
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            icon: Icons.lock_person_outlined,
                            isPassword: true,
                            isObscure: _isObscure,
                            onToggle: () => setState(() => _isObscure = !_isObscure),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          _buildLoginButton(),
                          
                          const SizedBox(height: 25),
                          
                          // REGISTER CTA - Moved right after Login button
                          FadeInUp(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Create Account",
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Bottom padding for footer
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy.withValues(alpha: 0.85),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: GoogleFonts.manrope(
              fontSize: 15, 
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                color: Colors.grey[400], 
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.getStartedGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {},
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
              'Login',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
