import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../core/session_manager.dart';
import '../../core/custom_alerts.dart';

class AddTestsScreen extends StatefulWidget {
  final Map<String, dynamic>? testToEdit;
  const AddTestsScreen({super.key, this.testToEdit});

  @override
  State<AddTestsScreen> createState() => _AddTestsScreenState();
}

class _AddTestsScreenState extends State<AddTestsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  // Edit Mode state
  bool _isEditing = false;
  String? _editingTestId;

  // Form Controllers
  final _testNameController = TextEditingController();
  final _testTypeController = TextEditingController();
  final _priceController = TextEditingController();

  // Schedule management
  final List<String> _weekdays = [
    'All Day', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final Map<String, bool> _activeDays = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};

  @override
  void initState() {
    super.initState();
    _resetSchedule();
    if (widget.testToEdit != null) {
      _loadTestForEdit(widget.testToEdit!);
    }
  }

  void _resetSchedule() {
    for (var day in _weekdays) {
      _activeDays[day] = false;
      _startTimes[day] = const TimeOfDay(hour: 8, minute: 0);
      _endTimes[day] = const TimeOfDay(hour: 20, minute: 0);
    }
  }

  void _loadTestForEdit(Map<String, dynamic> test) {
    setState(() {
      _isEditing = true;
      _editingTestId = test['id'].toString();
      _testNameController.text = test['test_name']?.toString() ?? '';
      _testTypeController.text = test['test_type']?.toString() ?? '';
      _priceController.text = test['test_price']?.toString() ?? '';
      
      _resetSchedule();

      // Parse schedule
      final scheduleData = test['test_day_time'];
      if (scheduleData != null) {
        List<dynamic> schedules = [];
        if (scheduleData is List) {
          schedules = scheduleData;
        } else if (scheduleData is String) {
          try {
            schedules = jsonDecode(scheduleData);
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
    });
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testTypeController.dispose();
    _priceController.dispose();
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
        return TimeOfDay(
          hour: hour,
          minute: minute,
        );
      }
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
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

  void _submitForm() async {
    if (_testNameController.text.trim().isEmpty ||
        _testTypeController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      CustomAlerts.showError(context, 'Please fill in all required fields marked with *');
      return;
    }

    // Check if at least one day is selected
    final hasSchedule = _activeDays.values.any((active) => active);
    if (!hasSchedule) {
      CustomAlerts.showError(context, 'Please select at least one weekday for the test availability schedule.');
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

      final Map<String, String> body = {
        'test_name': _testNameController.text.trim(),
        'test_type': _testTypeController.text.trim(),
        'test_price': _priceController.text.trim(),
      };

      int idx = 0;
      for (var day in _weekdays) {
        if (_activeDays[day] == true) {
          body['test_day[$idx]'] = day;
          body['test_start_time[$idx]'] = _formatTime24h(_startTimes[day]!);
          body['test_end_time[$idx]'] = _formatTime24h(_endTimes[day]!);
          idx++;
        }
      }

      final response = _isEditing
          ? await ApiService.updateTest(token: token, id: _editingTestId!, body: body)
          : await ApiService.addTest(token: token, body: body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        CustomAlerts.showSuccessLoader(context, response['message'] ?? 'Pathology test saved successfully!');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context); // Pop success loader
          Navigator.pop(context, true); // Pop AddTestsScreen and return success
        }
      } else {
        String errorMessage = response['message'] ?? 'Failed to save test details.';
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
        CustomAlerts.showError(context, 'An unexpected error occurred. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _isEditing ? 'Edit Test Details' : 'Add New Test',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
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
                _isEditing ? 'Modify Test Parameters' : 'Register Pathology Test',
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
                'Configure price, diagnostic category, and operational timings.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
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
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
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
            _buildFormInput(
              controller: _testNameController,
              hint: 'Enter Test Name *',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 14),
            _buildFormInput(
              controller: _testTypeController,
              hint: 'Enter Test Type *',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 14),
            _buildFormInput(
              controller: _priceController,
              hint: 'Enter Test Price *',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            
            // Schedule section
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Text(
                  'TEST AVAILABILITY HOURS *',
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
              children: _weekdays.map((day) => _buildScheduleRow(day)).toList(),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isEditing ? 'Update Details' : 'Upload Details',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
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
    );
  }

  Widget _buildFormInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary.withValues(alpha: 0.7), size: 18),
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
                    color: isEnabled ? AppColors.navy : AppColors.textSecondary.withValues(alpha: 0.6),
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
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.teal),
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
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.teal),
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
}
