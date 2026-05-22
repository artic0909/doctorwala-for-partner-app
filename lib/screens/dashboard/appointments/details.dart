import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../core/api_service.dart';
import '../../../core/session_manager.dart';
import '../../../core/custom_alerts.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> partnerData;
  final VoidCallback? onStatusUpdated;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
    required this.partnerData,
    this.onStatusUpdated,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool _isLoading = false;
  late Map<String, dynamic> _appointment;

  bool _isDoctorPartner() {
    final rawRegType = widget.partnerData['registration_type'];
    if (rawRegType == null) return false;
    if (rawRegType is List) {
      return rawRegType.map((e) => e.toString().toLowerCase().trim()).contains('doctor');
    }
    final str = rawRegType.toString().toLowerCase().trim();
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => e.toString().toLowerCase().trim()).contains('doctor');
        }
      } catch (_) {}
      return str.contains('doctor');
    }
    return str == 'doctor';
  }

  @override
  void initState() {
    super.initState();
    _appointment = Map<String, dynamic>.from(widget.appointment);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+'), ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (_) {
      if (mounted) {
        final status = _appointment['status'] ?? 'Upcoming';
        final Color themeColor;
        if (status == 'Completed') {
          themeColor = AppColors.teal;
        } else if (status == 'Cancelled') {
          themeColor = const Color(0xFFEF4444);
        } else {
          themeColor = const Color(0xFFD97706);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open the dialer app.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: themeColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatTime12h(String time24h) {
    if (time24h == 'N/A' || time24h.isEmpty) return 'N/A';
    try {
      final parts = time24h.split(':');
      if (parts.length < 2) return time24h;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (_) {
      return time24h;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          newStatus == 'Completed' ? 'Complete Appointment' : 'Cancel Appointment',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        content: Text(
          newStatus == 'Completed'
              ? 'Are you sure you want to mark this appointment as Completed? This action cannot be undone.'
              : 'Are you sure you want to cancel this appointment? The patient will be notified.',
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
              backgroundColor: newStatus == 'Completed' ? AppColors.teal : Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              newStatus == 'Completed' ? 'Complete' : 'Yes, Cancel',
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
        if (token == null) {
          if (mounted) {
            CustomAlerts.showError(context, 'Authentication token missing.');
          }
          return;
        }

        final id = _appointment['id']?.toString() ?? '';
        final response = await ApiService.updateAppointmentStatus(
          token: token,
          id: id,
          status: newStatus,
        );

        if (!mounted) return;

        if (response['success'] == true) {
          CustomAlerts.showSuccess(
            context,
            response['message'] ?? 'Appointment status updated successfully.',
          );
          setState(() {
            _appointment['status'] = newStatus;
          });
          if (widget.onStatusUpdated != null) {
            widget.onStatusUpdated!();
          }
        } else {
          CustomAlerts.showError(
            context,
            response['message'] ?? 'Failed to update status.',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomAlerts.showError(context, 'An unexpected error occurred.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _appointment['status'] ?? 'Upcoming';
    final date = _appointment['booking_date'] ?? 'N/A';
    final time = _appointment['booking_time'] ?? 'N/A';
    final visitMode = _appointment['visit_mode'] ?? 'N/A';
    final clinicType = _appointment['clinic_type'] ?? 'N/A';
    final inquiry = _appointment['user_inquiry'] ?? '';

    // Patient Details
    final patientName = _appointment['user_name'] ?? _appointment['user']?['user_name'] ?? 'N/A';
    final patientMobile = _appointment['user_mobile'] ?? _appointment['user']?['user_mobile'] ?? 'N/A';
    final patientEmail = _appointment['user_email'] ?? _appointment['user']?['user_email'] ?? 'N/A';

    // Doctor Details
    final doctor = _appointment['doctor'];
    final doctorName = doctor?['doctor_name'] ?? 'N/A';
    final doctorSpeciality = doctor?['doctor_specialist'] ?? 'N/A';
    final doctorDesignation = doctor?['doctor_designation'] ?? 'N/A';

    // Test Details
    final test = _appointment['test'];
    final testName = test?['test_name'] ?? 'N/A';
    final testType = test?['test_type'] ?? 'N/A';
    final testPrice = test?['test_price']?.toString() ?? 'N/A';

    // Status Styling
    final Color themeColor;
    final Color themeLight;
    final Color themeBorder;
    final IconData statusIcon;
    if (status == 'Completed') {
      themeColor = AppColors.teal;
      themeLight = const Color(0xFFF0FAF7);
      themeBorder = const Color(0xFFBFECE1);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Cancelled') {
      themeColor = const Color(0xFFEF4444);
      themeLight = const Color(0xFFFFF1F2);
      themeBorder = const Color(0xFFFECDD3);
      statusIcon = Icons.cancel_rounded;
    } else {
      themeColor = const Color(0xFFD97706);
      themeLight = const Color(0xFFFFF9EE);
      themeBorder = const Color(0xFFFCD34D);
      statusIcon = Icons.pending_actions_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Serial No: ${_appointment['enquiry_serial'] ?? 'N/A'}',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Time Header Card
                  FadeInDown(
                    duration: const Duration(milliseconds: 350),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: themeLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeBorder.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: themeColor, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: themeColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  clinicType.toUpperCase(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(height: 1, thickness: 1, color: themeBorder.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHeaderTimeItem(
                                  Icons.calendar_month_rounded,
                                  'Booking Date',
                                  date,
                                  themeColor,
                                ),
                              ),
                              Container(width: 1, height: 35, color: themeBorder.withValues(alpha: 0.3)),
                              Expanded(
                                child: _buildHeaderTimeItem(
                                  Icons.access_time_rounded,
                                  'Booking Time',
                                  _formatTime12h(time),
                                  themeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 350),
                    child: _buildSectionCard(
                      title: 'Patient Information',
                      icon: Icons.person_rounded,
                      themeColor: themeColor,
                      themeLight: themeLight,
                      themeBorder: themeBorder,
                      children: [
                        _buildInfoRow('Name', patientName, themeColor),
                        _buildInfoRow('Mobile Number', patientMobile, themeColor),
                        _buildInfoRow('Email Address', patientEmail, themeColor),
                        if (inquiry.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Symptom / Inquiry Notes:',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: themeLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: themeBorder.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              inquiry,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service Section (Doctor, Test, or Visit Details for Doctor partner)
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: clinicType.toLowerCase() == 'pathology'
                        ? _buildSectionCard(
                            title: 'Test Details',
                            icon: Icons.science_rounded,
                            themeColor: themeColor,
                            themeLight: themeLight,
                            themeBorder: themeBorder,
                            children: [
                              _buildInfoRow('Test Name', testName, themeColor),
                              _buildInfoRow('Test Type', testType, themeColor),
                              _buildInfoRow('Test Cost', '₹$testPrice', themeColor),
                              _buildInfoRow('Visit Mode', visitMode, themeColor),
                            ],
                          )
                        : _isDoctorPartner()
                            ? _buildSectionCard(
                                title: 'Visit Details',
                                icon: Icons.meeting_room_rounded,
                                themeColor: themeColor,
                                themeLight: themeLight,
                                themeBorder: themeBorder,
                                children: [
                                  _buildInfoRow('Visit Mode', visitMode, themeColor),
                                ],
                              )
                            : _buildSectionCard(
                                title: 'Doctor Details',
                                icon: Icons.medical_information_rounded,
                                themeColor: themeColor,
                                themeLight: themeLight,
                                themeBorder: themeBorder,
                                children: [
                                  _buildInfoRow('Doctor Name', doctorName, themeColor),
                                  _buildInfoRow('Specialty', doctorSpeciality, themeColor),
                                  _buildInfoRow('Designation', doctorDesignation, themeColor),
                                  _buildInfoRow('Visit Mode', visitMode, themeColor),
                                ],
                              ),
                  ),
                  const SizedBox(height: 40),

                  // Actions Section (Only for Upcoming status)
                  if (status == 'Upcoming')
                    FadeInUp(
                      duration: const Duration(milliseconds: 450),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus('Completed'),
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                              label: Text(
                                'Mark as Completed',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                elevation: 2,
                                shadowColor: AppColors.teal.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _updateStatus('Cancelled'),
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                              label: Text(
                                'Cancel Appointment',
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.redAccent,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FadeInUp(
                      duration: const Duration(milliseconds: 450),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColor.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          status == 'Completed'
                              ? 'This appointment has been completed successfully.'
                              : 'This appointment was cancelled.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderTimeItem(IconData icon, String label, String value, Color themeColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: themeColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required Color themeColor,
    required Color themeLight,
    required Color themeBorder,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeBorder.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: themeColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: themeBorder.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color themeColor) {
    final isMobile = label == 'Mobile Number' && value != 'N/A' && value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (isMobile) ...[
                  IconButton(
                    onPressed: () => _makePhoneCall(value),
                    icon: Icon(Icons.phone_in_talk_rounded, color: themeColor, size: 14),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(5),
                    tooltip: 'Call Patient',
                    style: IconButton.styleFrom(
                      backgroundColor: themeColor.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
