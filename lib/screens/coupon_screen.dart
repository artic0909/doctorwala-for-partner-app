import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/api_service.dart';
import '../core/session_manager.dart';
import 'dashboard/dashboard.dart';
import 'login_screen.dart';

class CouponScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final String token;

  const CouponScreen({super.key, required this.partnerData, required this.token});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final _couponController = TextEditingController();
  final _partnerIdController = TextEditingController();

  bool _isAdding = false;
  bool _isActivating = false;
  bool _isCouponApplied = false;
  String? _errorMessage;

  // Coupon response details cached locally for layout
  String _couponAmount = '';
  String _startDate = '';
  String _endDate = '';

  @override
  void initState() {
    super.initState();
    final rawId = widget.partnerData['id']?.toString() ?? '1676';
    _partnerIdController.text = 'Partner ID: #$rawId';
  }

  @override
  void dispose() {
    _couponController.dispose();
    _partnerIdController.dispose();
    super.dispose();
  }

  void _applyCouponCode() async {
    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a voucher code.';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCouponDetails(
        couponCode: code,
        token: widget.token,
      );

      setState(() {
        _isAdding = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final couponData = response['data'];
        setState(() {
          _isCouponApplied = true;
          _couponAmount = couponData['coupon_amount']?.toString() ?? '1000';
          _startDate = couponData['coupon_start_date']?.toString() ?? '2026-04-10';
          _endDate = couponData['coupon_end_date']?.toString() ?? '2027-05-10';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon successfully validated!',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid coupon. Please check and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isAdding = false;
        _errorMessage = 'Server response error. Please try again.';
      });
    }
  }

  void _proceedToDashboard() async {
    if (!_isCouponApplied) return;

    setState(() {
      _isActivating = true;
    });

    try {
      final response = await ApiService.addPartnerCoupon(
        partnerId: widget.partnerData['id']?.toString() ?? '1676',
        couponCode: _couponController.text.trim(),
        amount: _couponAmount,
        startDate: _startDate,
        endDate: _endDate,
        token: widget.token,
      );

      setState(() {
        _isActivating = false;
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final updatedPartner = response['partner'] as Map<String, dynamic>? ?? widget.partnerData;
        await SessionManager.updatePartnerData(updatedPartner);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subscription activated! Welcome to DoctorWala.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(partnerData: updatedPartner),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to complete activation.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isActivating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection timed out. Please try again.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool readOnly = false,
    bool showApplyButton = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.navy.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCouponApplied && !readOnly 
                  ? AppColors.teal 
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(prefixIcon, color: AppColors.teal, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: readOnly ? AppColors.textSecondary : AppColors.navy,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter activation voucher',
                    hintStyle: GoogleFonts.manrope(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (showApplyButton)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: _isAdding || _isCouponApplied ? null : _applyCouponCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isCouponApplied ? 'Verified' : 'Verify',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 18),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.skyBlue,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.navy, size: 14),
                const SizedBox(width: 6),
                Text(
                  'SECURE GATEWAY',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER SECTION
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Your Account',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Activate your partner dashboard to begin managing clinic profiles, consultation bookings, and diagnostic reports.',
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

                const SizedBox(height: 25),

                // PREMIUM SUBSCRIPTION BANNER CARD
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.navy,
                          AppColors.navy.withBlue(120),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'UNLIMITED PARTNER SUITE',
                                  style: GoogleFonts.manrope(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.teal,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Complete Medical Ecosystem',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Gives full access to bookings trackers, patient data records, and administrative settings.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // FORM BLOCK
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Partner ID Field
                        _buildTextField(
                          controller: _partnerIdController,
                          label: 'Assigned Partner ID',
                          prefixIcon: Icons.badge_outlined,
                          readOnly: true,
                        ),

                        const SizedBox(height: 20),

                        // Coupon Input Field
                        _buildTextField(
                          controller: _couponController,
                          label: 'Voucher Activation Code',
                          prefixIcon: Icons.confirmation_number_outlined,
                          showApplyButton: true,
                          readOnly: _isCouponApplied,
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 10),
                          FadeIn(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.manrope(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],

                        // Quick voucher prompt
                        if (!_isCouponApplied) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _couponController.text = 'DWCPNFREE01';
                                _errorMessage = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlue.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.skyBlue),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.navy, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        children: const [
                                          TextSpan(text: 'Quick Activation: Tap to apply '),
                                          TextSpan(
                                            text: '"DWCPNFREE01"',
                                            style: TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
                                          ),
                                          TextSpan(text: ' voucher code.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // VOUCHER DETAIL EXPANSION TICKET
                        if (_isCouponApplied) ...[
                          const SizedBox(height: 24),
                          FadeInDown(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.skyBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.skyBlue, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Voucher Activated',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.teal,
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            '₹$_couponAmount Credit',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    color: AppColors.skyBlue,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'START DATE',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _startDate,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'END DATE',
                                              style: GoogleFonts.manrope(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _endDate,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // CONTINUATION BUTTON
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isCouponApplied && !_isActivating
                          ? AppColors.getStartedGradient
                          : LinearGradient(
                              colors: [
                                AppColors.navy.withValues(alpha: 0.5),
                                AppColors.teal.withValues(alpha: 0.5),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _isCouponApplied && !_isActivating
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _isCouponApplied && !_isActivating ? _proceedToDashboard : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isActivating
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
                                  'Activate Suite & Go to Dashboard',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
