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
import '../video_call/video_call_screen.dart';
import '../../../widgets/partner_skeleton_loader.dart';

class TodayAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;
  final bool isTab;

  const TodayAppointmentsScreen({
    super.key,
    required this.partnerData,
    this.isTab = false,
  });

  @override
  State<TodayAppointmentsScreen> createState() => _TodayAppointmentsScreenState();
}

class _TodayAppointmentsScreenState extends State<TodayAppointmentsScreen> {
  static const Color themeColor = AppColors.teal;
  static const Color themeLight = Color(0xFFF0FAF7);
  static const Color themeBorder = Color(0xFFBFECE1);

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

  bool _isToday(String dateStr) {
    if (dateStr == 'N/A' || dateStr.trim().isEmpty) return false;
    
    final now = DateTime.now();
    
    // Format 1: YYYY-MM-DD
    final yyyymmdd = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // Format 2: DD-MM-YYYY
    final ddmmyyyy = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    // Format 3: D-M-YYYY
    final dmyyyy = '${now.day}-${now.month}-${now.year}';
    // Format 4: DD/MM/YYYY
    final ddmmyyyySlash = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    // Format 5: D/M/YYYY
    final dmyyyySlash = '${now.day}/${now.month}/${now.year}';
    // Format 6: YYYY/MM/DD
    final yyyymmddSlash = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    final cleanDate = dateStr.trim();
    if (cleanDate == yyyymmdd || 
        cleanDate == ddmmyyyy || 
        cleanDate == dmyyyy || 
        cleanDate == ddmmyyyySlash || 
        cleanDate == dmyyyySlash || 
        cleanDate == yyyymmddSlash) {
      return true;
    }

    try {
      final parsed = DateTime.tryParse(cleanDate);
      if (parsed != null) {
        return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
      }
    } catch (_) {}

    if (cleanDate.contains(yyyymmdd) || cleanDate.contains(ddmmyyyy)) {
      return true;
    }

    return false;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      final todayAppts = _appointments.where((appt) {
        final dateStr = (appt['booking_date'] ?? '').toString();
        return _isToday(dateStr);
      }).toList();

      if (query.isEmpty) {
        _filteredAppointments = todayAppts;
      } else {
        _filteredAppointments = todayAppts.where((appt) {
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

      final response = await ApiService.getAppointments(token: token, status: 'Upcoming,Confirmed,Pending');
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _appointments = response['appointments'] ?? [];
          // Filter to today's appointments initially
          _filteredAppointments = _appointments.where((appt) {
            final dateStr = (appt['booking_date'] ?? '').toString();
            return _isToday(dateStr);
          }).toList();
        });
      } else {
        CustomAlerts.showError(
          context,
          response['message'] ?? "Failed to load today's appointments.",
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
    final bookingTime = appt['booking_time']?.toString();
    if (bookingTime == null || bookingTime.isEmpty) return 'Opens 10m before';
    try {
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
      final now = DateTime.now();
      final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      final start = scheduled.subtract(const Duration(minutes: 10));
      final h = start.hour > 12 ? start.hour - 12 : (start.hour == 0 ? 12 : start.hour);
      final m = start.minute.toString().padLeft(2, '0');
      final p = start.hour >= 12 ? 'PM' : 'AM';
      return 'Opens at $h:$m $p';
    } catch (_) {
      return 'Opens 10m before';
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

  Future<void> _updateAppointmentStatus(Map<String, dynamic> appt, String newStatus) async {
    final patientName = appt['user_name'] ?? appt['user']?['user_name'] ?? 'Patient';
    final actionWord = newStatus == 'Confirmed' 
        ? 'confirm' 
        : newStatus == 'Completed' 
            ? 'mark as completed' 
            : 'cancel';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$newStatus Appointment',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        content: Text(
          'Are you sure you want to $actionWord the appointment for $patientName?',
          style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Keep',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'Cancelled' ? Colors.redAccent : AppColors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              newStatus == 'Cancelled' ? 'Yes, Cancel' : 'Yes, $newStatus',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) CustomAlerts.showError(context, 'Authentication token missing.');
        return;
      }
      final id = appt['id']?.toString() ?? '';
      final response = await ApiService.updateAppointmentStatus(
        token: token,
        id: id,
        status: newStatus,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        CustomAlerts.showSuccess(context, response['message'] ?? 'Status updated successfully.');
        _fetchAppointments();
      } else {
        CustomAlerts.showError(context, response['message'] ?? 'Failed to update status.');
      }
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
    // Total count calculation based on today's filter
    final todayCount = _appointments.where((appt) {
      final dateStr = (appt['booking_date'] ?? '').toString();
      return _isToday(dateStr);
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Today's Appointments",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              shape: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
            ),
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
                          "Today's Bookings",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Pending: $todayCount',
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
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 135),
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
              query.isEmpty ? "No Appointments for Today" : 'No Results Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'There are no active upcoming inquiries or appointments booked for today.'
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
    final resService = appt['resolved_service_name']?.toString().trim();
    final resDoc = appt['resolved_doctor_name']?.toString().trim();
    final serviceName = (resService != null && resService.isNotEmpty && resService != 'N/A')
        ? resService
        : (resDoc != null && resDoc.isNotEmpty && resDoc != 'N/A')
            ? resDoc
            : isPathology
                ? (appt['test']?['test_name'] ?? appt['test_name'] ?? appt['clinic_name'] ?? 'Diagnostic Test')
                : (appt['doctor_contact']?['partner_doctor_name'] ??
                    appt['clinic_name'] ??
                    appt['doctor']?['doctor_name'] ??
                    appt['doctor_name'] ??
                    'Specialist Consultation');

    final rawStatus = (appt['status'] ?? 'Upcoming').toString().trim();
    final normStatus = rawStatus.toLowerCase();
    final statusText = rawStatus.isEmpty ? 'Upcoming' : rawStatus;

    final Color statusBg;
    final Color statusFg;
    if (normStatus == 'confirmed') {
      statusBg = const Color(0xFFE0F2FE);
      statusFg = const Color(0xFF0369A1);
    } else if (normStatus == 'completed') {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
    } else if (normStatus == 'cancelled') {
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFB91C1C);
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFB45309);
    }

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
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: statusFg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  patientName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),

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
                if (_isVideoCall(appt)) ...[
                  const SizedBox(height: 12),
                  _isWindowOpen(appt)
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

                // Quick Action Buttons on Card
                if (normStatus == 'upcoming' || normStatus == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus(appt, 'Confirmed'),
                            icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'Confirm',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateAppointmentStatus(appt, 'Cancelled'),
                            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                            label: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (normStatus == 'confirmed') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus(appt, 'Completed'),
                            icon: const Icon(Icons.task_alt_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'Mark Complete',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () => _updateAppointmentStatus(appt, 'Cancelled'),
                            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                            label: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
