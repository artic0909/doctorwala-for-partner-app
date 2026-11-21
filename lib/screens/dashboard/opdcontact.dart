import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';
import '../../core/state_picker_modal.dart';
import '../../widgets/partner_skeleton_loader.dart';

class OpdContactScreen extends StatefulWidget {
  const OpdContactScreen({super.key});

  @override
  State<OpdContactScreen> createState() => _OpdContactScreenState();
}

class _OpdContactScreenState extends State<OpdContactScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = true;

  String? _serverBannerUrl;
  String? _localBannerPath;

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
  String? _selectedRegType = 'OPD';

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

      final partnerData = await SessionManager.getPartnerData();

      final response = await ApiService.getClinicProfile(
        type: 'opd',
        token: token,
      );

      if (response['success'] == true && response['contact_details'] != null) {
        final data = response['contact_details'] as Map<String, dynamic>;
        setState(() {
          _serverBannerUrl = response['opd_banner'];
          _clinicNameController.text = (data['clinic_name'] != null && data['clinic_name'].toString().isNotEmpty)
              ? data['clinic_name'].toString()
              : (partnerData?['partner_clinic_name']?.toString() ?? '');

          _contactPersonController.text = (data['clinic_contact_person_name'] != null && data['clinic_contact_person_name'].toString().isNotEmpty)
              ? data['clinic_contact_person_name'].toString()
              : (partnerData?['partner_contact_person_name']?.toString() ?? '');

          _gstinController.text = data['clinic_gstin'] ?? '';

          _mobileController.text = (data['clinic_mobile_number'] != null && data['clinic_mobile_number'].toString().isNotEmpty)
              ? data['clinic_mobile_number'].toString()
              : (partnerData?['partner_mobile_number']?.toString() ?? '');

          _emailController.text = (data['clinic_email'] != null && data['clinic_email'].toString().isNotEmpty)
              ? data['clinic_email'].toString()
              : (partnerData?['partner_email']?.toString() ?? '');

          _cityController.text = (data['clinic_city'] != null && data['clinic_city'].toString().isNotEmpty)
              ? data['clinic_city'].toString()
              : (partnerData?['partner_city']?.toString() ?? '');

          _pinCodeController.text = (data['clinic_pincode'] != null && data['clinic_pincode'].toString().isNotEmpty)
              ? data['clinic_pincode'].toString()
              : (partnerData?['partner_pincode']?.toString() ?? '');

          _landmarkController.text = (data['clinic_landmark'] != null && data['clinic_landmark'].toString().isNotEmpty)
              ? data['clinic_landmark'].toString()
              : (partnerData?['partner_landmark']?.toString() ?? '');

          _googleMapController.text = data['clinic_google_map_link'] ?? '';

          _addressController.text = (data['clinic_address'] != null && data['clinic_address'].toString().isNotEmpty)
              ? data['clinic_address'].toString()
              : (partnerData?['partner_address']?.toString() ?? '');
          
          final fetchedState = (data['clinic_state'] != null && data['clinic_state'].toString().isNotEmpty)
              ? data['clinic_state'].toString().trim()
              : (partnerData?['partner_state']?.toString().trim());

          if (fetchedState != null && _states.contains(fetchedState)) {
            _selectedState = fetchedState;
          }

          final fetchedRegType = data['clinic_registration_type']?.toString().trim();
          if (fetchedRegType != null && _regTypes.contains(fetchedRegType)) {
            _selectedRegType = fetchedRegType;
          }

          final banner = response['opd_banner'] ?? data['opd_banner'];
          final mapLink = (data['clinic_google_map_link'] ?? '').toString().trim();
          final name = (data['clinic_name'] ?? '').toString().trim();
          final person = (data['clinic_contact_person_name'] ?? '').toString().trim();
          final mobile = (data['clinic_mobile_number'] ?? '').toString().trim();
          final addr = (data['clinic_address'] ?? '').toString().trim();
          final state = (data['clinic_state'] ?? '').toString().trim();
          final city = (data['clinic_city'] ?? '').toString().trim();
          final pin = (data['clinic_pincode'] ?? '').toString().trim();

          final bool hasBanner = banner != null && banner.toString().trim().isNotEmpty;
          final bool hasMap = mapLink.isNotEmpty;
          final bool hasInfo = name.isNotEmpty && person.isNotEmpty;
          final bool hasAddr = addr.isNotEmpty && state.isNotEmpty && city.isNotEmpty && pin.isNotEmpty;

          SharedPreferences.getInstance().then((prefs) {
            final pid = partnerData?['id']?.toString() ?? 'default';
            prefs.setBool('has_opd_info_$pid', hasInfo && mobile.isNotEmpty);
            prefs.setBool('has_opd_addr_$pid', hasAddr);
            prefs.setBool('has_opd_map_$pid', hasMap);
            prefs.setBool('has_opd_banner_$pid', hasBanner);
            prefs.setBool('opd_contact_saved_$pid', hasInfo && mobile.isNotEmpty && hasAddr && hasMap && hasBanner);
          });
        });
      } else {
        if (partnerData != null) {
          setState(() {
            _clinicNameController.text = partnerData['partner_clinic_name']?.toString() ?? '';
            _contactPersonController.text = partnerData['partner_contact_person_name']?.toString() ?? '';
            _mobileController.text = partnerData['partner_mobile_number']?.toString() ?? '';
            _emailController.text = partnerData['partner_email']?.toString() ?? '';
            _cityController.text = partnerData['partner_city']?.toString() ?? '';
            _pinCodeController.text = partnerData['partner_pincode']?.toString() ?? '';
            _landmarkController.text = partnerData['partner_landmark']?.toString() ?? '';
            _addressController.text = partnerData['partner_address']?.toString() ?? '';

            final state = partnerData['partner_state']?.toString().trim();
            if (state != null && _states.contains(state)) {
              _selectedState = state;
            }
          });
        }
      }
    } catch (_) {
      // Quietly ignore
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _submitForm() async {
    if (_selectedRegType == null) {
      CustomAlerts.showError(context, 'Please select a Clinic Registration Type');
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
        type: 'opd',
        body: body,
        token: token,
        imageKey: 'opdbanner',
        imagePath: _localBannerPath,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final pData = await SessionManager.getPartnerData();
        final pid = pData?['id']?.toString() ?? 'default';

        final bool hasBanner = _localBannerPath != null ||
            (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty) ||
            (response['opd_banner'] != null && response['opd_banner'].toString().isNotEmpty);
        final bool hasMap = _googleMapController.text.trim().isNotEmpty;
        final bool hasInfo = _clinicNameController.text.trim().isNotEmpty &&
            _contactPersonController.text.trim().isNotEmpty &&
            _selectedRegType != null;
        final bool hasContact = _mobileController.text.trim().isNotEmpty;
        final bool hasAddr = _addressController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _pinCodeController.text.trim().isNotEmpty &&
            _selectedState != null;

        final bool isFullyDone = hasInfo && hasContact && hasAddr && hasMap && hasBanner;

        await prefs.setBool('has_opd_info_$pid', hasInfo && hasContact);
        await prefs.setBool('has_opd_contact_$pid', hasContact);
        await prefs.setBool('has_opd_addr_$pid', hasAddr);
        await prefs.setBool('has_opd_map_$pid', hasMap);
        await prefs.setBool('has_opd_banner_$pid', hasBanner);
        await prefs.setBool('opd_contact_saved_$pid', isFullyDone);

        if (!mounted) return;
        CustomAlerts.showSuccessLoader(context, response['message'] ?? 'OPD details saved successfully!');
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
        backgroundColor: AppColors.background,
        body: PartnerFormProfileSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Doctor Chamber Setup',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FadeInDown(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  'Complete your doctor chamber clinic profile details below',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Banner Image Upload Card
              FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: _buildBannerUploadCard(),
              ),

              // Section 1: Clinic Profile Types
              FadeInUp(
                duration: const Duration(milliseconds: 360),
                child: _buildSectionCard(
                  title: 'Clinic Information',
                  icon: Icons.apartment_rounded,
                  iconColor: const Color(0xFF0D9488),
                  children: [
                    _buildCompactField(
                      label: 'Clinic Name',
                      controller: _clinicNameController,
                      hint: 'Enter clinic name',
                      icon: Icons.apartment_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Contact Person Name',
                      controller: _contactPersonController,
                      hint: 'Enter contact person name',
                      icon: Icons.person_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Clinic GSTIN',
                      controller: _gstinController,
                      hint: 'Enter GSTIN (Optional)',
                      icon: Icons.receipt_long_rounded,
                      isRequired: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 2: Contact Details
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: _buildSectionCard(
                  title: 'Contact Details',
                  icon: Icons.contact_phone_rounded,
                  iconColor: const Color(0xFF0284C7),
                  children: [
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
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Email Address',
                      controller: _emailController,
                      hint: 'clinic@example.com',
                      icon: Icons.alternate_email_rounded,
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 3: Location Details
              FadeInUp(
                duration: const Duration(milliseconds: 440),
                child: _buildSectionCard(
                  title: 'Location & Address',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFE11D48),
                  children: [
                    _buildStateDropdown(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactField(
                            label: 'City',
                            controller: _cityController,
                            hint: 'Enter city',
                            icon: Icons.location_city_rounded,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactField(
                            label: 'Pin Code',
                            controller: _pinCodeController,
                            hint: '6-digit pincode',
                            icon: Icons.pin_drop_rounded,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Landmark',
                      controller: _landmarkController,
                      hint: 'Nearby landmark / road',
                      icon: Icons.assistant_navigation,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Google Map Link',
                      controller: _googleMapController,
                      hint: 'https://maps.google.com/?q=... (Required for 100%)',
                      icon: Icons.map_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Full Address',
                      controller: _addressController,
                      hint: 'Premises, building, street address',
                      icon: Icons.home_work_outlined,
                      isRequired: true,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SUBMIT BUTTON
              FadeInUp(
                duration: const Duration(milliseconds: 480),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isLoading ? 'Saving...' : 'Save Chamber Details',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF0D9488),
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withAlpha(15),
                  border: Border.all(
                    color: iconColor.withAlpha(30),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
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
    int maxLines = 1,
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
          height: maxLines == 1 ? 42 : null,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 17),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
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

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'State / UT',
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
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
        InkWell(
          onTap: () async {
            final chosen = await showSearchableStatePicker(
              context: context,
              currentState: _selectedState,
              states: _states,
            );
            if (chosen != null) {
              setState(() {
                _selectedState = chosen;
              });
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedState != null
                    ? AppColors.teal.withAlpha(140)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  color: Color(0xFF64748B),
                  size: 16.5,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedState ?? 'Select State / Union Territory',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: _selectedState != null ? FontWeight.w600 : FontWeight.w500,
                      color: _selectedState != null ? AppColors.navy : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerUploadCard() {
    Widget imageWidget;
    if (_localBannerPath != null) {
      imageWidget = Image.file(
        File(_localBannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
      );
    } else if (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _serverBannerUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
          );
        },
      );
    } else {
      imageWidget = Container(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: AppColors.teal.withValues(alpha: 0.8), size: 34),
              const SizedBox(height: 6),
              Text(
                'Upload Chamber Banner Image',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG, WebP (Required for 100%)',
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withAlpha(15),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withAlpha(30),
                    width: 1.0,
                  ),
                ),
                child: const Icon(Icons.image_rounded, color: Color(0xFF0D9488), size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                'Chamber Banner Image',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showImageSourceBottomSheet,
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    if (_localBannerPath != null || (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty))
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Change',
                                style: GoogleFonts.manrope(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageSourceBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Select Image Source',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.teal),
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickBannerImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.teal),
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickBannerImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickBannerImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _localBannerPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomAlerts.showError(context, 'Failed to pick image. Please try again.');
      }
    }
  }
}
