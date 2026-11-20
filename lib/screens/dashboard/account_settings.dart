import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import '../login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const AccountSettingsScreen({
    super.key,
    required this.partnerData,
    required this.onProfileUpdated,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.partnerData;
    _mobileController = TextEditingController(
      text: data['partner_mobile_number']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: data['partner_email']?.toString() ?? '',
    );
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitUpdate() async {
    final mobileText = _mobileController.text.trim();
    final emailText = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validate Mobile
    if (mobileText.isEmpty) {
      CustomAlerts.showError(context, 'Please enter your mobile number');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobileText)) {
      CustomAlerts.showError(context, 'Mobile number must be a valid 10-digit number');
      return;
    }

    // 2. Validate Email
    if (emailText.isEmpty) {
      CustomAlerts.showError(context, 'Please enter your email address');
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailText)) {
      CustomAlerts.showError(context, 'Please enter a valid email address');
      return;
    }

    // 3. Validate Password if filled
    if (newPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        CustomAlerts.showError(context, 'New password must be at least 6 characters');
        return;
      }
      if (newPassword != confirmPassword) {
        CustomAlerts.showError(context, 'New password and Confirm password do not match');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          CustomAlerts.showError(context, 'Session expired. Please log in again.');
        }
        return;
      }

      final data = widget.partnerData;
      final response = await ApiService.updateProfile(
        token: token,
        clinicName: data['partner_clinic_name']?.toString() ?? '',
        contactPerson: data['partner_contact_person_name']?.toString() ?? '',
        mobileNumber: mobileText,
        email: emailText,
        state: data['partner_state']?.toString() ?? 'West Bengal',
        city: data['partner_city']?.toString() ?? '',
        pincode: data['partner_pincode']?.toString() ?? '',
        landmark: data['partner_landmark']?.toString() ?? '',
        address: data['partner_address']?.toString() ?? '',
        password: newPassword.isNotEmpty ? newPassword : null,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['success'] == true || response['status'] == true) {
        final updatedPartner = response['partner'] as Map<String, dynamic>;

        await SessionManager.updatePartnerData(updatedPartner);
        widget.onProfileUpdated(updatedPartner);

        if (mounted) {
          CustomAlerts.showSuccess(
            context,
            response['message'] ?? 'Account settings updated successfully!',
          );
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      } else {
        String errorMessage = response['message'] ?? 'Failed to update account settings.';
        if (response['errors'] != null && response['errors'] is Map) {
          final errors = response['errors'] as Map;
          final firstErrorList = errors.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            errorMessage = firstErrorList.first.toString();
          }
        }
        CustomAlerts.showError(context, errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      CustomAlerts.showError(context, 'An unexpected error occurred. Please try again.');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your partner account?',
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SessionManager.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = widget.partnerData['partner_clinic_name']?.toString() ??
        widget.partnerData['partner_contact_person_name']?.toString() ??
        'Partner Account';
    final partnerId = widget.partnerData['partner_id']?.toString() ?? 'N/A';
    final representative = widget.partnerData['partner_contact_person_name']?.toString() ?? '';
    final city = widget.partnerData['partner_city']?.toString() ?? '';
    final state = widget.partnerData['partner_state']?.toString() ?? '';
    final pincode = widget.partnerData['partner_pincode']?.toString() ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
      ),
      child: FadeInUp(
        duration: const Duration(milliseconds: 320),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP PARTNER PROFILE HEADER & LOGOUT
              _buildTopProfileCard(clinicName, partnerId, representative),
              const SizedBox(height: 12),

              // 2. COMPACT CREDENTIALS & SECURITY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.blueGrey.withAlpha(22),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.teal,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Account Credentials',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Field 1: Mobile Number
                    _buildCompactField(
                      label: 'Mobile Number',
                      controller: _mobileController,
                      hint: '10-digit mobile number',
                      icon: Icons.phone_android_rounded,
                      isRequired: true,
                      prefixText: '+91 ',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Field 2: Email ID
                    _buildCompactField(
                      label: 'Email Address',
                      controller: _emailController,
                      hint: 'partner@example.com',
                      icon: Icons.alternate_email_rounded,
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // Sub-divider for password
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF64748B),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Password Change',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(leave blank if unchanged)',
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Field 3: New Password
                    _buildCompactField(
                      label: 'New Password',
                      controller: _newPasswordController,
                      hint: 'Min. 8 characters',
                      icon: Icons.key_rounded,
                      obscureText: _isNewPasswordObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordObscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 17,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordObscure = !_isNewPasswordObscure;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Field 4: Confirm Password
                    _buildCompactField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      hint: 'Re-enter new password',
                      icon: Icons.lock_rounded,
                      obscureText: _isConfirmPasswordObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 17,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Changes Button
                    _buildSaveButton(),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. READ-ONLY FACILITY SNAPSHOT CARD
              _buildFacilitySnapshotCard(
                clinicName: clinicName,
                representative: representative,
                location: [city, state, pincode].where((s) => s.isNotEmpty).join(', '),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPACT WIDGET BUILDERS ---

  Widget _buildTopProfileCard(String clinicName, String partnerId, String representative) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withAlpha(22), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4F46E5).withAlpha(15),
              border: Border.all(
                color: const Color(0xFF4F46E5).withAlpha(30),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.medical_services_rounded,
                color: Color(0xFF4F46E5),
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clinicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'ID: $partnerId',
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    if (representative.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• $representative',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 0.9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    size: 13.5,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    'Logout',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
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

  Widget _buildCompactField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    String? prefixText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.5),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 16.5),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.getStartedGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withAlpha(45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 17),
                    const SizedBox(width: 6),
                    Text(
                      'Save Changes',
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFacilitySnapshotCard({
    required String clinicName,
    required String representative,
    required String location,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 5),
              Text(
                'Registered Practice Snapshot',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSnapshotRow('Facility Name', clinicName),
          if (representative.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSnapshotRow('Representative', representative),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSnapshotRow('Location', location),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.7),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 13.5),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'To update your clinic name, medical license, or address, please contact Support.',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            key,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
