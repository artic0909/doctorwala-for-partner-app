import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/api_service.dart';
import 'dashboard/dashboard.dart';
import '../core/session_manager.dart';

class CouponScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final String token;

  const CouponScreen({super.key, required this.partnerData, required this.token});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  // Form controllers
  final _partnerIdController = TextEditingController();
  final _couponController = TextEditingController();
  final _amountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  bool _isAdding = false;
  bool _isActivating = false;
  bool _isCouponApplied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fetch numeric database ID or string partner_id
    final rawId = widget.partnerData['id']?.toString() ?? '1676';
    _partnerIdController.text = rawId;
  }

  @override
  void dispose() {
    _partnerIdController.dispose();
    _couponController.dispose();
    _amountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _applyCouponCode() async {
    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a coupon code first.';
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
          _amountController.text = couponData['coupon_amount']?.toString() ?? '1000';
          _startDateController.text = couponData['coupon_start_date']?.toString() ?? '2026-04-10';
          _endDateController.text = couponData['coupon_end_date']?.toString() ?? '2027-05-10';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon verified successfully!',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Invalid Coupon Code. Try "DWCPNFREE01"';
        });
      }
    } catch (e) {
      setState(() {
        _isAdding = false;
        _errorMessage = 'Connection error. Please try again.';
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
        amount: _amountController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
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
              'Subscription activated! Redirecting...',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.teal,
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
              response['message'] ?? 'Failed to activate coupon.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
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
            'Connection error. Please try again.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    bool isCouponField = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Subtle light gray matching the screenshots
        borderRadius: BorderRadius.circular(8), // Standard clean corners from web
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: readOnly ? Colors.grey[600] : AppColors.navy,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.manrope(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          if (isCouponField)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _applyCouponCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626), // Solid bright red matching "Add"
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          'Add',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BRAND BRIGHT BLUE BACKGROUND WITH DOCTOR MASKED WALLPAPER STYLING
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0EA5E9), // Bright brand blue from screens
                  const Color(0xFF0369A1), // Elegant deep royal blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // BOTTOM WAVE ACCENTS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ),

          // Scrollable Form Container
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // HEADER TITLE
                    Center(
                      child: FadeInDown(
                        child: Text(
                          'Make Payments',
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SECTION 1: SUBSCRIBE NOW
                    FadeInUp(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Subscribe Now'),
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626), // Brand red color matching screens
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Coming Soon',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 2: PARTNER ID
                    FadeInUp(
                      delay: const Duration(milliseconds: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Partner ID*'),
                          _buildFormInput(
                            controller: _partnerIdController,
                            hint: 'Partner ID',
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 3: COUPON CODE ENTRY
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Coupon Code (if any)*'),
                          
                          // Suggested Web Code Banner
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _couponController.text = 'DWCPNFREE01';
                                _errorMessage = null;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Write the Code below : " DWCPNFREE01 "',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),

                          _buildFormInput(
                            controller: _couponController,
                            hint: 'Enter Code',
                            isCouponField: true,
                          ),
                        ],
                      ),
                    ),

                    // ERROR BLOCK
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      FadeIn(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.manrope(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // SECTION 4: COUPON CODE AMOUNT
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Coupon Code Amount*'),
                          _buildFormInput(
                            controller: _amountController,
                            hint: 'Waiting for coupon activation...',
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 5: START DATE
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Start Date*'),
                          _buildFormInput(
                            controller: _startDateController,
                            hint: 'YYYY-MM-DD',
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 6: END DATE
                    FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('End Date*'),
                          _buildFormInput(
                            controller: _endDateController,
                            hint: 'YYYY-MM-DD',
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    // SUBMIT CONTINUE BUTTON
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isCouponApplied 
                              ? const Color(0xFFDC2626) // Solid brand-red on code match
                              : const Color(0xFFDC2626).withValues(alpha: 0.6), // Dimmed red when inactive
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isCouponApplied ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: ElevatedButton(
                          onPressed: (_isCouponApplied && !_isActivating) ? _proceedToDashboard : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isActivating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'Continue With Code',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _isCouponApplied 
                                          ? Colors.white 
                                          : Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
