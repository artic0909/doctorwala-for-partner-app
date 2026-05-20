import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class PathologyContactScreen extends StatefulWidget {
  const PathologyContactScreen({super.key});

  @override
  State<PathologyContactScreen> createState() => _PathologyContactScreenState();
}

class _PathologyContactScreenState extends State<PathologyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = true;

  // Form Controllers
  final _clinicNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _gstinController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _googleMapController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedState;
  String? _selectedRegType = 'Pathology';

  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  final List<String> _regTypes = [
    'OPD',
    'Pathology',
    'Doctor',
    'OPD, Pathology'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _contactPersonController.dispose();
    _gstinController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _googleMapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingDetails() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isFetching = false);
        return;
      }

      final response = await ApiService.getClinicProfile(
        type: 'pathology',
        token: token,
      );

      if (response['success'] == true && response['contact_details'] != null) {
        final data = response['contact_details'] as Map<String, dynamic>;
        setState(() {
          _clinicNameController.text = data['clinic_name'] ?? '';
          _contactPersonController.text = data['clinic_contact_person_name'] ?? '';
          _gstinController.text = data['clinic_gstin'] ?? '';
          _mobileController.text = data['clinic_mobile_number'] ?? '';
          _emailController.text = data['clinic_email'] ?? '';
          _cityController.text = data['clinic_city'] ?? '';
          _pinCodeController.text = data['clinic_pincode']?.toString() ?? '';
          _landmarkController.text = data['clinic_landmark'] ?? '';
          _googleMapController.text = data['clinic_google_map_link'] ?? '';
          _addressController.text = data['clinic_address'] ?? '';
          
          final fetchedState = data['clinic_state']?.toString().trim();
          if (fetchedState != null && _states.contains(fetchedState)) {
            _selectedState = fetchedState;
          }

          final fetchedRegType = data['clinic_registration_type']?.toString().trim();
          if (fetchedRegType != null && _regTypes.contains(fetchedRegType)) {
            _selectedRegType = fetchedRegType;
          }
        });
      }
    } catch (_) {
      // Quietly ignore or let the user try saving
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _submitForm() async {
    if (_selectedRegType == null) {
      CustomAlerts.showError(context, 'Please select a Pathology Registration Type');
      return;
    }
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

    final mobileText = _mobileController.text.trim();
    if (!RegExp(r'^\d{10,}$').hasMatch(mobileText)) {
      CustomAlerts.showError(context, 'Mobile number must be at least 10 digits');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      CustomAlerts.showError(context, 'Please enter a valid email address');
      return;
    }

    final pincodeText = _pinCodeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pincodeText)) {
      CustomAlerts.showError(context, 'Pincode must be exactly 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (!mounted) return;
      if (token == null) {
        CustomAlerts.showError(context, 'Session expired. Please log in again.');
        setState(() => _isLoading = false);
        return;
      }

      final body = {
        'clinic_registration_type': _selectedRegType!,
        'clinic_contact_person_name': _contactPersonController.text.trim(),
        'clinic_name': _clinicNameController.text.trim(),
        'clinic_gstin': _gstinController.text.trim(),
        'clinic_mobile_number': _mobileController.text.trim(),
        'clinic_email': _emailController.text.trim(),
        'clinic_landmark': _landmarkController.text.trim(),
        'clinic_pincode': _pinCodeController.text.trim(),
        'clinic_state': _selectedState!,
        'clinic_city': _cityController.text.trim(),
        'clinic_google_map_link': _googleMapController.text.trim(),
        'clinic_address': _addressController.text.trim(),
      };

      final response = await ApiService.storeClinicProfile(
        type: 'pathology',
        body: body,
        token: token,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['success'] == true) {
        CustomAlerts.showSuccessLoader(context, response['message'] ?? 'Pathology details saved successfully!');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context); // Dismiss success loader dialog
      } else {
        String errorMessage = response['message'] ?? 'Failed to save details.';
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

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  'Pathology Clinic Setup',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeInDown(
                duration: const Duration(milliseconds: 450),
                child: Text(
                  'Complete your pathology diagnostic center profile details below',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Section 1: Clinic Profile Types
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: _buildSectionCard(
                  title: 'Laboratory Information',
                  icon: Icons.biotech_rounded,
                  children: [
                    _buildFormInput(
                      controller: _clinicNameController,
                      hint: 'Pathology Name *',
                      icon: Icons.science_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormInput(
                      controller: _contactPersonController,
                      hint: 'Contact Person *',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormInput(
                      controller: _gstinController,
                      hint: 'Pathology GSTIN (Optional)',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ],
                ),
              ),

              // Section 2: Contact Details
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: _buildSectionCard(
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
              ),

              // Section 3: Location Details
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: _buildSectionCard(
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
                      controller: _googleMapController,
                      hint: 'Google Map Link (Optional)',
                      icon: Icons.map_rounded,
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
              ),

              const SizedBox(height: 15),

              // SUBMIT BUTTON
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.getStartedGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                                'Save Pathology Details',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.01),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
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
            color: AppColors.navy.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: TextField(
        controller: controller,
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
            color: AppColors.navy.withValues(alpha: 0.01),
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

}
