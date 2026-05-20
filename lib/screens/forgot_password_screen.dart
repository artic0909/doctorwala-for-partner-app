import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import '../core/api_service.dart';
import 'package:flutter/services.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Email, 2: OTP & New Password
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.forgotPasswordSendOtp(email: email);
      
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP sent successfully!', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.teal,
          ),
        );
        setState(() {
          _currentStep = 2;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send OTP', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();

    if (otp.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.forgotPasswordReset(
        email: email,
        otp: otp,
        password: password,
      );
      
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset successfully!', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.teal,
          ),
        );
        Navigator.pop(context); // Go back to login screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to reset password', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() {
                _currentStep = 1;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
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

          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // HEADER
                      FadeInDown(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forgot Password?',
                              style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.navy,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentStep == 1
                                  ? 'Enter your registered email address to receive an OTP.'
                                  : 'Enter the OTP sent to your email and your new password.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      if (_currentStep == 1) ...[
                        FadeInUp(
                          child: _buildInputField(
                            controller: _emailController,
                            label: 'Email ID',
                            hint: 'Enter your registered email',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 30),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildActionButton(
                            onPressed: _sendOtp,
                            label: 'Send OTP',
                          ),
                        ),
                      ] else ...[
                        FadeInUp(
                          child: _buildInputField(
                            controller: _otpController,
                            label: 'OTP',
                            hint: 'Enter 4-digit OTP',
                            icon: Icons.message_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildInputField(
                            controller: _passwordController,
                            label: 'New Password',
                            hint: 'Enter new password',
                            icon: Icons.lock_person_outlined,
                            isPassword: true,
                            isObscure: _isObscure,
                            onToggle: () => setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                        const SizedBox(height: 30),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildActionButton(
                            onPressed: _resetPassword,
                            label: 'Reset Password',
                          ),
                        ),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required String label}) {
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
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
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
