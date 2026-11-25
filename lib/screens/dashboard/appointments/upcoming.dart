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
import '../../../widgets/partner_appointment_card.dart';

class UpcomingAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> partnerData;

  const UpcomingAppointmentsScreen({super.key, required this.partnerData});

  @override
  State<UpcomingAppointmentsScreen> createState() => _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState extends State<UpcomingAppointmentsScreen> {
  static const Color themeColor = Color(0xFFD97706);

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

      final response = await ApiService.getAppointments(token: token, status: 'Upcoming,Confirmed,Pending');
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
    final patientMobile = (appt['user_mobile'] ?? appt['user']?['user_mobile'] ?? 'N/A').toString();
    final isVideo = _isVideoCall(appt);
    final isWindow = _isWindowOpen(appt);
    final windowStart = isVideo && !isWindow ? _getWindowStartFormatted(appt) : '';
    final hasPhone = patientMobile != 'N/A' && patientMobile.isNotEmpty;

    return PartnerAppointmentCard(
      appt: appt,
      isDoctorPartner: _isDoctorPartner(),
      isVideo: isVideo,
      isWindowOpen: isWindow,
      windowStartText: windowStart,
      onCall: hasPhone ? () => _makePhoneCall(patientMobile) : null,
      onStartVideoCall: isVideo ? () => _startVideoCall(appt) : null,
      onUpdateStatus: (newStatus) => _updateAppointmentStatus(appt, newStatus),
      onTap: () => PartnerAppointmentCard.showDetailsModal(
        context: context,
        appt: appt,
        isDoctorPartner: _isDoctorPartner(),
        isVideo: isVideo,
        isWindowOpen: isWindow,
        windowStartText: windowStart,
        onCall: hasPhone ? () => _makePhoneCall(patientMobile) : null,
        onStartVideoCall: isVideo ? () => _startVideoCall(appt) : null,
        onUpdateStatus: (newStatus) => _updateAppointmentStatus(appt, newStatus),
        onOpenFullDetails: () => _navigateToDetails(appt),
      ),
    );
  }
}
