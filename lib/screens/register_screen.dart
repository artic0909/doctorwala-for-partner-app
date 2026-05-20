import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/app_assets.dart';
import '../core/api_service.dart';
import '../core/session_manager.dart';
import 'login_screen.dart';
import 'coupon_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 1; // 1: Type Selection, 2: Form Details
  String _selectedType = 'clinic'; // 'clinic', 'lab', 'doctor', 'both'
  late AnimationController _floatController;

  // Form Controllers
  final _clinicNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaInputController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _selectedState;
  String _captchaText = '';

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _generateCaptcha();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _clinicNameController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _captchaInputController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
      _captchaInputController.clear();
    });
  }

  void _submitRegistration() async {
    // Basic field validation
    if (_clinicNameController.text.trim().isEmpty ||
        _contactPersonController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _selectedState == null ||
        _cityController.text.trim().isEmpty ||
        _pinCodeController.text.trim().isEmpty ||
        _landmarkController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields marked with *',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validate Mobile Number
    final mobileText = _mobileController.text.trim();
    if (!RegExp(r'^\d{10,}$').hasMatch(mobileText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mobile number must be at least 10 digits',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validate Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid email address',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validate Pincode
    final pincodeText = _pinCodeController.text.trim();
    if (!RegExp(r'^\d{5,}$').hasMatch(pincodeText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pincode must be at least 5 digits',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validate Captcha
    if (_captchaInputController.text.trim() != _captchaText) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Incorrect Captcha! Please try again.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      _generateCaptcha();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.register(
        clinicName: _clinicNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        state: _selectedState!,
        city: _cityController.text.trim(),
        pincode: _pinCodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        address: _addressController.text.trim(),
        password: _passwordController.text.trim(),
        clientCategory: _selectedType,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {
        // Save persistent session locally
        await SessionManager.saveSession(
          token: response['token'] ?? '',
          partnerData: response['partner'] as Map<String, dynamic>,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Registration successful!',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.teal,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CouponScreen(
              partnerData: response['partner'],
              token: response['token'] ?? '',
            ),
          ),
        );
      } else {
        // Handle validation errors from backend
        String errorMessage = response['message'] ?? 'Registration failed.';
        if (response['errors'] != null && response['errors'] is Map) {
          final errors = response['errors'] as Map;
          final firstErrorList = errors.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            errorMessage = firstErrorList.first.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
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
          content: Text(
            'An unexpected error occurred. Please try again.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(1, 'Type Selection', _currentStep >= 1),
        Container(
          width: 50,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _currentStep >= 2 ? AppColors.teal : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        _buildStepDot(2, 'Details Form', _currentStep >= 2),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.teal : Colors.white,
            border: Border.all(
              color: isActive ? AppColors.teal : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.navy : Colors.grey[400],
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.teal : Colors.grey[200]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Circular Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.teal.withValues(alpha: 0.15) 
                    : Colors.grey[50]!,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.teal : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.65) 
                          : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Circular Checkmark Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.teal : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.teal : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.manrope(
          fontSize: 14, 
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
          prefixIcon: Icon(icon, color: AppColors.teal, size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.map_rounded, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Select State *',
                style: GoogleFonts.manrope(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.teal, size: 28),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          items: _states.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCaptchaBox() {
    return Row(
      children: [
        // Textured Captcha Graphic Block
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!, width: 1.2),
            ),
            child: Stack(
              children: [
                // Render custom intersecting lines/dots noise on top
                Positioned.fill(
                  child: CustomPaint(
                    painter: CaptchaNoisePainter(),
                  ),
                ),
                Center(
                  child: Text(
                    _captchaText,
                    style: GoogleFonts.specialElite(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      letterSpacing: 4.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Refresh Captcha Button
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal, size: 22),
            onPressed: _generateCaptcha,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Accent Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[100]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.teal, size: 20),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Section Contents
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormTitle() {
    switch (_selectedType) {
      case 'clinic':
        return 'Chamber Partner';
      case 'lab':
        return 'Laboratory Partner';
      case 'doctor':
        return 'Doctor Partner';
      case 'both':
      default:
        return 'Medical Partner';
    }
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

          // SafeArea Scrollable View
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
                    children: [
                      const SizedBox(height: 70), // Header spacing

                      // Stepper Bar
                      FadeInDown(
                        duration: const Duration(milliseconds: 400),
                        child: _buildStepIndicator(),
                      ),

                      const SizedBox(height: 25),

                      // MULTI-STEP RENDERER
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 1 
                            ? _buildSelectionStep() 
                            : _buildFormStep(),
                      ),
                      
                      const SizedBox(height: 120), // Bottom scroll spacing
                    ],
                  ),
                ),
              ),
            ),
          ),

          // TOP NAVIGATION HEADER WITH BACK BUTTON & FLOATING LOGO (Placed last in Stack to receive click events)
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            left: 15,
            right: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentStep > 1) {
                      setState(() {
                        _currentStep = 1;
                      });
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: TYPE SELECTION WIDGETS
  Widget _buildSelectionStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        FadeInLeft(
          child: Column(
            children: [
              Text(
                'Choose Partner Type',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the category that best describes your healthcare facility',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        FadeInUp(
          child: Column(
            children: [
              _buildTypeCard(
                id: 'clinic',
                title: 'Doctors Chamber',
                description: 'Manage clinical chambers where doctors consult patients and provide healthcare checkups.',
                icon: Icons.apartment_rounded,
              ),
              _buildTypeCard(
                id: 'lab',
                title: 'Pathology Lab',
                description: 'Manage diagnostic laboratories conducting blood tests, pathology & clinical reporting.',
                icon: Icons.science_rounded,
              ),
              _buildTypeCard(
                id: 'doctor',
                title: 'Individual Doctor',
                description: 'For independent medical specialists, private practitioners, or consultants.',
                icon: Icons.person_pin_rounded,
              ),
              _buildTypeCard(
                id: 'both',
                title: 'Doctor Chamber & Pathology Both',
                description: 'Manage integrated clinics offering both expert doctor consultations and diagnostic testing in one center.',
                icon: Icons.domain_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // CONTINUE BUTTON
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.getStartedGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 2;
                });
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
                    'Continue',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: REGISTRATION ACCOUNT FORM
  Widget _buildFormStep() {
    final title = _getFormTitle();
    final nameLabel = _selectedType == 'doctor' ? 'Doctor Name *' : 'Clinic / Lab Name *';

    return Column(
      key: const ValueKey(2),
      children: [
        FadeInLeft(
          child: Column(
            children: [
              Text(
                'PARTNER ACCOUNT',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        FadeInUp(
          child: Column(
            children: [
              // Section 1: Basic Information
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildFormInput(
                    controller: _clinicNameController,
                    hint: nameLabel,
                    icon: _selectedType == 'doctor' ? Icons.person_rounded : Icons.apartment_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _contactPersonController,
                    hint: 'Contact Person *',
                    icon: Icons.face_rounded,
                  ),
                ],
              ),

              // Section 2: Contact Details
              _buildSectionCard(
                title: 'Contact Details',
                icon: Icons.contact_phone_rounded,
                children: [
                  _buildFormInput(
                    controller: _mobileController,
                    hint: 'Mobile Number *',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _emailController,
                    hint: 'Email ID *',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),

              // Section 3: Location Details
              _buildSectionCard(
                title: 'Location Details',
                icon: Icons.location_on_rounded,
                children: [
                  _buildStateDropdown(),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _cityController,
                    hint: 'City *',
                    icon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _pinCodeController,
                    hint: 'Pin Code *',
                    icon: Icons.pin_drop_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _landmarkController,
                    hint: 'Landmark *',
                    icon: Icons.assistant_navigation,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _addressController,
                    hint: 'Full Address *',
                    icon: Icons.home_work_outlined,
                    maxLines: 3,
                  ),
                ],
              ),

              // Section 4: Security & Verification
              _buildSectionCard(
                title: 'Security & Verification',
                icon: Icons.security_rounded,
                children: [
                  _buildFormInput(
                    controller: _passwordController,
                    hint: 'Password *',
                    icon: Icons.lock_person_outlined,
                    isPassword: true,
                    isObscure: _isObscure,
                    onToggle: () => setState(() => _isObscure = !_isObscure),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptchaBox(),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _captchaInputController,
                    hint: 'Enter Captcha *',
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SUBMIT BUTTON
              Container(
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
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
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
                              'Register Now',
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Painter for generating lines/dots textures on top of Captcha text to mimic secure Captchas
class CaptchaNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final random = Random();
    
    // Draw 4 random noise lines crossing the captcha area
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        paint,
      );
    }
    
    // Draw 20 random noise dots scattered across the captcha box
    final dotPaint = Paint()
      ..color = Colors.grey[400]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        1.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
