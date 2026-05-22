import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../core/api_service.dart';
import '../../../core/session_manager.dart';
import '../../../core/custom_alerts.dart';
import 'details.dart';

class CancelledAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const CancelledAppointmentsScreen({super.key, required this.partnerData});

  @override
  State<CancelledAppointmentsScreen> createState() => _CancelledAppointmentsScreenState();
}

class _CancelledAppointmentsScreenState extends State<CancelledAppointmentsScreen> {
  static const Color themeColor = Color(0xFFEF4444);
  static const Color themeLight = Color(0xFFFFF1F2);
  static const Color themeBorder = Color(0xFFFECDD3);

  bool _isFetching = true;
  List<dynamic> _appointments = [];
  List<dynamic> _filteredAppointments = [];
  final TextEditingController _searchController = TextEditingController();

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
    _fetchAppointments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredAppointments = _appointments;
      } else {
        _filteredAppointments = _appointments.where((appt) {
          final patientName = (appt['user_name'] ?? appt['user']?['user_name'] ?? '').toString().toLowerCase();
          final patientMobile = (appt['user_mobile'] ?? appt['user']?['user_mobile'] ?? '').toString().toLowerCase();
          final doctorName = (appt['doctor']?['doctor_name'] ?? '').toString().toLowerCase();
          final testName = (appt['test']?['test_name'] ?? '').toString().toLowerCase();
          final clinicType = (appt['clinic_type'] ?? '').toString().toLowerCase();
          final visitMode = (appt['visit_mode'] ?? '').toString().toLowerCase();

          return patientName.contains(query) ||
              patientMobile.contains(query) ||
              doctorName.contains(query) ||
              testName.contains(query) ||
              clinicType.contains(query) ||
              visitMode.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    setState(() => _isFetching = true);
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _isFetching = false);
        return;
      }

      final response = await ApiService.getAppointments(token: token, status: 'Cancelled');
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _appointments = response['appointments'] ?? [];
          _filteredAppointments = _appointments;
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load cancelled appointments.',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomAlerts.showError(
          context,
          'An unexpected error occurred while fetching appointments.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
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

  void _navigateToDetails(Map<String, dynamic> appt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          appointment: appt,
          partnerData: widget.partnerData,
          onStatusUpdated: _fetchAppointments,
        ),
      ),
    );
    _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancelled Appointments',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Cancelled: ${_appointments.length}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: themeColor),
                      onPressed: _fetchAppointments,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: themeColor,
                        size: 20,
                      ),
                      hintText: 'Search patient, phone, doctor or test...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: _isFetching
                ? const Center(
                     child: CircularProgressIndicator(
                       valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                     ),
                   )
                : RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    color: themeColor,
                    child: _filteredAppointments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAppointments.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final appt = _filteredAppointments[index] as Map<String, dynamic>;
                              return FadeInUp(
                                duration: const Duration(milliseconds: 300),
                                child: _buildAppointmentCard(appt),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text.trim();
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No Cancelled Appointments' : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'There are no cancelled appointments in your record.'
                  : 'We couldn\'t find any matches for "$query". Try searching something else.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final patientName = appt['user_name'] ?? appt['user']?['user_name'] ?? 'N/A';
    final patientMobile = appt['user_mobile'] ?? appt['user']?['user_mobile'] ?? 'N/A';
    final date = appt['booking_date'] ?? 'N/A';
    final time = appt['booking_time'] ?? 'N/A';
    final visitMode = appt['visit_mode'] ?? 'N/A';
    final clinicType = appt['clinic_type'] ?? 'N/A';

    final isPathology = clinicType.toLowerCase() == 'pathology';
    final serviceName = isPathology
        ? (appt['test']?['test_name'] ?? 'N/A')
        : (appt['doctor']?['doctor_name'] ?? 'N/A');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: themeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeBorder.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToDetails(appt),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with status tags & clinical type tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPathology ? Colors.purpleAccent : themeColor).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPathology ? Icons.science_rounded : Icons.medical_information_rounded,
                            size: 12,
                            color: isPathology ? Colors.purple : themeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clinicType.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isPathology ? Colors.purple : themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        visitMode.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Patient details
                Text(
                  patientName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),

                // Service Name
                if (!(_isDoctorPartner() && !isPathology)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPathology ? 'Test: ' : 'Doctor: ',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          serviceName,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Date, Time, Contact
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                date,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime12h(time),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Call number
                    if (patientMobile != 'N/A' && patientMobile.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _makePhoneCall(patientMobile),
                        icon: const Icon(Icons.phone_in_talk_rounded, color: themeColor, size: 18),
                        tooltip: 'Call Patient',
                        style: IconButton.styleFrom(
                          backgroundColor: themeColor.withValues(alpha: 0.08),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: themeColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
