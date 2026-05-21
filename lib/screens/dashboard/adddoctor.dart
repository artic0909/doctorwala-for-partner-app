import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isFetching = true;
  bool _isFormExpanded = false;
  List<dynamic> _doctors = [];

  // Edit Mode state
  bool _isEditing = false;
  String? _editingDoctorId;

  // Form State / Controllers
  final _doctorNameController = TextEditingController();
  final _specialistController = TextEditingController();
  String? _selectedDesignation;
  final _feesController = TextEditingController();
  final _moreController = TextEditingController();

  // Schedule management
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final Map<String, bool> _activeDays = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};

  @override
  void initState() {
    super.initState();
    _resetSchedule();
    _fetchDoctors();
  }

  void _resetSchedule() {
    for (var day in _weekdays) {
      _activeDays[day] = false;
      _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
      _endTimes[day] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialistController.dispose();
    _feesController.dispose();
    _moreController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatTime24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDBTime(String? dbTime) {
    if (dbTime == null || dbTime.isEmpty || dbTime.toLowerCase() == 'null') {
      return '';
    }
    final time = _parseTimeOfDay(dbTime);
    return _formatTimeDisplay(time);
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim();
      if (clean.contains('AM') || clean.contains('PM')) {
        final parts = clean.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final timeParts = clean.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        return TimeOfDay(
          hour: hour,
          minute: minute,
        );
      }
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isStart,
  ) async {
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

  Future<void> _fetchDoctors() async {
    setState(() => _isFetching = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isFetching = false);
        return;
      }

      final response = await ApiService.getDoctors(token: token);
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _doctors = response['doctors'] ?? [];
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load doctors.',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(
          context,
          'An unexpected error occurred while fetching doctors.',
        );
      }
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _editDoctor(Map<String, dynamic> doctor) {
    setState(() {
      _isEditing = true;
      _editingDoctorId = doctor['id'].toString();
      _doctorNameController.text = doctor['doctor_name']?.toString() ?? '';
      _specialistController.text =
          doctor['doctor_specialist']?.toString() ?? '';
      
      final des = doctor['doctor_designation']?.toString() ?? '';
      _selectedDesignation = ['MD', 'Dr', 'Prof', 'BDS'].contains(des) ? des : null;
      
      _feesController.text = doctor['doctor_fees']?.toString() ?? '';
      _moreController.text = doctor['doctor_more']?.toString() ?? '';

      _resetSchedule();

      // Parse schedule
      final visitData = doctor['visit_day_time'];
      if (visitData != null) {
        List<dynamic> schedules = [];
        if (visitData is List) {
          schedules = visitData;
        } else if (visitData is String) {
          try {
            schedules = jsonDecode(visitData);
          } catch (_) {}
        }

        for (var sched in schedules) {
          if (sched is Map) {
            final day = sched['day']?.toString();
            final start = sched['start_time']?.toString();
            final end = sched['end_time']?.toString();

            if (day != null && _weekdays.contains(day)) {
              _activeDays[day] = true;
              if (start != null && start.toLowerCase() != 'null' && start.isNotEmpty) {
                _startTimes[day] = _parseTimeOfDay(start);
              }
              if (end != null && end.toLowerCase() != 'null' && end.isNotEmpty) {
                _endTimes[day] = _parseTimeOfDay(end);
              }
            }
          }
        }
      }

      _isFormExpanded = true;
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingDoctorId = null;
      _doctorNameController.clear();
      _specialistController.clear();
      _selectedDesignation = null;
      _feesController.clear();
      _moreController.clear();
      _resetSchedule();
      _isFormExpanded = false;
    });
  }

  Future<void> _deleteDoctor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Delete Doctor',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this doctor from your seating?',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final token = await SessionManager.getToken();
        if (token == null) return;

        final res = await ApiService.deleteDoctor(token: token, id: id);
        if (!mounted) return;
        if (res['success'] == true) {
          CustomAlerts.showSuccess(
            context,
            res['message'] ?? 'Doctor deleted successfully!',
          );
          _fetchDoctors();
          if (_isEditing && _editingDoctorId == id) {
            _cancelEdit();
          }
        } else {
          CustomAlerts.showError(
            context,
            res['message'] ?? 'Failed to delete doctor.',
          );
        }
      } catch (_) {
        if (mounted) {
          CustomAlerts.showError(context, 'An error occurred while deleting.');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitForm() async {
    if (_doctorNameController.text.trim().isEmpty ||
        _specialistController.text.trim().isEmpty ||
        _selectedDesignation == null ||
        _feesController.text.trim().isEmpty) {
      CustomAlerts.showError(
        context,
        'Please fill in all required fields marked with *',
      );
      return;
    }

    // Check if at least one day is selected
    final hasSchedule = _activeDays.values.any((active) => active);
    if (!hasSchedule) {
      CustomAlerts.showError(
        context,
        'Please select at least one weekday for the seating schedule.',
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
        'doctor_name': _doctorNameController.text.trim(),
        'doctor_designation': _selectedDesignation!,
        'doctor_specialist': _specialistController.text.trim(),
        'doctor_fees': _feesController.text.trim(),
        'doctor_more': _moreController.text.trim(),
      };

      int idx = 0;
      for (var day in _weekdays) {
        if (_activeDays[day] == true) {
          body['doctor_visit_day[$idx]'] = day;
          body['doctor_visit_start_time[$idx]'] = _formatTime24h(
            _startTimes[day]!,
          );
          body['doctor_visit_end_time[$idx]'] = _formatTime24h(
            _endTimes[day]!,
          );
          idx++;
        }
      }

      final response =
          _isEditing
              ? await ApiService.updateDoctor(
                token: token,
                id: _editingDoctorId!,
                body: body,
              )
              : await ApiService.addDoctor(token: token, body: body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        CustomAlerts.showSuccessLoader(
          context,
          response['message'] ?? 'Doctor details saved successfully!',
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context); // Pop success loader
          _cancelEdit();
          _fetchDoctors();
        }
      } else {
        String errorMessage =
            response['message'] ?? 'Failed to save doctor details.';
        if (response['errors'] != null && response['errors'] is Map) {
          final errors = response['errors'] as Map;
          final firstErrorList = errors.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            errorMessage = firstErrorList.first.toString();
          }
        }
        CustomAlerts.showError(context, errorMessage);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomAlerts.showError(
          context,
          'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          _isFetching
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchDoctors,
                color: AppColors.teal,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          'Manage Doctors',
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
                          'Add, edit or remove doctors practicing at your clinic chamber.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Expandable Doctor Add Form
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: _buildFormCard(),
                      ),

                      const SizedBox(height: 25),

                      // Doctor Directory Title
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            color: AppColors.navy,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Doctors Directory (${_doctors.length})',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Doctors List
                      _buildDoctorsList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
          initiallyExpanded: _isFormExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isFormExpanded = expanded;
            });
          },
          key: ValueKey<bool>(_isFormExpanded),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
              color: AppColors.teal,
              size: 20,
            ),
          ),
          title: Text(
            _isEditing
                ? 'Edit Doctor: ${_doctorNameController.text}'
                : 'Add New Doctor',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
          ),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 20),
                  _buildDesignationDropdown(),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _doctorNameController,
                    hint: 'Enter Doctor Name *',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _specialistController,
                    hint: 'Enter Specialist *',
                    icon: Icons.stars_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _feesController,
                    hint: 'Enter Doctor Fees *',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _buildFormInput(
                    controller: _moreController,
                    hint: 'Enter More Details About Doctor',
                    icon: Icons.info_outline_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Schedule section
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SEATING SCHEDULE *',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Column(
                    children:
                        _weekdays.map((day) => _buildScheduleRow(day)).toList(),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      if (_isEditing) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelEdit,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.getStartedGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
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
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isEditing
                                              ? 'Update Details'
                                              : 'Upload Details',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                          ),
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
          prefixIcon: Icon(
            icon,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            size: 18,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDesignationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDesignation,
        dropdownColor: Colors.white,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.school_outlined,
            color: AppColors.textSecondary,
            size: 18,
          ),
          hintText: 'Designation *',
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: ['MD', 'Dr', 'Prof', 'BDS'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedDesignation = newValue;
          });
        },
      ),
    );
  }

  Widget _buildScheduleRow(String day) {
    final isEnabled = _activeDays[day] ?? false;
    final startTime = _startTimes[day]!;
    final endTime = _endTimes[day]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        isEnabled
                            ? AppColors.navy
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 2, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Time From: ${_formatTimeDisplay(startTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Time To: ${_formatTimeDisplay(endTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    if (_doctors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.skyBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information_rounded,
                color: AppColors.navy,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Doctors Registered',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add New Doctor" at the top to add doctor schedules and visit fees.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _doctors.length,
      itemBuilder: (context, idx) {
        final doc = _doctors[idx] as Map<String, dynamic>;
        final id = doc['id']?.toString() ?? '';
        final name = doc['doctor_name'] ?? 'N/A';
        final spec = doc['doctor_specialist'] ?? 'N/A';
        final desig = doc['doctor_designation'] ?? 'N/A';
        final fees = doc['doctor_fees']?.toString() ?? '0';
        final more = doc['doctor_more']?.toString() ?? '';

        // Decode days list
        List<dynamic> daysList = [];
        final visitData = doc['visit_day_time'];
        if (visitData != null) {
          if (visitData is List) {
            daysList = visitData;
          } else if (visitData is String) {
            try {
              daysList = jsonDecode(visitData);
            } catch (_) {}
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.navy,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$desig • $spec',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹$fees',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),

              if (more.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  more,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
              ),

              // Timings / Schedule list
              Text(
                'Schedule:',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    daysList.map<Widget>((sched) {
                      final dayName = sched['day']?.toString() ?? '';
                      final start = sched['start_time']?.toString() ?? '';
                      final end = sched['end_time']?.toString() ?? '';

                      // Make short day names, e.g. Monday -> Mon
                      String shortDay = dayName;
                      if (dayName.length > 3) {
                        shortDay = dayName.substring(0, 3);
                      }

                      final startDisplay = _formatDBTime(start);
                      final endDisplay = _formatDBTime(end);
                      final String displayTime;
                      if (startDisplay.isEmpty && endDisplay.isEmpty) {
                        displayTime = 'No Timings';
                      } else if (endDisplay.isEmpty) {
                        displayTime = '$startDisplay onwards';
                      } else if (startDisplay.isEmpty) {
                        displayTime = 'Till $endDisplay';
                      } else {
                        displayTime = '$startDisplay - $endDisplay';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          '$shortDay ($displayTime)',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _editDoctor(doc),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.teal,
                      size: 20,
                    ),
                    tooltip: 'Edit details',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteDoctor(id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Delete doctor',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
