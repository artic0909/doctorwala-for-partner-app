  import 'dart:io';
import 'dart:convert';
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

class DoctorScheduleSlot {
  String type; // 'day' or 'date'
  String day;
  String? date;

  bool morningEnabled;
  TimeOfDay morningStart;
  TimeOfDay morningEnd;

  bool afternoonEnabled;
  TimeOfDay afternoonStart;
  TimeOfDay afternoonEnd;

  bool eveningEnabled;
  TimeOfDay eveningStart;
  TimeOfDay eveningEnd;

  DoctorScheduleSlot({
    this.type = 'day',
    this.day = 'Monday',
    this.date,
    this.morningEnabled = true,
    this.morningStart = const TimeOfDay(hour: 9, minute: 0),
    this.morningEnd = const TimeOfDay(hour: 12, minute: 0),
    this.afternoonEnabled = true,
    this.afternoonStart = const TimeOfDay(hour: 13, minute: 0),
    this.afternoonEnd = const TimeOfDay(hour: 16, minute: 0),
    this.eveningEnabled = true,
    this.eveningStart = const TimeOfDay(hour: 17, minute: 0),
    this.eveningEnd = const TimeOfDay(hour: 20, minute: 0),
  });

  Map<String, dynamic> toJson(String Function(TimeOfDay) formatter) {
    return {
      'type': type,
      'day': day,
      'date': date,
      'morning_enabled': morningEnabled,
      'morning_start': formatter(morningStart),
      'morning_end': formatter(morningEnd),
      'afternoon_enabled': afternoonEnabled,
      'afternoon_start': formatter(afternoonStart),
      'afternoon_end': formatter(afternoonEnd),
      'evening_enabled': eveningEnabled,
      'evening_start': formatter(eveningStart),
      'evening_end': formatter(eveningEnd),
      'start_time': morningEnabled
          ? formatter(morningStart)
          : (afternoonEnabled ? formatter(afternoonStart) : formatter(eveningStart)),
      'end_time': eveningEnabled
          ? formatter(eveningEnd)
          : (afternoonEnabled ? formatter(afternoonEnd) : formatter(morningEnd)),
    };
  }
}

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
  String? _clinicRegistrationType;

  // States List
  final List<String> _states = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  // Weekdays Schedule State
  // ignore: unused_field
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
    'All Day',
  ];

  final List<DoctorScheduleSlot> _scheduleSlots = [];

  TimeOfDay _parseTime(String? timeStr, TimeOfDay fallback) {
    if (timeStr == null || !timeStr.contains(':')) return fallback;
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  void _loadScheduleFromData(dynamic raw) {
    _scheduleSlots.clear();
    if (raw != null && raw is List && raw.isNotEmpty) {
      for (var item in raw) {
        if (item is Map) {
          final type = item['type']?.toString() ?? (item['date'] != null ? 'date' : 'day');
          final date = item['date']?.toString();
          final day = item['day']?.toString() ?? 'Monday';

          // Currently day-wise is hidden, only keep date-wise slots
          if (type != 'date' && date == null) continue;

          final bool mOn = item['morning_enabled'] == true;
          final bool aOn = item['afternoon_enabled'] == true;
          final bool eOn = item['evening_enabled'] == true;

          final legacyStart = item['start_time']?.toString();
          final legacyEnd = item['end_time']?.toString();

          bool finalM = mOn;
          bool finalA = aOn;
          bool finalE = eOn;

          TimeOfDay mStart = _parseTime(item['morning_start']?.toString(), const TimeOfDay(hour: 9, minute: 0));
          TimeOfDay mEnd = _parseTime(item['morning_end']?.toString(), const TimeOfDay(hour: 12, minute: 0));
          TimeOfDay aStart = _parseTime(item['afternoon_start']?.toString(), const TimeOfDay(hour: 13, minute: 0));
          TimeOfDay aEnd = _parseTime(item['afternoon_end']?.toString(), const TimeOfDay(hour: 16, minute: 0));
          TimeOfDay eStart = _parseTime(item['evening_start']?.toString(), const TimeOfDay(hour: 17, minute: 0));
          TimeOfDay eEnd = _parseTime(item['evening_end']?.toString(), const TimeOfDay(hour: 20, minute: 0));

          if (!mOn && !aOn && !eOn && legacyStart != null) {
            final startHour = int.tryParse(legacyStart.split(':')[0]) ?? 10;
            if (startHour < 12) {
              finalM = true;
              mStart = _parseTime(legacyStart, mStart);
              mEnd = _parseTime(legacyEnd, mEnd);
            } else if (startHour < 16) {
              finalA = true;
              aStart = _parseTime(legacyStart, aStart);
              aEnd = _parseTime(legacyEnd, aEnd);
            } else {
              finalE = true;
              eStart = _parseTime(legacyStart, eStart);
              eEnd = _parseTime(legacyEnd, eEnd);
            }
          }

          _scheduleSlots.add(DoctorScheduleSlot(
            type: 'date',
            day: day,
            date: date,
            morningEnabled: finalM,
            morningStart: mStart,
            morningEnd: mEnd,
            afternoonEnabled: finalA,
            afternoonStart: aStart,
            afternoonEnd: aEnd,
            eveningEnabled: finalE,
            eveningStart: eStart,
            eveningEnd: eEnd,
          ));
        }
      }
    }

    if (_scheduleSlots.isEmpty) {
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      _scheduleSlots.add(DoctorScheduleSlot(
        type: 'date',
        date: dateStr,
        day: dayNames[now.weekday - 1],
        morningEnabled: true,
        afternoonEnabled: true,
        eveningEnabled: true,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
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
        _clinicRegistrationType = (data['clinic_registration_type'] ?? 'Doctor').toString();
        final dName = (data['partner_doctor_name'] ??
                partnerData?['partner_contact_person_name'] ??
                '')
            .toString()
            .trim();
        final dSpec =
            (data['partner_doctor_specialist'] ?? '').toString().trim();
        final dDesig =
            (data['partner_doctor_designation'] ?? '').toString().trim();
        final hasDoc = dName.isNotEmpty && dSpec.isNotEmpty && dDesig.isNotEmpty;

        final feesVal = double.tryParse(
                (data['partner_doctor_fees'] ?? '').toString().trim()) ??
            0;
        final hasFee = feesVal > 0;

        final addrVal = (data['partner_doctor_address'] ??
                partnerData?['partner_address'] ??
                '')
            .toString()
            .trim();
        final cityVal = (data['partner_doctor_city'] ??
                partnerData?['partner_city'] ??
                '')
            .toString()
            .trim();
        final pinVal = (data['partner_doctor_pincode'] ??
                partnerData?['partner_pincode'] ??
                '')
            .toString()
            .trim();
        final hasAddr =
            addrVal.isNotEmpty && cityVal.isNotEmpty && pinVal.isNotEmpty;

        bool hasSched = false;
        if (data['visit_day_time'] != null && data['visit_day_time'] is List) {
          final list = data['visit_day_time'] as List;
          if (list.isNotEmpty) {
            hasSched = true;
          }
        }

        final bool hasBanner = (response['doctor_banner'] != null && response['doctor_banner'].toString().isNotEmpty) ||
            (data['partner_doctor_banner'] != null && data['partner_doctor_banner'].toString().isNotEmpty);
        final bool hasMap = (data['partner_doctor_google_map_link'] ?? '').toString().trim().isNotEmpty;

        int stepsCount = 0;
        if (hasDoc) stepsCount++;
        if (hasFee && hasSched) stepsCount++;
        if (hasAddr && hasMap) stepsCount++;
        if (hasBanner) stepsCount++;
        final calcPct = stepsCount * 25;

        final prefs = await SharedPreferences.getInstance();
        final pid = partnerData?['id']?.toString() ?? 'default';
        await prefs.setInt('profile_completion_percent_$pid', calcPct);
        await prefs.setBool('has_doc_info_$pid', hasDoc);
        await prefs.setBool('has_fee_$pid', hasFee && hasSched);
        await prefs.setBool('has_addr_$pid', hasAddr && hasMap);
        await prefs.setBool('has_map_$pid', hasMap);
        await prefs.setBool('has_banner_$pid', hasBanner);
        await prefs.setBool('doctor_contact_saved_$pid', calcPct == 100);

        setState(() {
          _serverBannerUrl = response['doctor_banner'];
          _doctorNameController.text =
              (data['partner_doctor_name'] != null &&
                      data['partner_doctor_name'].toString().isNotEmpty)
                  ? data['partner_doctor_name'].toString()
                  : (partnerData?['partner_contact_person_name']?.toString() ??
                      '');

          _specialistController.text =
              data['partner_doctor_specialist']?.toString() ?? '';
          _designationController.text =
              data['partner_doctor_designation']?.toString() ?? '';
          final String rawFee = data['partner_doctor_fees']?.toString() ?? '';
          _feesController.text = (rawFee.isEmpty || rawFee == '500') ? '000' : rawFee;

          _mobileController.text =
              (data['partner_doctor_mobile'] != null &&
                      data['partner_doctor_mobile'].toString().isNotEmpty)
                  ? data['partner_doctor_mobile'].toString()
                  : (partnerData?['partner_mobile_number']?.toString() ?? '');

          _emailController.text =
              (data['partner_doctor_email'] != null &&
                      data['partner_doctor_email'].toString().isNotEmpty)
                  ? data['partner_doctor_email'].toString()
                  : (partnerData?['partner_email']?.toString() ?? '');

          _cityController.text =
              (data['partner_doctor_city'] != null &&
                      data['partner_doctor_city'].toString().isNotEmpty)
                  ? data['partner_doctor_city'].toString()
                  : (partnerData?['partner_city']?.toString() ?? '');

          _pinCodeController.text =
              (data['partner_doctor_pincode'] != null &&
                      data['partner_doctor_pincode'].toString().isNotEmpty)
                  ? data['partner_doctor_pincode'].toString()
                  : (partnerData?['partner_pincode']?.toString() ?? '');

          _landmarkController.text =
              (data['partner_doctor_landmark'] != null &&
                      data['partner_doctor_landmark'].toString().isNotEmpty)
                  ? data['partner_doctor_landmark'].toString()
                  : (partnerData?['partner_landmark']?.toString() ?? '');

          _googleMapController.text =
              data['partner_doctor_google_map_link'] ?? '';

          _addressController.text =
              (data['partner_doctor_address'] != null &&
                      data['partner_doctor_address'].toString().isNotEmpty)
                  ? data['partner_doctor_address'].toString()
                  : (partnerData?['partner_address']?.toString() ?? '');

          final fetchedState =
              (data['partner_doctor_state'] != null &&
                      data['partner_doctor_state'].toString().isNotEmpty)
                  ? data['partner_doctor_state'].toString().trim()
                  : (partnerData?['partner_state']?.toString().trim());

          if (fetchedState != null && _states.contains(fetchedState)) {
            _selectedState = fetchedState;
          }

          _loadScheduleFromData(data['visit_day_time']);
        });
      } else {
        if (partnerData != null) {
          setState(() {
            _doctorNameController.text =
                partnerData['partner_contact_person_name']?.toString() ?? '';
            _mobileController.text =
                partnerData['partner_mobile_number']?.toString() ?? '';
            _emailController.text =
                partnerData['partner_email']?.toString() ?? '';
            _cityController.text =
                partnerData['partner_city']?.toString() ?? '';
            _pinCodeController.text =
                partnerData['partner_pincode']?.toString() ?? '';
            _landmarkController.text =
                partnerData['partner_landmark']?.toString() ?? '';
            _addressController.text =
                partnerData['partner_address']?.toString() ?? '';

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
      CustomAlerts.showError(
        context,
        'Please fill in all required fields marked with *',
      );
      return;
    }

    final mobileText = _mobileController.text.trim();
    if (!RegExp(r'^\d{10,}$').hasMatch(mobileText)) {
      CustomAlerts.showError(
        context,
        'Mobile number must be at least 10 digits',
      );
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

    bool hasActiveSlot = false;
    for (var slot in _scheduleSlots) {
      if (slot.morningEnabled) {
        final startMinutes = slot.morningStart.hour * 60 + slot.morningStart.minute;
        final endMinutes = slot.morningEnd.hour * 60 + slot.morningEnd.minute;
        if (endMinutes <= startMinutes) {
          CustomAlerts.showError(
            context,
            'Morning slot end time must be after start time for ${slot.type == "date" ? slot.date : slot.day}.',
          );
          return;
        }
        hasActiveSlot = true;
      }
      if (slot.afternoonEnabled) {
        final startMinutes = slot.afternoonStart.hour * 60 + slot.afternoonStart.minute;
        final endMinutes = slot.afternoonEnd.hour * 60 + slot.afternoonEnd.minute;
        if (endMinutes <= startMinutes) {
          CustomAlerts.showError(
            context,
            'Afternoon slot end time must be after start time for ${slot.type == "date" ? slot.date : slot.day}.',
          );
          return;
        }
        hasActiveSlot = true;
      }
      if (slot.eveningEnabled) {
        final startMinutes = slot.eveningStart.hour * 60 + slot.eveningStart.minute;
        final endMinutes = slot.eveningEnd.hour * 60 + slot.eveningEnd.minute;
        if (endMinutes <= startMinutes) {
          CustomAlerts.showError(
            context,
            'Evening slot end time must be after start time for ${slot.type == "date" ? slot.date : slot.day}.',
          );
          return;
        }
        hasActiveSlot = true;
      }
    }

    if (!hasActiveSlot) {
      CustomAlerts.showError(
        context,
        'Please configure at least one active visiting schedule slot (Morning, Afternoon, or Evening).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await SessionManager.getToken();
      if (!mounted) return;
      if (token == null) {
        CustomAlerts.showError(
          context,
          'Session expired. Please log in again.',
        );
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, String> body = {
        'clinic_registration_type': _clinicRegistrationType ?? 'Doctor',
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
        'schedule_data_json': jsonEncode(
          _scheduleSlots.map((s) => s.toJson(_formatTimeOfDay)).toList(),
        ),
      };

      for (int i = 0; i < _scheduleSlots.length; i++) {
        final slot = _scheduleSlots[i];
        body['partner_doctor_visit_day[$i]'] =
            slot.type == 'date' && slot.date != null ? slot.date! : slot.day;
        final startStr = slot.morningEnabled
            ? _formatTimeOfDay(slot.morningStart)
            : (slot.afternoonEnabled
                ? _formatTimeOfDay(slot.afternoonStart)
                : _formatTimeOfDay(slot.eveningStart));
        final endStr = slot.eveningEnabled
            ? _formatTimeOfDay(slot.eveningEnd)
            : (slot.afternoonEnabled
                ? _formatTimeOfDay(slot.afternoonEnd)
                : _formatTimeOfDay(slot.morningEnd));
        body['partner_doctor_visit_start_time[$i]'] = startStr;
        body['partner_doctor_visit_end_time[$i]'] = endStr;
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
        final prefs = await SharedPreferences.getInstance();
        final pData = await SessionManager.getPartnerData();
        final pid = pData?['id']?.toString() ?? 'default';

        final bool hasBanner = _localBannerPath != null ||
            (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty) ||
            (response['doctor_banner'] != null && response['doctor_banner'].toString().isNotEmpty);
        final bool hasMap = _googleMapController.text.trim().isNotEmpty;
        final bool hasDoc = _doctorNameController.text.trim().isNotEmpty &&
            _specialistController.text.trim().isNotEmpty &&
            _designationController.text.trim().isNotEmpty;
        final double feeVal = double.tryParse(_feesController.text.trim()) ?? 0;
        final bool hasFee = feeVal > 0;
        final bool hasSched = _scheduleSlots.isNotEmpty;
        final bool hasAddr = _addressController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _pinCodeController.text.trim().isNotEmpty &&
            _selectedState != null;

        int stepsCount = 0;
        if (hasDoc) stepsCount++;
        if (hasFee && hasSched) stepsCount++;
        if (hasAddr && hasMap) stepsCount++;
        if (hasBanner) stepsCount++;
        final calcPct = stepsCount * 25;

        await prefs.setInt('profile_completion_percent_$pid', calcPct);
        await prefs.setBool('has_doc_info_$pid', hasDoc);
        await prefs.setBool('has_fee_$pid', hasFee && hasSched);
        await prefs.setBool('has_addr_$pid', hasAddr && hasMap);
        await prefs.setBool('has_map_$pid', hasMap);
        await prefs.setBool('has_banner_$pid', hasBanner);
        await prefs.setBool('doctor_contact_saved_$pid', calcPct == 100);

        if (!mounted) return;

        CustomAlerts.showSuccessLoader(
          context,
          response['message'] ?? 'Doctor profile saved successfully!',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context);
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
      CustomAlerts.showError(
        context,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Banner Image Source',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Gallery',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickBannerImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
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
        CustomAlerts.showError(
          context,
          'Failed to pick image. Please try again.',
        );
      }
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
              // Header Title
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Doctor Setup & Profile',
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
                  'Fill your practitioner profile, consultation fees and visiting hours',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Compact Stepper Roadmap Badge
              FadeInDown(
                duration: const Duration(milliseconds: 380),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 0.9),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A),
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '1. Info  ➔  2. Fees & Schedule  ➔  3. Address & Map Link  ➔  4. Banner Image',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Compact Banner Image Upload Card
              FadeInUp(
                duration: const Duration(milliseconds: 320),
                child: _buildCompactBannerCard(),
              ),
              const SizedBox(height: 12),

              // Section 1: Doctor Credentials
              FadeInUp(
                duration: const Duration(milliseconds: 360),
                child: _buildSectionCard(
                  title: 'Doctor Credentials',
                  icon: Icons.medical_information_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  children: [
                    _buildCompactField(
                      label: 'Doctor Name',
                      controller: _doctorNameController,
                      hint: 'Dr. John Doe',
                      icon: Icons.person_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Specialization',
                      controller: _specialistController,
                      hint: 'e.g. Cardiologist, General Physician',
                      icon: Icons.stars_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Designation & Degree',
                      controller: _designationController,
                      hint: 'e.g. MBBS, MD, Senior Consultant',
                      icon: Icons.school_rounded,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Consultation Fees (INR)',
                      controller: _feesController,
                      hint: 'e.g. 000',
                      icon: Icons.payments_rounded,
                      isRequired: true,
                      prefixText: '₹ ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      hint: 'doctor@example.com',
                      icon: Icons.alternate_email_rounded,
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 3: Chamber & Location Details
              FadeInUp(
                duration: const Duration(milliseconds: 440),
                child: _buildSectionCard(
                  title: 'Chamber Location',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF0D9488),
                  children: [
                    _buildCompactStateDropdown(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactField(
                            label: 'City',
                            controller: _cityController,
                            hint: 'e.g. Kolkata',
                            icon: Icons.location_city_rounded,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCompactField(
                            label: 'Pin Code',
                            controller: _pinCodeController,
                            hint: '6 digits',
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
                      hint: 'Near Metro / Hospital',
                      icon: Icons.assistant_navigation,
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Full Chamber Address',
                      controller: _addressController,
                      hint: 'Flat/Shop No, Street, Area details',
                      icon: Icons.home_rounded,
                      isRequired: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactField(
                      label: 'Google Map Link',
                      controller: _googleMapController,
                      hint: 'https://maps.google.com/?q=... (Required for 100%)',
                      icon: Icons.map_rounded,
                      isRequired: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 4: Practice Schedule (Day-wise & Date-wise)
              FadeInUp(
                duration: const Duration(milliseconds: 480),
                child: _buildSectionCard(
                  title: 'Visiting Schedule (Date Wise)',
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF0284C7),
                  children: [
                    Text(
                      'Configure practice dates on the calendar and set Morning, Afternoon, and Evening practice slots for online consultations',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addDateSlot,
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0284C7)),
                        label: Text(
                          '+ Add Visiting Date',
                          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._scheduleSlots.asMap().entries.map((entry) => _buildScheduleSlotCard(entry.value, entry.key)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              FadeInUp(
                duration: const Duration(milliseconds: 520),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.getStartedGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Save & Complete Setup',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
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

  // --- WIDGET BUILDERS ---

  Widget _buildCompactBannerCard() {
    Widget imageContent;
    final hasImage = _localBannerPath != null ||
        (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty);

    if (_localBannerPath != null) {
      imageContent = Image.file(
        File(_localBannerPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 125,
      );
    } else if (_serverBannerUrl != null && _serverBannerUrl!.isNotEmpty) {
      imageContent = Image.network(
        _serverBannerUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 125,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(),
      );
    } else {
      imageContent = _buildPlaceholderBanner();
    }

    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.image_rounded,
                  color: Color(0xFF0D9488),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  'Doctor Profile Banner',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max 2MB',
                  style: GoogleFonts.manrope(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: GestureDetector(
              onTap: () => _showImageSourceActionSheet(context),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageContent,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasImage
                                ? Icons.edit_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasImage ? 'Change' : 'Upload',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.teal,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to upload doctor banner or clinic photo',
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'JPG, PNG or WebP',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15.5),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
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
    final isMultiline = maxLines > 1;

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
        const SizedBox(height: 4),
        SizedBox(
          height: isMultiline ? 60 : 42,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
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
              prefixIcon: isMultiline
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Icon(icon, color: const Color(0xFF64748B), size: 16.5),
                    )
                  : Icon(icon, color: const Color(0xFF64748B), size: 16.5),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
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

  Widget _buildCompactStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'State',
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
        const SizedBox(height: 4),
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
                    _selectedState ?? 'Select State',
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
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  void _addDaySlot() {
    setState(() {
      _scheduleSlots.add(DoctorScheduleSlot(
        type: 'day',
        day: 'Monday',
        morningEnabled: true,
        afternoonEnabled: true,
        eveningEnabled: true,
      ));
    });
  }

  Future<void> _addDateSlot() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0284C7),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final dateStr =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[picked.weekday - 1];

      setState(() {
        _scheduleSlots.add(DoctorScheduleSlot(
          type: 'date',
          date: dateStr,
          day: dayName,
          morningEnabled: true,
          afternoonEnabled: true,
          eveningEnabled: true,
        ));
      });
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: Colors.white,
            onSurface: Color(0xFF0F172A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Widget _buildScheduleSlotCard(DoctorScheduleSlot slot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_rounded, size: 12, color: Color(0xFF0369A1)),
                    const SizedBox(width: 4),
                    Text(
                      'VISITING DATE',
                      style: GoogleFonts.manrope(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0369A1),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(slot.date ?? '') ?? now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 180)),
                    );
                    if (picked != null) {
                      setState(() {
                        slot.date =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                        slot.day = dayNames[picked.weekday - 1];
                      });
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13.5, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            slot.date != null ? "${slot.date} (${slot.day})" : 'Select Date',
                            maxLines: 1,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  if (_scheduleSlots.length > 1) {
                    setState(() {
                      _scheduleSlots.removeAt(index);
                    });
                  } else {
                    CustomAlerts.showError(context, 'At least one visiting date slot is required.');
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.8),

          // 3 Slot Shifts (Using Icons, NO Emojis!)
          _buildSlotShiftRow(
            label: 'Morning Slot',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            enabled: slot.morningEnabled,
            startTime: slot.morningStart,
            endTime: slot.morningEnd,
            onToggle: (val) => setState(() => slot.morningEnabled = val),
            onPickStart: () => _pickTime(context, slot.morningStart, (t) => setState(() => slot.morningStart = t)),
            onPickEnd: () => _pickTime(context, slot.morningEnd, (t) => setState(() => slot.morningEnd = t)),
          ),
          const SizedBox(height: 6),
          _buildSlotShiftRow(
            label: 'Afternoon Slot',
            icon: Icons.cloud_queue_rounded,
            iconColor: const Color(0xFFEA580C),
            enabled: slot.afternoonEnabled,
            startTime: slot.afternoonStart,
            endTime: slot.afternoonEnd,
            onToggle: (val) => setState(() => slot.afternoonEnabled = val),
            onPickStart: () => _pickTime(context, slot.afternoonStart, (t) => setState(() => slot.afternoonStart = t)),
            onPickEnd: () => _pickTime(context, slot.afternoonEnd, (t) => setState(() => slot.afternoonEnd = t)),
          ),
          const SizedBox(height: 6),
          _buildSlotShiftRow(
            label: 'Evening Slot',
            icon: Icons.nightlight_round_rounded,
            iconColor: const Color(0xFF7C3AED),
            enabled: slot.eveningEnabled,
            startTime: slot.eveningStart,
            endTime: slot.eveningEnd,
            onToggle: (val) => setState(() => slot.eveningEnabled = val),
            onPickStart: () => _pickTime(context, slot.eveningStart, (t) => setState(() => slot.eveningStart = t)),
            onPickEnd: () => _pickTime(context, slot.eveningEnd, (t) => setState(() => slot.eveningEnd = t)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotShiftRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required ValueChanged<bool> onToggle,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF0FAF7) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFFBFECE1) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: Checkbox(
              value: enabled,
              activeColor: AppColors.teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => onToggle(val ?? false),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 15, color: enabled ? iconColor : const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: enabled ? FontWeight.w800 : FontWeight.w600,
                color: enabled ? AppColors.navy : const Color(0xFF64748B),
              ),
            ),
          ),
          if (enabled) ...[
            InkWell(
              onTap: onPickStart,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                ),
                child: Text(
                  _formatTimeDisplay(startTime),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 11,
                color: Color(0xFF16A34A),
              ),
            ),
            InkWell(
              onTap: onPickEnd,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                ),
                child: Text(
                  _formatTimeDisplay(endTime),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Off',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
