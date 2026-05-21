import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class _DoctorTheme {
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo Navy
  static const Color accent = Color(0xFF0D9488); // Turquoise/Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Mint/Turquoise Light
  static const Color bgTint = Color(0xFFF8FAFC); // Slate background
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium slate
  static const Color border = Color(0xFFE2E8F0); // Border color
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AddDoctorScreen extends StatefulWidget {
  final Map<String, dynamic>? doctorToEdit;
  const AddDoctorScreen({super.key, this.doctorToEdit});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

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
    'All Day',
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
    if (widget.doctorToEdit != null) {
      _loadDoctorForEdit(widget.doctorToEdit!);
    }
  }

  void _resetSchedule() {
    for (var day in _weekdays) {
      _activeDays[day] = false;
      _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
      _endTimes[day] = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  void _loadDoctorForEdit(Map<String, dynamic> doctor) {
    setState(() {
      _isEditing = true;
      _editingDoctorId = doctor['id'].toString();
      _doctorNameController.text = doctor['doctor_name']?.toString() ?? '';
      _specialistController.text =
          doctor['doctor_specialist']?.toString() ?? '';

      final des = doctor['doctor_designation']?.toString() ?? '';
      _selectedDesignation =
          ['MD', 'Dr', 'Prof', 'BDS'].contains(des) ? des : null;

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
              if (start != null &&
                  start.toLowerCase() != 'null' &&
                  start.isNotEmpty) {
                _startTimes[day] = _parseTimeOfDay(start);
              }
              if (end != null &&
                  end.toLowerCase() != 'null' &&
                  end.isNotEmpty) {
                _endTimes[day] = _parseTimeOfDay(end);
              }
            }
          }
        }
      }
    });
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
        return TimeOfDay(hour: hour, minute: minute);
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
              primary: _DoctorTheme.accent,
              onPrimary: Colors.white,
              onSurface: _DoctorTheme.primary,
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
          body['doctor_visit_end_time[$idx]'] = _formatTime24h(_endTimes[day]!);
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
          Navigator.pop(
            context,
            true,
          ); // Pop AddDoctorScreen with success result
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
      backgroundColor: _DoctorTheme.bgTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _DoctorTheme.primary),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _isEditing ? 'Edit Doctor Details' : 'Add New Doctor',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: _DoctorTheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _isEditing ? 'Modify Practitioner Details' : 'List New Doctor',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _DoctorTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeInDown(
              duration: const Duration(milliseconds: 450),
              child: Text(
                'Configure seating schedule, designation, and consultation fees.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _DoctorTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 25),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildFormCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _DoctorTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildDesignationSelector(),
            const SizedBox(height: 20),
            _AnimatedFormInput(
              controller: _doctorNameController,
              hint: 'Enter Doctor Name *',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _AnimatedFormInput(
              controller: _specialistController,
              hint: 'Enter Specialist *',
              icon: Icons.stars_outlined,
            ),
            const SizedBox(height: 14),
            _AnimatedFormInput(
              controller: _feesController,
              hint: 'Enter Doctor Fees *',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            _AnimatedFormInput(
              controller: _moreController,
              hint: 'Enter More Details About Doctor',
              icon: Icons.info_outline_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Schedule section
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: _DoctorTheme.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'SEATING SCHEDULE *',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _DoctorTheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Column(
              children: _weekdays.map((day) => _buildScheduleRow(day)).toList(),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _DoctorTheme.border),
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
                        color: _DoctorTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _DoctorTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _DoctorTheme.accent.withValues(alpha: 0.25),
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
                        padding: EdgeInsets.zero,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DESIGNATION *',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _DoctorTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['MD', 'Dr', 'Prof', 'BDS'].map((option) {
            final isSelected = _selectedDesignation == option;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDesignation = option;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _DoctorTheme.accentLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _DoctorTheme.accent : _DoctorTheme.border,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _DoctorTheme.accent.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? _DoctorTheme.accent : _DoctorTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String day) {
    final isEnabled = _activeDays[day] ?? false;
    final startTime = _startTimes[day]!;
    final endTime = _endTimes[day]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : _DoctorTheme.bgTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? _DoctorTheme.accent.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: _DoctorTheme.accent.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _activeDays[day] = !isEnabled;
              });
            },
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isEnabled ? _DoctorTheme.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isEnabled ? _DoctorTheme.accent : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isEnabled
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                     day,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? _DoctorTheme.textPrimary : _DoctorTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  isEnabled ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: isEnabled ? _DoctorTheme.accent : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _DoctorTheme.bgTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: _DoctorTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Time From: ${_formatTimeDisplay(startTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _DoctorTheme.textPrimary,
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
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _DoctorTheme.bgTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: _DoctorTheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Time To: ${_formatTimeDisplay(endTime)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _DoctorTheme.textPrimary,
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
}

class _AnimatedFormInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _AnimatedFormInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  State<_AnimatedFormInput> createState() => _AnimatedFormInputState();
}

class _AnimatedFormInputState extends State<_AnimatedFormInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : _DoctorTheme.bgTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? _DoctorTheme.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: _DoctorTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.maxLines,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _DoctorTheme.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused 
                ? _DoctorTheme.primary 
                : _DoctorTheme.textSecondary.withValues(alpha: 0.7),
            size: 18,
          ),
          hintText: widget.hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _DoctorTheme.textSecondary.withValues(alpha: 0.5),
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
}
