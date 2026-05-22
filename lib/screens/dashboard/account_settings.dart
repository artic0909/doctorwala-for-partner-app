import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

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

  // Form Controllers
  late TextEditingController _clinicNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _pinCodeController;
  late TextEditingController _landmarkController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;

  bool _isObscure = true;
  bool _isLoading = false;
  String? _selectedState;

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
    final data = widget.partnerData;
    _clinicNameController = TextEditingController(text: data['partner_clinic_name']?.toString() ?? '');
    _contactPersonController = TextEditingController(text: data['partner_contact_person_name']?.toString() ?? '');
    _mobileController = TextEditingController(text: data['partner_mobile_number']?.toString() ?? '');
    _emailController = TextEditingController(text: data['partner_email']?.toString() ?? '');
    _cityController = TextEditingController(text: data['partner_city']?.toString() ?? '');
    _pinCodeController = TextEditingController(text: data['partner_pincode']?.toString() ?? '');
    _landmarkController = TextEditingController(text: data['partner_landmark']?.toString() ?? '');
    _addressController = TextEditingController(text: data['partner_address']?.toString() ?? '');
    _passwordController = TextEditingController();

    final dbState = data['partner_state']?.toString().trim();
    if (dbState != null && _states.contains(dbState)) {
      _selectedState = dbState;
    } else {
      // Find matching state case-insensitive
      _selectedState = _states.firstWhere(
        (s) => s.toLowerCase() == dbState?.toLowerCase(),
        orElse: () => _states.first,
      );
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitUpdate() async {
    // Client-side fields validation
    if (_clinicNameController.text.trim().isEmpty ||
        _contactPersonController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _selectedState == null ||
        _cityController.text.trim().isEmpty ||
        _pinCodeController.text.trim().isEmpty ||
        _landmarkController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      CustomAlerts.showError(context, 'Please fill in all required fields marked with *');
      return;
    }

    // Validate Mobile Number
    final mobileText = _mobileController.text.trim();
    if (!RegExp(r'^\d{10,}$').hasMatch(mobileText)) {
      CustomAlerts.showError(context, 'Mobile number must be at least 10 digits');
      return;
    }

    // Validate Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      CustomAlerts.showError(context, 'Please enter a valid email address');
      return;
    }

    // Validate Pincode
    final pincodeText = _pinCodeController.text.trim();
    if (!RegExp(r'^\d{5,}$').hasMatch(pincodeText)) {
      CustomAlerts.showError(context, 'Pincode must be at least 5 digits');
      return;
    }

    // Validate Password if filled
    if (_passwordController.text.isNotEmpty && _passwordController.text.length < 6) {
      CustomAlerts.showError(context, 'New password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CustomAlerts.showError(context, 'Authentication session expired. Please login again.');
        }
        return;
      }

      final response = await ApiService.updateProfile(
        token: token,
        clinicName: _clinicNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        state: _selectedState!,
        city: _cityController.text.trim(),
        pincode: _pinCodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        address: _addressController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text.trim() : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response['success'] == true || response['status'] == true) {
        final updatedPartner = response['partner'] as Map<String, dynamic>;
        
        // Update persistent session details
        await SessionManager.updatePartnerData(updatedPartner);
        
        // Trigger callback to update dashboard state
        widget.onProfileUpdated(updatedPartner);

        if (mounted) {
          CustomAlerts.showSuccess(context, response['message'] ?? 'Profile updated successfully!');
          _passwordController.clear();
        }
      } else {
        // Handle validation errors from backend
        String errorMessage = response['message'] ?? 'Profile update failed.';
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
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      CustomAlerts.showError(context, 'An unexpected error occurred. Please try again.');
    }
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

  @override
  Widget build(BuildContext context) {
    // Check registration type to dynamicize the first label
    final regType = widget.partnerData['registration_type']?.toString().toLowerCase() ?? '';
    final isDoctor = regType.contains('doctor');
    final nameLabel = isDoctor ? 'Doctor Name *' : 'Clinic / Lab Name *';

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Form(
              key: _formKey,
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
                        icon: isDoctor ? Icons.person_rounded : Icons.apartment_rounded,
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

                  // Section 4: Security (Password Update)
                  _buildSectionCard(
                    title: 'Security Settings',
                    icon: Icons.lock_outline_rounded,
                    children: [
                      _buildFormInput(
                        controller: _passwordController,
                        hint: 'New Password (leave blank if unchanged)',
                        icon: Icons.key_rounded,
                        isPassword: true,
                        isObscure: _isObscure,
                        onToggle: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Save Changes Button
                  Container(
                    width: double.infinity,
                    height: 56,
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
                      onPressed: _isLoading ? null : _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save Changes',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
