import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../core/api_service.dart';
import '../../../core/session_manager.dart';
import '../../../core/custom_alerts.dart';
import '../video_call/video_call_screen.dart';
import 'details.dart';
import '../../../widgets/partner_skeleton_loader.dart';

class UpcomingAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const UpcomingAppointmentsScreen({super.key, required this.partnerData});

  @override
  State<UpcomingAppointmentsScreen> createState() => _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState extends State<UpcomingAppointmentsScreen> {
  static const Color themeColor = Color(0xFFD97706);
  static const Color themeLight = Color(0xFFFFF9EE);
  static const Color themeBorder = Color(0xFFFCD34D);

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

      final response = await ApiService.getAppointments(token: token, status: 'Upcoming,Confirmed');
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _appointments = response['appointments'] ?? [];
          _filteredAppointments = _appointments;
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? 'Failed to load upcoming appointments.',
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
      final launched = await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch $launchUri';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the dialer app.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: themeColor,
            duration: Duration(seconds: 2),
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

  bool _isVideoCall(Map<String, dynamic> appt) {
    final clinicType = (appt['clinic_type'] ?? '').toString().toLowerCase().trim();
    // Video consultation is strictly disabled for OPD and Pathology
    if (clinicType == 'opd' || clinicType == 'pathology') {
      return false;
    }
    final visitMode = (appt['visit_mode'] ?? '').toString().toLowerCase().trim();
    if (visitMode == 'offline' || visitMode == 'physical' || visitMode == 'in_person') {
      return false;
    }
    final isVideo = appt['is_video'] == true || appt['is_video'] == 1 || appt['is_video'] == '1' || appt['is_video'] == 'true';
    return (clinicType == 'doctor' || clinicType == 'others') && (visitMode == 'online' || visitMode == 'video' || visitMode == 'video call' || isVideo);
  }

  bool _isWindowOpen(Map<String, dynamic> appt) {
    final bookingDate = appt['booking_date']?.toString();
    final bookingTime = appt['booking_time']?.toString();
    if (bookingDate == null || bookingTime == null || bookingDate.isEmpty || bookingTime.isEmpty) return true;
    try {
      final date = DateTime.parse(bookingDate);
      final rawTime = bookingTime.trim();
      final timeParts = rawTime.split(' ');
      final hms = timeParts[0].split(':');
      int hour = int.parse(hms[0]);
      int minute = hms.length > 1 ? int.parse(hms[1]) : 0;
      if (timeParts.length > 1) {
        final period = timeParts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      final scheduled = DateTime(date.year, date.month, date.day, hour, minute);
      final now = DateTime.now();
      final windowStart = scheduled.subtract(const Duration(minutes: 10));
      final windowEnd = scheduled.add(const Duration(minutes: 60));
      return now.isAfter(windowStart) && now.isBefore(windowEnd);
    } catch (_) {
      return true;
    }
  }

  String _getWindowStartFormatted(Map<String, dynamic> appt) {
    final bookingDate = appt['booking_date']?.toString();
    final bookingTime = appt['booking_time']?.toString();
    if (bookingDate == null || bookingTime == null) return "Starts soon";
    try {
      final date = DateTime.parse(bookingDate);
      final rawTime = bookingTime.trim();
      final timeParts = rawTime.split(' ');
      final hms = timeParts[0].split(':');
      int hour = int.parse(hms[0]);
      int minute = hms.length > 1 ? int.parse(hms[1]) : 0;
      if (timeParts.length > 1) {
        final period = timeParts[1].toUpperCase();
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }
      final start = DateTime(date.year, date.month, date.day, hour, minute).subtract(const Duration(minutes: 10));
      final h = start.hour > 12 ? start.hour - 12 : (start.hour == 0 ? 12 : start.hour);
      final m = start.minute.toString().padLeft(2, '0');
      final p = start.hour >= 12 ? 'PM' : 'AM';
      return "Opens at $h:$m $p";
    } catch (_) {
      return "Opens 10m before";
    }
  }

  Future<void> _startVideoCall(Map<String, dynamic> appt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      ),
    );

    try {
      final token = await SessionManager.getToken();
      if (!mounted) return;
      if (token == null) {
        Navigator.pop(context);
        CustomAlerts.showError(context, 'Authentication session expired.');
        return;
      }

      final id = int.tryParse(appt['id'].toString()) ?? 0;
      final response = await ApiService.getVideoCallToken(appointmentId: id, token: token);
      if (!mounted) return;
      Navigator.pop(context);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final appId = data['app_id']?.toString() ?? '';
        final channel = data['channel']?.toString() ?? '';
        final agoraToken = data['token']?.toString() ?? '';
        final uid = int.tryParse(data['uid'].toString()) ?? 0;
        final patientName = data['patient_name']?.toString() ?? appt['user_name'] ?? 'Patient';

        if (appId.isEmpty || channel.isEmpty || agoraToken.isEmpty) {
          CustomAlerts.showError(context, 'Invalid video call token received from server.');
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              appId: appId,
              channelName: channel,
              token: agoraToken,
              uid: uid,
              appointmentId: id,
              participantName: patientName,
              role: 'doctor',
            ),
          ),
        );
        if (mounted) {
          _fetchAppointments();
        }
      } else {
        CustomAlerts.showError(context, response['message'] ?? 'Unable to connect to video session.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomAlerts.showError(context, 'Failed to connect to video session.');
      }
    }
  }

  void _navigateToDetails(Map<String, dynamic> appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          appointment: appt,
          partnerData: widget.partnerData,
          onStatusUpdated: _fetchAppointments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: Column(
        children: [
          // Header Stats & Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
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
                          'Upcoming Bookings',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Upcoming: ${_appointments.length}',
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
                ? const PartnerAppointmentsSkeleton()
                : RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    color: themeColor,
                    child: _filteredAppointments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                              bottom: (MediaQuery.paddingOf(context).bottom + 125).clamp(140.0, 165.0),
                            ),
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
                Icons.calendar_month_rounded,
                color: AppColors.navy,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty ? 'No Upcoming Bookings' : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'There are no active upcoming inquiries or appointments booked at this time.'
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

    final isVideo = _isVideoCall(appt);
    final isWindow = _isWindowOpen(appt);

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SL: ${appt['enquiry_serial'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isVideo ? AppColors.teal.withValues(alpha: 0.12) : AppColors.navy.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isVideo) ...[
                                const Icon(Icons.videocam_rounded, size: 10, color: AppColors.teal),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                visitMode.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: isVideo ? AppColors.teal : AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                // Video Call Button on Card if Video Appointment
                if (isVideo) ...[
                  const SizedBox(height: 12),
                  isWindow
                      ? InkWell(
                          onTap: () => _startVideoCall(appt),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Start Video Consultation',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined, color: Colors.blueGrey[400], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Video Call: ${_getWindowStartFormatted(appt)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueGrey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
