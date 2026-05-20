import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class DoctorContactScreen extends StatefulWidget {
  const DoctorContactScreen({super.key});

  @override
  State<DoctorContactScreen> createState() => _DoctorContactScreenState();
}

class _DoctorContactScreenState extends State<DoctorContactScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = true;

  String? _serverBannerUrl;
  String? _localBannerPath;

  // Form Controllers
  final _doctorNameController = TextEditingController();
  final _specialistController = TextEditingController();
  final _designationController = TextEditingController();
  final _feesController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _googleMapController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedState;

  // States List
  final List<String> _states = [
    'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
    'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa',
    'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand', 'Karnataka',
    'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  // Weekdays Schedule State
  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Store selection state for each day
  final Map<String, bool> _activeDays = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};

  @override
  void initState() {
    super.initState();
    // Initialize weekday schedule states with defaults
    for (var day in _weekdays) {
      _activeDays[day] = false;
      _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
      _endTimes[day] = const TimeOfDay(hour: 17, minute: 0);
    }
    _fetchExistingDetails();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialistController.dispose();
    _designationController.dispose();
    _feesController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _googleMapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(BuildContext context, String day, bool isStart) async {
    final initialTime = isStart ? _startTimes[day]! : _endTimes[day]!;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTimes[day] = pickedTime;
        } else {
          _endTimes[day] = pickedTime;
        }
      });
    }
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
        type: 'doctor',
        token: token,
      );

      if (response['success'] == true && response['contact_details'] != null) {
        final data = response['contact_details'] as Map<String, dynamic>;
        setState(() {
          _serverBannerUrl = response['doctor_banner'];
          _doctorNameController.text = (data['partner_doctor_name'] != null && data['partner_doctor_name'].toString().isNotEmpty)
              ? data['partner_doctor_name'].toString()
              : (partnerData?['partner_contact_person_name']?.toString() ?? '');

          _specialistController.text = data['partner_doctor_specialist']?.toString() ?? '';
          _designationController.text = data['partner_doctor_designation']?.toString() ?? '';
          _feesController.text = data['partner_doctor_fees']?.toString() ?? '';

          _mobileController.text = (data['partner_doctor_mobile'] != null && data['partner_doctor_mobile'].toString().isNotEmpty)
              ? data['partner_doctor_mobile'].toString()
              : (partnerData?['partner_mobile_number']?.toString() ?? '');

          _emailController.text = (data['partner_doctor_email'] != null && data['partner_doctor_email'].toString().isNotEmpty)
              ? data['partner_doctor_email'].toString()
              : (partnerData?['partner_email']?.toString() ?? '');

          _cityController.text = (data['partner_doctor_city'] != null && data['partner_doctor_city'].toString().isNotEmpty)
              ? data['partner_doctor_city'].toString()
              : (partnerData?['partner_city']?.toString() ?? '');

          _pinCodeController.text = (data['partner_doctor_pincode'] != null && data['partner_doctor_pincode'].toString().isNotEmpty)
              ? data['partner_doctor_pincode'].toString()
              : (partnerData?['partner_pincode']?.toString() ?? '');

          _landmarkController.text = (data['partner_doctor_landmark'] != null && data['partner_doctor_landmark'].toString().isNotEmpty)
              ? data['partner_doctor_landmark'].toString()
              : (partnerData?['partner_landmark']?.toString() ?? '');

          _googleMapController.text = data['partner_doctor_google_map_link'] ?? '';

          _addressController.text = (data['partner_doctor_address'] != null && data['partner_doctor_address'].toString().isNotEmpty)
              ? data['partner_doctor_address'].toString()
              : (partnerData?['partner_address']?.toString() ?? '');
          
          final fetchedState = (data['partner_doctor_state'] != null && data['partner_doctor_state'].toString().isNotEmpty)
              ? data['partner_doctor_state'].toString().trim()
              : (partnerData?['partner_state']?.toString().trim());

          if (fetchedState != null && _states.contains(fetchedState)) {
            _selectedState = fetchedState;
          }

          // Parse visit days and timings
          if (data['visit_day_time'] != null && data['visit_day_time'] is List) {
            final list = data['visit_day_time'] as List;
            for (var item in list) {
              if (item is Map) {
                final day = item['day']?.toString();
                final startTimeStr = item['start_time']?.toString();
                final endTimeStr = item['end_time']?.toString();

                if (day != null && _weekdays.contains(day)) {
                  _activeDays[day] = true;
                  if (startTimeStr != null && startTimeStr.contains(':')) {
                    final parts = startTimeStr.split(':');
                    _startTimes[day] = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 9,
                      minute: int.tryParse(parts[1]) ?? 0,
                    );
                  }
                  if (endTimeStr != null && endTimeStr.contains(':')) {
                    final parts = endTimeStr.split(':');
                    _endTimes[day] = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 17,
                      minute: int.tryParse(parts[1]) ?? 0,
                    );
                  }
                }
              }
            }
          }
        });
      } else {
        if (partnerData != null) {
          setState(() {
            _doctorNameController.text = partnerData['partner_contact_person_name']?.toString() ?? '';
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
    if (_doctorNameController.text.trim().isEmpty ||
        _specialistController.text.trim().isEmpty ||
        _designationController.text.trim().isEmpty ||
        _feesController.text.trim().isEmpty ||
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

    // Verify schedule: At least one day must be active, and end time must be after start time
    final activeDaysList = _weekdays.where((day) => _activeDays[day] == true).toList();
    if (activeDaysList.isEmpty) {
      CustomAlerts.showError(context, 'Please enable at least one weekday schedule');
      return;
    }

    for (var day in activeDaysList) {
      final start = _startTimes[day]!;
      final end = _endTimes[day]!;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      if (endMinutes <= startMinutes) {
        CustomAlerts.showError(
          context,
          'On $day, the Visit End Time must be after the Visit Start Time.'
        );
        return;
      }
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

      // Build parameters
      final Map<String, String> body = {
        'clinic_registration_type': 'Doctor',
        'partner_doctor_name': _doctorNameController.text.trim(),
        'partner_doctor_specialist': _specialistController.text.trim(),
        'partner_doctor_designation': _designationController.text.trim(),
        'partner_doctor_fees': _feesController.text.trim(),
        'partner_doctor_mobile': _mobileController.text.trim(),
        'partner_doctor_email': _emailController.text.trim(),
        'partner_doctor_landmark': _landmarkController.text.trim(),
        'partner_doctor_pincode': _pinCodeController.text.trim(),
        'partner_doctor_state': _selectedState!,
        'partner_doctor_city': _cityController.text.trim(),
        'partner_doctor_google_map_link': _googleMapController.text.trim(),
        'partner_doctor_address': _addressController.text.trim(),
      };

      // Add visit day, start time and end time arrays
      for (int i = 0; i < activeDaysList.length; i++) {
        final day = activeDaysList[i];
        body['partner_doctor_visit_day[$i]'] = day;
        body['partner_doctor_visit_start_time[$i]'] = _formatTimeOfDay(_startTimes[day]!);
        body['partner_doctor_visit_end_time[$i]'] = _formatTimeOfDay(_endTimes[day]!);
      }

      final response = await ApiService.storeClinicProfile(
        type: 'doctor',
        body: body,
        token: token,
        imageKey: 'doctorbanner',
        imagePath: _localBannerPath,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['success'] == true) {
        CustomAlerts.showSuccessLoader(context, response['message'] ?? 'Doctor contact saved successfully!');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context); // Dismiss success loader
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
                  'List Myself (Doctor Setup)',
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
                  'Complete your doctor practitioner contact details and schedule below',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Banner Image Upload Card
              FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: _buildBannerUploadCard(),
              ),

              // Section 1: Doctor Information
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: _buildSectionCard(
                  title: 'Doctor Information',
                  icon: Icons.badge_rounded,
                  children: [
                    _buildFormInput(
                      controller: _doctorNameController,
                      hint: 'Doctor Name *',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormInput(
                      controller: _specialistController,
                      hint: 'Specialization * (e.g. Cardiologist)',
                      icon: Icons.stars_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormInput(
                      controller: _designationController,
                      hint: 'Designation * (e.g. MD, Senior Consultant)',
                      icon: Icons.school_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildFormInput(
                      controller: _feesController,
                      hint: 'Fees * (INR)',
                      icon: Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

              // Section 3: Schedule Details
              FadeInUp(
                duration: const Duration(milliseconds: 550),
                child: _buildSectionCard(
                  title: 'Practice Schedule *',
                  icon: Icons.schedule_rounded,
                  children: _weekdays.map((day) => _buildScheduleRow(day)).toList(),
                ),
              ),

              // Section 4: Location Details
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
                      icon: Icons.home_rounded,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Submit Button
              FadeInUp(
                duration: const Duration(milliseconds: 650),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                        : Text(
                            'Save & Complete Setup',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.teal, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          children: children,
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary.withValues(alpha: 0.7), size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedState,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.map_outlined, color: AppColors.textSecondary.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 10),
              Text(
                'Select State *',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary.withValues(alpha: 0.7)),
          decoration: const InputDecoration(border: InputBorder.none),
          items: _states.map((state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: AppColors.textSecondary.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    state,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedState = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String day) {
    final isEnabled = _activeDays[day] ?? false;
    final startTime = _startTimes[day]!;
    final endTime = _endTimes[day]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isEnabled,
                activeColor: AppColors.teal,
                onChanged: (val) {
                  setState(() {
                    _activeDays[day] = val ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  day,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? AppColors.navy : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.teal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Start: ${_formatTimeDisplay(startTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.teal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'End: ${_formatTimeDisplay(endTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
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
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildBannerUploadCard() {
    Widget imageWidget;
    if (_localBannerPath != null) {
      imageWidget = Image.file(
        File(_localBannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      );
    } else if (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty) {
      imageWidget = Image.network(
        _serverBannerUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
          );
        },
      );
    } else {
      imageWidget = Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: AppColors.teal.withValues(alpha: 0.8), size: 40),
              const SizedBox(height: 8),
              Text(
                'Upload Doctor Banner Image',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG, WebP (Max 2MB)',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_rounded, color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Doctor Profile Banner Image',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: InkWell(
              onTap: _pickBannerImage,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: imageWidget),
                      if (_localBannerPath != null || (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty))
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Change',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
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
          ),
        ],
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
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
